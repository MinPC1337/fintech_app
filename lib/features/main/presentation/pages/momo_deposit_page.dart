import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dialog_utils.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/deposit_usecase.dart';

class MomoDepositPage extends StatefulWidget {
  const MomoDepositPage({super.key});

  @override
  State<MomoDepositPage> createState() => _MomoDepositPageState();
}

class _MomoDepositPageState extends State<MomoDepositPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool _isDepositing = false;

  void _simulateScanAndDeposit() async {
    if (currentUser == null) return;
    
    setState(() {
      _isDepositing = true;
    });

    // Mô phỏng thiết bị khác quét và delay mạng (2 giây)
    await Future.delayed(const Duration(seconds: 2));

    // Thực thi nạp tiền qua Usecase với số lượng fix (ví dụ: 50.000đ)
    final depositUseCase = sl<DepositUseCase>();
    final result = await depositUseCase.call(currentUser!.uid, 50000.0);

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
          'Đã nhận 50.000 VNĐ vào ví từ Momo.',
          kEmerald,
          Icons.check_circle_outline,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Cần đăng nhập trước")));
    }

    final String qrData = jsonEncode({
      "type": "deposit",
      "receiver_uid": currentUser!.uid,
      "app": "FinTech"
    });

    const Color momoPink = Color(0xFFA50064);

    return Scaffold(
      backgroundColor: Colors.white, // Momo QR page thường có viền trắng
      appBar: AppBar(
        backgroundColor: momoPink,
        title: const Text('Nhận tiền bằng Mã QR', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Đưa mã này cho người chuyển tiền\nhoặc dùng máy khác quét',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 30),
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
                    data: qrData,
                    version: QrVersions.auto,
                    size: 250.0,
                    // Nếu ko có Momo logo thật, sẽ hiện placeholder tròn ở giữa
                    embeddedImage: const AssetImage('assets/Futuristic Pro.png'),
                    embeddedImageStyle: const QrEmbeddedImageStyle(size: Size(40, 40)),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Button for Simulation Purpose Only
              if (_isDepositing)
                const CircularProgressIndicator(color: momoPink)
              else
                ElevatedButton.icon(
                  onPressed: _simulateScanAndDeposit,
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                  label: const Text('Mô phỏng máy khác quét Qr', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: momoPink,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),

              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tính năng giao dịch nguyên tử (Atomic Transaction) đang được áp dụng qua Firebase Realtime.',
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
