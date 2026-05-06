import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dialog_utils.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/transfer_to_user_usecase.dart';
import 'qr_scanner_page.dart';

class SendToUserPage extends StatefulWidget {
  /// Pre-fill receiver UID nếu được truyền từ QR scanner
  final String? initialReceiverUid;

  const SendToUserPage({super.key, this.initialReceiverUid});

  @override
  State<SendToUserPage> createState() => _SendToUserPageState();
}

class _SendToUserPageState extends State<SendToUserPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late final TextEditingController _uidController;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _isSending = false;

  /// Mở QrScannerPage và điền UID người nhận từ QR ví nội bộ.
  Future<void> _scanWalletQr() async {
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (_) => const QrScannerPage(
          title: 'Quét QR ví',
          hint: 'Quét mã QR ví của người nhận để tự động điền Mã ví',
        ),
      ),
    );

    if (result == null || result.isEmpty) return;

    final rawTrimmed = result.trim();
    if (rawTrimmed.startsWith('fintech://receive?uid=')) {
      _uidController.text = rawTrimmed.replaceAll('fintech://receive?uid=', '');
    } else {
      _uidController.text = rawTrimmed;
    }
  }

  @override
  void initState() {
    super.initState();
    _uidController = TextEditingController(
      text: widget.initialReceiverUid ?? '',
    );
  }

  @override
  void dispose() {
    _uidController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _handleSend() async {
    if (currentUser == null) return;

    final receiverUid = _uidController.text.trim();
    final amountText = _amountController.text.trim();

    if (receiverUid.isEmpty) {
      showNotificationDialog(
        context,
        'Lỗi',
        'Vui lòng nhập Mã ví người nhận',
        kRose,
        Icons.error,
      );
      return;
    }

    if (receiverUid == currentUser!.uid) {
      showNotificationDialog(
        context,
        'Lỗi',
        'Không thể chuyển tiền cho chính mình',
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

    setState(() => _isSending = true);

    final useCase = sl<TransferToUserUseCase>();
    final result = await useCase.call(currentUser!.uid, receiverUid, amount);

    setState(() => _isSending = false);

    result.fold(
      (failure) => showNotificationDialog(
        context,
        'Thất bại',
        failure.message,
        kRose,
        Icons.error_outline,
      ),
      (_) => showNotificationDialog(
        context,
        'Thành công',
        'Đã chuyển ${amount.toStringAsFixed(0)} VNĐ vào ví người nhận.',
        kEmerald,
        Icons.check_circle_outline,
        onOkPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Cần đăng nhập trước')));
    }

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        title: const Text(
          'Chuyển vào ví',
          style: TextStyle(color: kTextPrimary),
        ),
        iconTheme: const IconThemeData(color: kTextPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero header
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: kThemeGlassBase,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: kThemeBorderDefault),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: kPurple.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            boxShadow: [AppGlows.purple],
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: kPurple,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chuyển tiền nội bộ',
                              style: TextStyle(
                                color: kTextPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Chuyển trực tiếp giữa các ví trong app',
                              style: TextStyle(
                                color: kTextSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Mã ví người nhận
              _buildLabel('Mã ví người nhận'),
              const SizedBox(height: 8),
              TextField(
                controller: _uidController,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
                decoration: _inputDecoration(
                  hint: 'Mã ví (UID) người nhận',
                  icon: Icons.wallet_outlined,
                  iconColor: kPurple,
                  scanAction: _scanWalletQr,
                ),
              ),

              const SizedBox(height: 20),

              // Số tiền
              _buildLabel('Số tiền chuyển'),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                decoration: _inputDecoration(
                  hint: '0',
                  icon: Icons.attach_money_rounded,
                  iconColor: kCyan,
                  suffix: 'VNĐ',
                ),
              ),

              const SizedBox(height: 20),

              // Ghi chú
              _buildLabel('Ghi chú (tuỳ chọn)'),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                style: const TextStyle(color: kTextPrimary, fontSize: 14),
                decoration: _inputDecoration(
                  hint: 'Ví dụ: Trả tiền cà phê',
                  icon: Icons.edit_note_rounded,
                  iconColor: kTextSecondary,
                ),
              ),

              const SizedBox(height: 40),

              // Nút chuyển tiền
              ElevatedButton(
                onPressed: _isSending ? null : _handleSend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPurple,
                  disabledBackgroundColor: kPurple.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isSending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Chuyển tiền ngay',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 16),

              // Cảnh báo
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kThemeSurfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kThemeBorderDefault),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: kCyan, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Giao dịch được xử lý nguyên tử — tiền trừ và cộng đồng thời, không thể hoàn tác sau khi xác nhận.',
                        style: TextStyle(
                          color: kTextSecondary,
                          fontSize: 12,
                          height: 1.5,
                        ),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: kTextSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required Color iconColor,
    String? suffix,
    VoidCallback? scanAction,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: kTextSecondary),
      suffixText: suffix,
      suffixStyle: const TextStyle(color: kTextSecondary, fontSize: 14),
      prefixIcon: Icon(icon, color: iconColor, size: 20),
      suffixIcon: scanAction != null
          ? IconButton(
              tooltip: 'Quét mã QR',
              icon: const Icon(Icons.qr_code_scanner_rounded, color: kPurple),
              onPressed: scanAction,
            )
          : null,
      filled: true,
      fillColor: kThemeSurfaceSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: kThemeBorderDefault),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: kThemeBorderDefault),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kCyan),
      ),
    );
  }
}
