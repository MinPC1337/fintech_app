import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dialog_utils.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/usecases/transfer_out_usecase.dart';
import '../../domain/usecases/watch_out_categories_usecase.dart';
import '../../../../core/services/local_notification_service.dart';
import '../widgets/category_dropdown.dart';
import 'qr_scanner_page.dart';
import 'transaction_success_page.dart';

class TransferPage extends StatefulWidget {
  /// Số điện thoại điền sẵn (từ QR scanner)
  final String? initialPhone;

  const TransferPage({super.key, this.initialPhone});

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late final TextEditingController _phoneController;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedCategoryName;

  bool _isTransferring = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
  }

  /// Mở QrScannerPage, parse SĐT 10 số từ kết quả QR MoMo UAT.
  /// Hỗ trợ các định dạng:
  ///   - EMV QR: "2|99|0987654321|..."
  ///   - Deeplink: "momo://...phone=0987654321..."
  ///   - Chuỗi thẳng 10 số
  Future<void> _scanMomoQr() async {
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (_) => const QrScannerPage(
          title: 'Quét QR MoMo',
          hint: 'Quét mã QR ví MoMo để tự động điền số điện thoại',
        ),
      ),
    );

    // ── DEBUG: kết quả trả về từ QR scanner ──────────────────────────
    debugPrint('[TransferPage._scanMomoQr] raw result: "$result"');
    // ──────────────────────────────────────────────────

    if (result == null || result.isEmpty) return;

    // Parse số điện thoại 10 số (bắt đầu bằng 0)
    final phoneRegex = RegExp(r'(?<![\d])(0\d{9})(?![\d])');
    final match = phoneRegex.firstMatch(result);
    if (match != null) {
      debugPrint(
        '[TransferPage._scanMomoQr] ✔ Phone extracted via regex: "${match.group(1)}"',
      );
      _phoneController.text = match.group(1)!;
      return;
    }

    // Nếu toàn bộ chuỗi chỉ là SĐT
    if (RegExp(r'^0\d{9}$').hasMatch(result.trim())) {
      debugPrint(
        '[TransferPage._scanMomoQr] ✔ Phone is raw string: "${result.trim()}"',
      );
      _phoneController.text = result.trim();
      return;
    }

    debugPrint('[TransferPage._scanMomoQr] ✖ No phone found in QR content');
    if (mounted) {
      showNotificationDialog(
        context,
        'Không tìm thấy SĐT',
        'Mã QR không chứa số điện thoại MoMo hợp lệ.\nNội dung: $result',
        kRose,
        Icons.qr_code_2_rounded,
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _handleTransfer() async {
    if (currentUser == null) return;

    final phone = _phoneController.text.trim();
    final amountText = _amountController.text.trim();

    if (phone.isEmpty || phone.length < 10) {
      showNotificationDialog(
        context,
        'Lỗi',
        'Vui lòng nhập số điện thoại hợp lệ',
        kRose,
        Icons.error,
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      showNotificationDialog(
        context,
        'Lỗi',
        'Số tiền không hợp lệ',
        kRose,
        Icons.error,
      );
      return;
    }

    if (_selectedCategoryId == null) {
      showNotificationDialog(
        context,
        'Lỗi',
        'Vui lòng chọn danh mục chi tiêu',
        kRose,
        Icons.category,
      );
      return;
    }

    setState(() {
      _isTransferring = true;
    });

    final transferUseCase = sl<TransferOutUseCase>();
    final result = await transferUseCase.call(
      currentUser!.uid,
      amount,
      phone,
      _selectedCategoryId!,
    );

    setState(() {
      _isTransferring = false;
    });

    result.fold(
      (failure) {
        showNotificationDialog(
          context,
          'Thất bại',
          failure.message,
          kRose,
          Icons.error_outline,
        );
      },
      (_) {
        sl<LocalNotificationService>().showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: 'Rút tiền thành công',
          body:
              'Giao dịch rút ${amount.toStringAsFixed(0)} VNĐ về số $phone đã hoàn tất.',
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) {
              final name = currentUser?.displayName?.isNotEmpty == true
                  ? currentUser!.displayName!
                  : 'Người dùng';
              return TransactionSuccessPage(
                amount: amount,
                sender: 'Ví cá nhân - $name',
                receiver: 'Ví MoMo - $phone',
                categoryName: _selectedCategoryName ?? 'Chưa phân loại',
                timestamp: DateTime.now(),
                note: _noteController.text.trim(),
                isInternal: false,
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Cần đăng nhập trước")));
    }

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        title: const Text(
          'Chuyển khoản (Rút tiền)',
          style: TextStyle(color: kTextPrimary),
        ),
        iconTheme: const IconThemeData(color: kTextPrimary),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kElectricBlue, kOceanBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Rút tiền về MoMo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tiền sẽ được chuyển ngay lập tức',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Số điện thoại nhận (MoMo)',
                style: TextStyle(color: kTextSecondary, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: kTextPrimary, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Nhập SĐT (vd: 0987654321)',
                  hintStyle: const TextStyle(color: kTextSecondary),
                  prefixIcon: const Icon(
                    Icons.phone_android,
                    color: kElectricBlue,
                  ),
                  suffixIcon: IconButton(
                    tooltip: 'Quét mã QR MoMo',
                    icon: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: kElectricBlue,
                    ),
                    onPressed: _scanMomoQr,
                  ),
                  filled: true,
                  fillColor: kSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Số tiền chuyển',
                style: TextStyle(color: kTextSecondary, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: const TextStyle(color: kTextSecondary),
                  suffixText: 'VNĐ',
                  suffixStyle: const TextStyle(color: kTextPrimary),
                  prefixIcon: const Icon(
                    Icons.attach_money,
                    color: kElectricBlue,
                  ),
                  filled: true,
                  fillColor: kSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Ghi chú (tuỳ chọn)',
                style: TextStyle(color: kTextSecondary, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                style: const TextStyle(color: kTextPrimary, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Ví dụ: Trả tiền cà phê',
                  hintStyle: const TextStyle(color: kTextSecondary),
                  prefixIcon: const Icon(
                    Icons.edit_note_rounded,
                    color: kElectricBlue,
                  ),
                  filled: true,
                  fillColor: kSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Danh mục',
                style: TextStyle(color: kTextSecondary, fontSize: 14),
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<CategoryEntity>>(
                stream: sl<WatchOutCategoriesUseCase>().call(currentUser!.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: kElectricBlue),
                    );
                  }
                  final categories = snapshot.data ?? [];
                  if (categories.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Bạn chưa có danh mục chi tiêu nào. Vui lòng tạo danh mục ở trang Ngân sách trước khi chuyển tiền.',
                        style: TextStyle(color: kRose, fontSize: 14),
                      ),
                    );
                  }

                  // Ensure _selectedCategoryId is valid
                  if (_selectedCategoryId != null &&
                      !categories.any((c) => c.id == _selectedCategoryId)) {
                    _selectedCategoryId = null;
                  }

                  return CategoryDropdown(
                    categories: categories,
                    selectedCategoryId: _selectedCategoryId,
                    onChanged: (val) {
                      setState(() {
                        _selectedCategoryId = val;
                        if (val != null) {
                          _selectedCategoryName = categories
                              .firstWhere((c) => c.id == val)
                              .name;
                        } else {
                          _selectedCategoryName = null;
                        }
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _isTransferring ? null : _handleTransfer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kElectricBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isTransferring
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Chuyển khoản ngay',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kBorder),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: kNeonCyan, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tính năng giả lập Rút tiền/Chi hộ. Tiền sẽ được trừ vào ví Firebase hiện tại.',
                        style: TextStyle(color: kTextSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
