import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/presentation/pages/login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Khối Tiêu đề
              const Text(
                'Cài đặt',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                  letterSpacing: -1.2, // tracking-tight
                ),
              ),
              const SizedBox(height: 32),

              // 2. Thẻ Hồ sơ Cá nhân
              _buildProfileCard(),
              const SizedBox(height: 48),

              // 3. Khối Danh mục Tùy chỉnh
              _buildSettingsSection(
                title: 'TÀI KHOẢN',
                children: [
                  _SettingsListItem(
                    icon: Icons.person_outline,
                    color: kCyan,
                    text: 'Thông tin cá nhân',
                    onTap: () {},
                  ),
                  _SettingsListItem(
                    icon: Icons.lock_outline,
                    color: kPurple,
                    text: 'Bảo mật & Mật khẩu',
                    onTap: () {},
                  ),
                  _SettingsListItem(
                    icon: Icons.notifications_none_outlined,
                    color: Colors.orange,
                    text: 'Thông báo',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildSettingsSection(
                title: 'GIAO DIỆN',
                children: [
                  _SettingsListItem(
                    icon: Icons.palette_outlined,
                    color: kEmerald,
                    text: 'Tùy chỉnh chủ đề',
                    onTap: () {},
                  ),
                  _SettingsListItem(
                    icon: Icons.translate_outlined,
                    color: kRose,
                    text: 'Ngôn ngữ',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // 4. Khối Đăng xuất
              _LogoutButton(),
              const SizedBox(height: 120), // Padding for floating nav bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        String? displayName;
        String? subtitle;
        String? avatarUrl;
        if (authState is AuthSuccess) {
          displayName = authState.user.fullName;
          subtitle = authState.user.email;
          avatarUrl = authState.user.avatarUrl;
        } else {
          final firebaseUser = FirebaseAuth.instance.currentUser;
          displayName = firebaseUser?.displayName ?? 'Nguyễn Văn A';
          subtitle = firebaseUser?.email ?? 'không có email';
          avatarUrl = null;
        }

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: kCyan.withValues(alpha: 0.1),
                blurRadius: 30,
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: kGlassBg,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: kCyan.withValues(alpha: 0.2)),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Lõi năng lượng bên trong
                    Positioned(
                      top: -50,
                      left: -50,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kCyan.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Row(
                          children: [
                            // Avatar
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [kCyan, kPurple],
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: kBgColor,
                                ),
                                child: ClipOval(
                                  child:
                                      (avatarUrl == null || avatarUrl.isEmpty)
                                      ? Image.asset(
                                          'assets/app_icon.png',
                                          width: 56,
                                          height: 56,
                                        )
                                      : Image.network(
                                          avatarUrl,
                                          width: 56,
                                          height: 56,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Tên & ID
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: kTextPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      fontFamily: 'monospace', // font-mono
                                      color: kTextSecondary,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Huy hiệu xác thực
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: kEmerald.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: kEmerald.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FadeTransition(
                                opacity: _pulseController,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: kEmerald,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: kEmerald, blurRadius: 4),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Đã xác thực',
                                style: TextStyle(
                                  color: kEmerald,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: kTextSecondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 4.0, // tracking-widest
          ),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: kGlassBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(children: children),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsListItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback onTap;

  const _SettingsListItem({
    required this.icon,
    required this.color,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(color: kTextPrimary, fontSize: 16),
                ),
              ),
              Icon(Icons.chevron_right, color: kTextSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatefulWidget {
  @override
  __LogoutButtonState createState() => __LogoutButtonState();
}

class __LogoutButtonState extends State<_LogoutButton> {
  bool _isPressed = false;

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kBgColor,
        elevation: 20,
        shadowColor: kRose.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: kRose.withValues(alpha: 0.2)),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout, color: kRose),
            SizedBox(width: 12),
            Text(
              'Xác nhận',
              style: TextStyle(
                color: kTextPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng không?',
          style: TextStyle(color: kTextSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: kTextSecondary),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'HỦY',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: kRose),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthCubit>().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LoginPage()),
                (Route<dynamic> route) => false,
              );
            },
            child: const Text(
              'ĐĂNG XUẤT',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () => _showLogoutConfirmation(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: kGlassBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: _isPressed
                  ? [
                      BoxShadow(
                        color: kRose.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ]
                  : [],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout, color: kRose),
                SizedBox(width: 12),
                Text(
                  'Đăng xuất',
                  style: TextStyle(
                    color: kRose,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
