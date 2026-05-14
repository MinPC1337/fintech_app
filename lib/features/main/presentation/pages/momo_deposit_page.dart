import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dialog_utils.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/deposit_usecase.dart';
import '../../data/datasources/momo_api_service.dart';
import 'transaction_success_page.dart';

class MomoDepositPage extends StatefulWidget {
  const MomoDepositPage({super.key});

  @override
  State<MomoDepositPage> createState() => _MomoDepositPageState();
}

class _MomoDepositPageState extends State<MomoDepositPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _amountController = TextEditingController(
    text: '10000',
  );

  bool _isLoadingQr = false;
  bool _isProcessingDeposit = false;

  String? _qrCodeUrl;
  String? _currentOrderId;
  String? _currentRequestId;
  double _pendingAmount = 0;

  /// Polling interval
  Timer? _pollingTimer;

  final MomoApiService _momoApiService = MomoApiService();

  @override
  void dispose() {
    _stopPolling();
    _amountController.dispose();
    super.dispose();
  }

  // ─── Tạo QR ───────────────────────────────────────────────────────────────

  Future<void> _generateMoMoQr() async {
    final amountText = _amountController.text.trim();
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

    _stopPolling(); // Hủy polling cũ nếu đang chạy

    setState(() {
      _isLoadingQr = true;
      _qrCodeUrl = null;
    });

    final result = await _momoApiService.createPayment(
      amount: amount,
      orderInfo: 'Nap tien vao vi FinTech',
      userId: currentUser!.uid,
    );

    if (!mounted) return;

    if (result == null || result.qrCodeUrl == null) {
      setState(() => _isLoadingQr = false);
      showNotificationDialog(
        context,
        'Lỗi kết nối MoMo',
        'Không thể tạo mã QR. Kiểm tra lại API Keys hoặc mạng.',
        kRose,
        Icons.error,
      );
      return;
    }

    setState(() {
      _isLoadingQr = false;
      _qrCodeUrl = result.qrCodeUrl;
      _currentOrderId = result.orderId;
      _currentRequestId = result.requestId;
      _pendingAmount = amount;
    });

    // Bắt đầu polling sau khi QR hiển thị
    _startPolling();
  }

  // ─── Polling ──────────────────────────────────────────────────────────────

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (_currentOrderId == null || _currentRequestId == null) return;

      final isPaid = await _momoApiService.queryPaymentStatus(
        orderId: _currentOrderId!,
        requestId: _currentRequestId!,
      );

      if (isPaid && mounted) {
        _stopPolling();
        await _creditWallet(_pendingAmount);
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // ─── Ghi nhận nạp tiền vào Firestore ─────────────────────────────────────

  Future<void> _creditWallet(double amount) async {
    if (currentUser == null || !mounted) return;

    setState(() => _isProcessingDeposit = true);

    final depositUseCase = sl<DepositUseCase>();
    final result = await depositUseCase.call(currentUser!.uid, amount);

    if (!mounted) return;
    setState(() => _isProcessingDeposit = false);

    result.fold(
      (failure) => showNotificationDialog(
        context,
        'Lỗi ghi nhận',
        failure.message,
        kRose,
        Icons.error_outline,
      ),
      (_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) {
              final name = currentUser?.displayName?.isNotEmpty == true
                  ? currentUser!.displayName!
                  : 'Người dùng';
              return TransactionSuccessPage(
                amount: amount,
                receiver: 'Ví cá nhân - $name',
                sender: 'Ví MoMo',
                categoryName: 'Nạp tiền',
              timestamp: DateTime.now(),
              note: 'Nạp tiền vào ví từ MoMo',
              isInternal: true,
              isIncome: true,
            ),
          ),
        );
      },
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Cần đăng nhập trước')));
    }

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Nạp tiền qua MoMo',
          style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: kTextPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Nhập số tiền ────────────────────────────────────────────
              _buildFieldLabel('SỐ TIỀN CẦN NẠP'),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                enabled: _qrCodeUrl == null,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: kSurface,
                  hintText: 'Ví dụ: 50000',
                  hintStyle: const TextStyle(color: kTextSecondary),
                  suffixText: 'VNĐ',
                  suffixStyle: const TextStyle(
                    color: kCyan,
                    fontWeight: FontWeight.bold,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: kCyan, width: 1),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Nút tạo QR ───────────────────────────────────────────────
              ElevatedButton(
                onPressed: (_isLoadingQr || _qrCodeUrl != null)
                    ? null
                    : _generateMoMoQr,
                style:
                    ElevatedButton.styleFrom(
                      backgroundColor: kCyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ).copyWith(
                      backgroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(WidgetState.disabled)) {
                          return kCyan.withValues(alpha: 0.4);
                        }
                        return kCyan;
                      }),
                    ),
                child: _isLoadingQr
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'TẠO MÃ QR MOMO',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
              ),

              // ── Hiển thị QR + trạng thái polling ────────────────────────
              if (_qrCodeUrl != null) ...[
                const SizedBox(height: 40),

                _buildFieldLabel('HÃY QUÉT MÃ DƯỚI ĐÂY'),
                const SizedBox(height: 20),

                // Container QR với hiệu ứng Glassmorphism
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: kThemeGlassBase,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: kThemeBorderDefault),
                      ),
                      child: Center(
                        child: QrImageView(
                          data: _qrCodeUrl!,
                          version: QrVersions.auto,
                          size: 250.0,
                          backgroundColor: Colors.white,
                          embeddedImage: const AssetImage(
                            'assets/Futuristic Pro.png',
                          ),
                          embeddedImageStyle: const QrEmbeddedImageStyle(
                            size: Size(40, 40),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Trạng thái chờ
                if (_isProcessingDeposit)
                  Column(
                    children: [
                      const CircularProgressIndicator(color: kPurple),
                      const SizedBox(height: 12),
                      Text(
                        'Đang ghi nhận thanh toán...',
                        style: TextStyle(color: kTextSecondary),
                      ),
                    ],
                  )
                else
                  _buildPollingStatus(),

                const SizedBox(height: 24),

                // Nút huỷ / tạo QR mới
                OutlinedButton(
                  onPressed: () {
                    _stopPolling();
                    setState(() {
                      _qrCodeUrl = null;
                      _currentOrderId = null;
                      _currentRequestId = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kRose),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'HỦY — TẠO QR MỚI',
                    style: TextStyle(color: kRose, fontWeight: FontWeight.bold),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // ── Chú thích ────────────────────────────────────────────────
              // Container thông tin với Glassmorphism
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kThemeGlassBase,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kThemeBorderDefault),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: kCyan),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Sau khi thanh toán thành công, số dư sẽ được cập nhật tự động.',
                            style: TextStyle(
                              color: kTextSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPollingStatus() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: kTextSecondary.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Đang chờ thanh toán...',
          style: TextStyle(color: kTextSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: kTextSecondary.withValues(alpha: 0.7),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
    );
  }
}
