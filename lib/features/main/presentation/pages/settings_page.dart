import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/pages/profile_page.dart';
import 'notifications_page.dart';
import '../../../../core/utils/dialog_utils.dart';

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

  void _showPasswordResetDialog(BuildContext context, AuthState authState) {
    if (authState is! AuthSuccess) return;

    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isOldPasswordVerified = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: kBgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: kPurple.withValues(alpha: 0.2)),
            ),
            title: Row(
              children: [
                Icon(
                  isOldPasswordVerified
                      ? Icons.lock_open_rounded
                      : Icons.lock_outline_rounded,
                  color: kPurple,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Đổi mật khẩu',
                  style: TextStyle(
                    color: kTextPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isOldPasswordVerified) ...[
                  const Text(
                    'Vui lòng nhập mật khẩu hiện tại để tiếp tục.',
                    style: TextStyle(color: kTextSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: oldPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: kTextPrimary),
                    decoration: InputDecoration(
                      hintText: 'Mật khẩu cũ',
                      hintStyle: const TextStyle(color: kTextSecondary),
                      filled: true,
                      fillColor: kThemeSurfaceSecondary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Nhập mật khẩu mới cho tài khoản của bạn.',
                    style: TextStyle(color: kTextSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: kTextPrimary),
                    decoration: InputDecoration(
                      hintText: 'Mật khẩu mới',
                      hintStyle: const TextStyle(color: kTextSecondary),
                      filled: true,
                      fillColor: kThemeSurfaceSecondary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: kTextPrimary),
                    decoration: InputDecoration(
                      hintText: 'Xác nhận mật khẩu mới',
                      hintStyle: const TextStyle(color: kTextSecondary),
                      filled: true,
                      fillColor: kThemeSurfaceSecondary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'HỦY',
                  style: TextStyle(color: kTextSecondary),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (!isOldPasswordVerified) {
                    if (oldPasswordController.text.isNotEmpty) {
                      setDialogState(() => isOldPasswordVerified = true);
                    }
                  } else {
                    final newPass = newPasswordController.text;
                    final confirmPass = confirmPasswordController.text;
                    if (newPass.length >= 8 && newPass == confirmPass) {
                      context.read<AuthCubit>().changePassword(
                        oldPasswordController.text,
                        newPass,
                      );
                      Navigator.pop(ctx);
                    } else {
                      showNotificationDialog(
                        context,
                        'Lỗi',
                        'Mật khẩu không khớp hoặc quá ngắn (tối thiểu 8 ký tự).',
                        kRose,
                        Icons.warning_amber_rounded,
                      );
                    }
                  }
                },
                child: Text(
                  isOldPasswordVerified ? 'CẬP NHẬT' : 'TIẾP TỤC',
                  style: const TextStyle(
                    color: kPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthPasswordChanged) {
          // Chỉ hiển thị thông báo nếu trang này đang ở trên cùng
          if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;

          showNotificationDialog(
            context,
            'Thành công',
            'Chúc mừng! Mật khẩu đã được đổi thành công.',
            kEmerald,
            Icons.check_circle_outline,
          );
        } else if (state is AuthError) {
          if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;

          showNotificationDialog(
            context,
            'Lỗi',
            state.message,
            kRose,
            Icons.error_outline,
          );
        }
      },
      builder: (context, authState) {
        return Stack(
          children: [
            Scaffold(
              backgroundColor: kBgColor,
              body: SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
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
                      _buildProfileCard(authState),
                      const SizedBox(height: 48),

                      // 3. Khối Danh mục Tùy chỉnh
                      _buildSettingsSection(
                        title: 'TÀI KHOẢN',
                        children: [
                          _SettingsListItem(
                            icon: Icons.person_outline,
                            color: kCyan,
                            text: 'Thông tin cá nhân',
                            onTap: () {
                              if (authState is AuthSuccess) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProfilePage(
                                      currentUser: authState.user,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          _SettingsListItem(
                            icon: Icons.lock_outline,
                            color: kPurple,
                            text: 'Bảo mật & Mật khẩu',
                            onTap: () =>
                                _showPasswordResetDialog(context, authState),
                          ),
                          _SettingsListItem(
                            icon: Icons.notifications_none_outlined,
                            color: Colors.orange,
                            text: 'Thông báo',
                            onTap: () {
                              if (authState is AuthSuccess) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => NotificationsPage(
                                      userId: authState.user.uid,
                                    ),
                                  ),
                                );
                              }
                            },
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
                      const SizedBox(
                        height: 120,
                      ), // Padding for floating nav bar
                    ],
                  ),
                ),
              ),
            ),
            if (authState is AuthLoading)
              Container(
                color: kBgColor.withValues(alpha: 0.7),
                child: const Center(
                  child: CircularProgressIndicator(color: kPurple),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildProfileCard(AuthState authState) {
    String? displayName;
    String? subtitle;
    String? avatarUrl;
    if (authState is AuthSuccess) {
      displayName = authState.user.fullName;
      subtitle = authState.user.email;
      avatarUrl = authState.user.avatarUrl;
    } else {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      displayName = firebaseUser?.displayName ?? 'Người dùng';
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
                            gradient: LinearGradient(colors: [kCyan, kPurple]),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: kBgColor,
                            ),
                            child: ClipOval(
                              child: (avatarUrl == null || avatarUrl.isEmpty)
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
                                style: const TextStyle(
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
