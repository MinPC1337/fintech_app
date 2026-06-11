import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Section "Tổng quan tất cả ví nhóm"
class GroupWalletOverviewStats extends StatelessWidget {
  const GroupWalletOverviewStats({super.key});

  @override
  Widget build(BuildContext context) {
    // Kích thước màn hình để responsive

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A), // Deep vibrant blue
            Color(0xFF0F172A), // Dark slate
            Color(0xFF020617), // Very dark slate
          ],
          stops: [0.0, 0.6, 1.0],
        ),
        border: Border.all(color: kCyan.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: kCyan.withValues(alpha: 0.05),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background Elements (Holographic / Glassmorphism)
            Positioned(
              right: -60,
              top: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [kCyan.withValues(alpha: 0.15), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      kEmerald.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Pattern watermark
            Positioned(
              right: 20,
              bottom: 20,
              child: Icon(
                Icons.group_rounded,
                size: 150,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),

            // Nội dung chính
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hàng 1: Tiêu đề + Các tag thông tin
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng quan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          _buildInfoTag(
                            Icons.folder_shared_rounded,
                            '3 Ví',
                            kCyan,
                          ),
                          const SizedBox(width: 8),
                          _buildInfoTag(
                            Icons.group_rounded,
                            '12 Thành viên',
                            kEmerald,
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Hàng 2: Tổng số dư
                  const Text(
                    'Tổng số dư các ví',
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        '22.090.000',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'đ',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Đường kẻ ngang mờ
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 24),

                  // Hàng 3: Tổng đóng góp & Đã chi
                  Row(
                    children: [
                      Expanded(
                        child: _buildBottomStatItem(
                          icon: Icons.download_rounded,
                          iconColor: kEmerald,
                          label: 'Đã đóng góp',
                          value: '37.000.000 đ',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildBottomStatItem(
                          icon: Icons.upload_rounded,
                          iconColor: kRose,
                          label: 'Đã chi tiêu',
                          value: '14.910.000 đ',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStatItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
