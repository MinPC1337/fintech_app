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

class MomoDepositPage extends StatefulWidget {
  const MomoDepositPage({super.key});

  @override
  State<MomoDepositPage> createState() => _MomoDepositPageState();
}

class _MomoDepositPageState extends State<MomoDepositPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _amountController =
      TextEditingController(text: '10000');

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
          context, 'Lỗi', 'Số tiền không hợp lệ', kRose, Icons.error);
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
      (_) => showNotificationDialog(
        context,
        '✅ Thanh toán thành công!',
        'Đã nhận ${amount.toStringAsFixed(0)} VNĐ vào ví từ MoMo.',
        kEmerald,
        Icons.check_circle_outline,
        onOkPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
          body: Center(child: Text('Cần đăng nhập trước')));
    }

    const Color momoPink = Color(0xFFA50064);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: momoPink,
        title: const Text('Nạp tiền qua MoMo',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Nhập số tiền ────────────────────────────────────────────
              const Text(
                'Nhập số tiền muốn nạp:',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                enabled: _qrCodeUrl == null, // Khoá khi đang chờ thanh toán
                decoration: InputDecoration(
                  hintText: 'Ví dụ: 50000',
                  suffixText: 'VNĐ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: momoPink),
                  ),
                ),
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),

              // ── Nút tạo QR ───────────────────────────────────────────────
              ElevatedButton(
                onPressed:
                    (_isLoadingQr || _qrCodeUrl != null) ? null : _generateMoMoQr,
                style: ElevatedButton.styleFrom(
                  backgroundColor: momoPink,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoadingQr
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Tạo Mã QR MoMo',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
              ),

              // ── Hiển thị QR + trạng thái polling ────────────────────────
              if (_qrCodeUrl != null) ...[
                const SizedBox(height: 40),

                const Text(
                  'Dùng ứng dụng MoMo quét mã dưới đây',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 20),

                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: _qrCodeUrl!,
                      version: QrVersions.auto,
                      size: 250.0,
                      embeddedImage:
                          const AssetImage('assets/Futuristic Pro.png'),
                      embeddedImageStyle:
                          const QrEmbeddedImageStyle(size: Size(40, 40)),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Trạng thái chờ
                if (_isProcessingDeposit)
                  const Column(
                    children: [
                      CircularProgressIndicator(color: momoPink),
                      SizedBox(height: 12),
                      Text(
                        'Đang ghi nhận thanh toán...',
                        style: TextStyle(color: Colors.black54),
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
                    side: const BorderSide(color: momoPink),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Huỷ — Tạo QR mới',
                      style: TextStyle(color: momoPink)),
                ),
              ],

              const SizedBox(height: 32),

              // ── Chú thích ────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'App sẽ tự động kiểm tra trạng thái thanh toán mỗi 4 giây. Sau khi bạn thanh toán thành công, số dư sẽ được cập nhật tự động.',
                        style:
                            TextStyle(color: Colors.black87, fontSize: 13),
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

  Widget _buildPollingStatus() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.grey.shade400,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Đang chờ thanh toán...',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
      ],
    );
  }
}
