import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class ReceiveMoneyPage extends StatelessWidget {
  const ReceiveMoneyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Cần đăng nhập trước')));
    }

    // Tạo số tài khoản dựa trên UID (giống logic ở AuthDataSource)
    final String accountNumber = user.uid.hashCode
        .abs()
        .toString()
        .padLeft(10, '0')
        .substring(0, 10);

    final String qrData = 'fintech://receive?account=$accountNumber';

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        title: const Text('Nhận tiền', style: TextStyle(color: kTextPrimary)),
        iconTheme: const IconThemeData(color: kTextPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              Text(
                'MÃ QR VÍ CÁ NHÂN',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  letterSpacing: 3.0,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Cho người khác quét để chuyển tiền vào ví của bạn',
                textAlign: TextAlign.center,
                style: TextStyle(color: kTextSecondary, fontSize: 13),
              ),
              const SizedBox(height: 32),

              // QR Card
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: kThemeGlassBase,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: kThemeBorderDefault),
                      boxShadow: [
                        BoxShadow(
                          color: kCyan.withValues(alpha: 0.08),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // QR Code trắng trên nền tối
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: 220.0,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Colors.black,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Tên người dùng
                        Text(
                          user.displayName ??
                              user.email?.split('@')[0] ??
                              'Người Dùng',
                          style: const TextStyle(
                            color: kTextPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // UID rút gọn + nút copy
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: accountNumber),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Đã sao chép Mã ví!'),
                                backgroundColor: kEmerald,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: kCyan.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: kCyan.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.wallet,
                                  color: kCyan,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  accountNumber,
                                  style: const TextStyle(
                                    color: kCyan,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.copy_rounded,
                                  color: kCyan,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Hướng dẫn
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kThemeSurfaceSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kThemeBorderDefault),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hướng dẫn nhận tiền',
                      style: TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStep(
                      '1',
                      'Cho người gửi mở màn hình Chuyển khoản trong app',
                    ),
                    _buildStep(
                      '2',
                      'Họ nhập Mã ví của bạn hoặc quét mã QR này',
                    ),
                    _buildStep(
                      '3',
                      'Nhập số tiền và xác nhận — tiền vào ví ngay lập tức',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Nút sao chép toàn bộ UID
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: accountNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Đã sao chép Mã ví đầy đủ!'),
                      backgroundColor: kEmerald,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_all_rounded, color: kCyan),
                label: const Text(
                  'Sao chép Mã ví đầy đủ',
                  style: TextStyle(color: kCyan),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: kCyan.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: kCyan.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: kCyan,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: kTextSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
