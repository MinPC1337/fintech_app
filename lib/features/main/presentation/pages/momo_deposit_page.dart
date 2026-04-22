
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
  final TextEditingController _amountController = TextEditingController(text: '50000');
  
  bool _isDepositing = false;
  bool _isLoadingQr = false;
  String? _qrCodeUrl;
  final MomoApiService _momoApiService = MomoApiService();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _generateMoMoQr() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      showNotificationDialog(context, 'Lỗi', 'Vui lòng nhập số tiền', kRose, Icons.error);
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      showNotificationDialog(context, 'Lỗi', 'Số tiền không hợp lệ', kRose, Icons.error);
      return;
    }

    setState(() {
      _isLoadingQr = true;
      _qrCodeUrl = null;
    });

    final qrUrl = await _momoApiService.createPayment(
      amount: amount,
      orderInfo: 'Nap tien vao vi FinTech',
      userId: currentUser!.uid,
    );

    setState(() {
      _isLoadingQr = false;
      _qrCodeUrl = qrUrl;
    });

    if (qrUrl == null) {
      if (mounted) {
        showNotificationDialog(
          context, 
          'Lỗi kết nối MoMo', 
          'Không thể tạo mã QR. Hãy kiểm tra lại API Keys hoặc mạng.', 
          kRose, 
          Icons.error
        );
      }
    }
  }

  void _simulateScanAndDeposit() async {
    if (currentUser == null) return;
    
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText) ?? 50000.0;

    setState(() {
      _isDepositing = true;
    });

    // Mô phỏng thiết bị khác quét và delay mạng (2 giây)
    await Future.delayed(const Duration(seconds: 2));

    // Thực thi nạp tiền qua Usecase
    final depositUseCase = sl<DepositUseCase>();
    final result = await depositUseCase.call(currentUser!.uid, amount);

    setState(() {
      _isDepositing = false;
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
        showNotificationDialog(
          context,
          'Thành công',
          'Đã nhận ${amount.toStringAsFixed(0)} VNĐ vào ví từ MoMo.',
          kEmerald,
          Icons.check_circle_outline,
          onOkPressed: () {
            // Có thể back về trang chủ sau khi nạp thành công
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Cần đăng nhập trước")));
    }

    const Color momoPink = Color(0xFFA50064);

    return Scaffold(
      backgroundColor: Colors.white, // Momo QR page thường có viền trắng
      appBar: AppBar(
        backgroundColor: momoPink,
        title: const Text('Nạp tiền qua MoMo', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Nhập số tiền muốn nạp:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoadingQr ? null : _generateMoMoQr,
                style: ElevatedButton.styleFrom(
                  backgroundColor: momoPink,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoadingQr 
                  ? const SizedBox(
                      height: 20, 
                      width: 20, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : const Text('Tạo Mã QR MoMo', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              
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
                      data: _qrCodeUrl!, // Dùng qrCodeUrl nhận từ MoMo
                      version: QrVersions.auto,
                      size: 250.0,
                      embeddedImage: const AssetImage('assets/Futuristic Pro.png'),
                      embeddedImageStyle: const QrEmbeddedImageStyle(size: Size(40, 40)),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Nút bấm mô phỏng thanh toán thành công
                if (_isDepositing)
                  const Center(child: CircularProgressIndicator(color: momoPink))
                else
                  ElevatedButton.icon(
                    onPressed: _simulateScanAndDeposit,
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: const Text('Mô phỏng thanh toán xong', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kEmerald,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
              ],

              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tính năng Tạo QR gọi trực tiếp lên MoMo UAT. Nút "Mô phỏng thanh toán xong" dùng để cập nhật số dư Firebase do chưa có Backend lắng nghe IPN.',
                        style: TextStyle(color: Colors.black87, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
