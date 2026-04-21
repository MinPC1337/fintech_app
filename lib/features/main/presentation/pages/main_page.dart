import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'home_page.dart';
import 'settings_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  // Danh sách các trang. Index 0 là HomePage hiện tại của bạn.
  final List<Widget> _pages = [
    const HomePage(),
    const Scaffold(
      body: Center(
        child: Text(
          "Phân tích Insights",
          style: TextStyle(color: kTextPrimary),
        ),
      ),
    ),
    const Scaffold(
      body: Center(
        child: Text("Ví nhóm / Synergy", style: TextStyle(color: kTextPrimary)),
      ),
    ),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      // Cho phép nội dung tràn xuống dưới thanh điều hướng lơ lửng
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _buildFloatingNavBar(),
    );
  }

  Widget _buildFloatingNavBar() {
    return SizedBox(
      height: 125, // Độ cao tổng thể để chứa cả nút Scan nhô lên
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 1. Thanh Dock Glassmorphism (Kính mờ không gian)
          Positioned(
            bottom: 25, // bottom-8: Cách đáy 32px tạo cảm giác lơ lửng
            left: 24, // Thụt vào 2 bên
            right: 24,
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32), // Pill Shape
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5), // Bóng đổ sâu
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // Blur 20px
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.03,
                      ), // Nền trắng mờ 3%
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: 0.1,
                        ), // Viền mảnh 10%
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildNavItem(0, Icons.home_outlined, 'Home'),
                        _buildNavItem(1, Icons.pie_chart_outline, 'Stats'),
                        const SizedBox(
                          width: 64,
                        ), // Không gian trống cho nút Scan ở giữa
                        _buildNavItem(2, Icons.group_outlined, 'Group'),
                        _buildNavItem(3, Icons.settings_outlined, 'Settings'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. Điểm nhấn trung tâm (Elevated Scan Button)
          Positioned(
            bottom: 45, // Đẩy trồi lên khỏi thanh dock
            child: _buildScanButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // Squircle mô phỏng Force Field
          color: isSelected ? kCyan.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          size: 28,
          // Active: Sáng rực Cyan | Inactive: Trắng đục mờ 40%
          color: isSelected ? kCyan : Colors.white.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildScanButton() {
    return Container(
      width: 76,
      height: 76,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        // Màu đen nguyên bản trùng với nền app để tạo viền chìm (Negative Space)
        // cắt sâu vào thanh dock kính mờ bên dưới
        color: kBgColor,
      ),
      padding: const EdgeInsets.all(6), // Tạo độ dày cho viền chìm
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Dải màu bùng nổ Cyan -> Tím
          gradient: const LinearGradient(
            colors: [kCyan, kPurple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            // Quầng sáng ảo ảnh Neon Glow
            BoxShadow(
              color: kCyan.withValues(alpha: 0.6),
              blurRadius: 30,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              // Thêm logic mở Camera quét mã QR của bạn ở đây
            },
            child: const Icon(
              Icons.qr_code_scanner,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}
