import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dialog_utils.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/usecases/transfer_out_usecase.dart';
import '../../domain/usecases/watch_out_categories_usecase.dart';
import '../../../../features/group_wallet/domain/usecases/watch_group_wallets_usecase.dart';
import '../../domain/usecases/get_primary_wallet_stream_usecase.dart';
import '../../domain/entities/wallet_entity.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/local_notification_service.dart';
import '../../../../core/config/push_config.dart';
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

  String? _selectedWalletId;
  String _selectedWalletName = 'Ví cá nhân';

  bool _isTransferring = false;

  late final Stream<dynamic> _primaryWalletStream;
  late final Stream<List<WalletEntity>> _groupWalletsStream;
  late final Stream<List<CategoryEntity>> _outCategoriesStream;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');

    if (currentUser != null) {
      _primaryWalletStream = sl<GetPrimaryWalletStreamUseCase>().call(
        currentUser!.uid,
      );
      _groupWalletsStream = sl<WatchGroupWalletsUseCase>().call(
        currentUser!.uid,
      );
      _outCategoriesStream = sl<WatchOutCategoriesUseCase>().call(
        currentUser!.uid,
      );
    } else {
      _primaryWalletStream = const Stream.empty();
      _groupWalletsStream = Stream.value([]);
      _outCategoriesStream = Stream.value([]);
    }
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
      fromWalletId: _selectedWalletId,
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
      (_) async {
        String senderName = 'Người dùng';
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser!.uid)
              .get();
          if (doc.exists) {
            final data = doc.data();
            final name = data?['fullName'] ?? 'Người dùng';
            final acc = data?['accountNumber'] ?? 'N/A';
            senderName = '$name ($acc)';
          }
        } catch (_) {}

        if (!PushConfig.isConfigured) {
          sl<LocalNotificationService>().showNotification(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: 'Rút tiền thành công',
            body:
                'Giao dịch rút ${amount.toStringAsFixed(0)} VNĐ về số $phone đã hoàn tất.',
          );
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) {
              return TransactionSuccessPage(
                amount: amount,
                sender: '$_selectedWalletName - $senderName',
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
          'Rút tiền ra MoMo',
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
                child: Column(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Image.asset(
                        'assets/icon_quickrow/spending.png',
                        width: 35,
                        height: 35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Rút tiền về MoMo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tiền sẽ được chuyển ngay lập tức',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Nguồn tiền',
                style: TextStyle(color: kTextSecondary, fontSize: 14),
              ),
              const SizedBox(height: 8),
              StreamBuilder(
                stream: _primaryWalletStream,
                builder: (context, primarySnapshot) {
                  WalletEntity? primaryWallet;
                  if (primarySnapshot.hasData) {
                    (primarySnapshot.data as dynamic).fold((failure) => null, (
                      wallet,
                    ) {
                      primaryWallet = wallet;
                    });
                  }
                  return StreamBuilder<List<WalletEntity>>(
                    stream: _groupWalletsStream,
                    builder: (context, groupSnapshot) {
                      final groupWallets = (groupSnapshot.data ?? [])
                          .where(
                            (w) =>
                                w.ownerId == currentUser!.uid &&
                                w.status != 'closed',
                          )
                          .toList();

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildWalletChip(
                              id: null,
                              name: 'Ví cá nhân',
                              balance: primaryWallet?.balance,
                              icon: Icons.account_balance_wallet,
                              isSelected: _selectedWalletId == null,
                            ),
                            ...groupWallets.map(
                              (w) => _buildWalletChip(
                                id: w.id,
                                name: w.name,
                                balance: w.balance,
                                icon: Icons.group,
                                isSelected: _selectedWalletId == w.id,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),

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
              const SizedBox(height: 12),
              // —— Quick Amount Chips ——
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [50000, 100000, 200000, 500000, 1000000].map((
                    amount,
                  ) {
                    final label = amount >= 1000000
                        ? '${amount ~/ 1000000}M'
                        : '${amount ~/ 1000}K';
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _amountController.text = amount.toString();
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: _amountController.text == amount.toString()
                                ? kElectricBlue.withValues(alpha: 0.2)
                                : kSurface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _amountController.text == amount.toString()
                                  ? kElectricBlue
                                  : kBorder,
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: _amountController.text == amount.toString()
                                  ? kElectricBlue
                                  : kTextSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

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
                stream: _outCategoriesStream,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletChip({
    required String? id,
    required String name,
    required double? balance,
    required IconData icon,
    required bool isSelected,
  }) {
    final balanceStr = balance != null
        ? '${NumberFormat.decimalPattern('vi_VN').format(balance)} đ'
        : '...';

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedWalletId = id;
            _selectedWalletName = name;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? kElectricBlue.withValues(alpha: 0.1) : kSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? kElectricBlue : kBorder,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? kElectricBlue : kTextSecondary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: isSelected ? kElectricBlue : kTextPrimary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    balanceStr,
                    style: TextStyle(
                      color: isSelected ? kElectricBlue : kTextSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
