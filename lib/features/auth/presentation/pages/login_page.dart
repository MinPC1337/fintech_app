import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'register_page.dart';
import '../../../../features/main/presentation/pages/main_page.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dialog_utils.dart';
import '../../../../injection_container.dart';
import '../../../../core/services/push_notification_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _savedEmail;
  bool _isCheckingSavedEmail = true;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('last_email');
      if (email != null && email.isNotEmpty) {
        setState(() {
          _savedEmail = email;
          emailController.text = email;
          _isCheckingSavedEmail = false;
        });
      } else {
        setState(() {
          _isCheckingSavedEmail = false;
        });
      }
    } catch (e) {
      setState(() {
        _isCheckingSavedEmail = false;
      });
    }
  }

  void _clearSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_email');
    setState(() {
      _savedEmail = null;
      emailController.clear();
      passwordController.clear();
    });
  }

  Future<void> _saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_email', email);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          _saveEmail(emailController.text.trim());
          sl<PushNotificationService>().syncTokenForUser(state.user.uid);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainPage()),
          );
        } else if (state is AuthPasswordResetSent) {
          showNotificationDialog(
            context,
            'Đã gửi Email',
            'Email khôi phục mật khẩu đã được gửi. Hãy kiểm tra hộp thư!',
            kCyan,
            Icons.mark_email_read_outlined,
          );
        } else if (state is AuthError) {
          showNotificationDialog(
            context,
            'Lỗi',
            state.message,
            kRose,
            Icons.error_outline,
          );
        }
      },
      child: Scaffold(
        backgroundColor: kBgColor,
        body: Stack(
          children: [
            // Atmosphere & Decor
            Positioned(
              top: MediaQuery.of(context).size.height * 0.1,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: kCyan.withValues(alpha: 0.4),
                        blurRadius: 80.0,
                        spreadRadius: 20.0,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Main Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Branding
                      _buildBranding(),
                      const SizedBox(height: 48),

                      // Form Controls
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            if (_isCheckingSavedEmail)
                              const SizedBox(
                                height: 76,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: kCyan,
                                  ),
                                ),
                              )
                            else if (_savedEmail != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: kCyan.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: kCyan.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.account_circle,
                                      color: kCyan,
                                      size: 40,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Xin chào,",
                                            style: TextStyle(
                                              color: kTextSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            _savedEmail!,
                                            style: const TextStyle(
                                              color: kTextPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ] else ...[
                              _GlassmorphicTextField(
                                controller: emailController,
                                hintText: 'Email',
                                icon: Icons.email_outlined,
                                focusColor: kCyan,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Vui lòng nhập email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                            _GlassmorphicTextField(
                              controller: passwordController,
                              hintText: 'Mật khẩu',
                              icon: Icons.lock_outline,
                              focusColor: kPurple,
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập mật khẩu';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      // Chỉ hiển thị nút chuyển tài khoản nếu đã có email được lưu từ lần đăng nhập trước
                      if (_savedEmail != null) ...[
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _clearSavedEmail,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              "Đăng nhập bằng tài khoản khác",
                              style: TextStyle(
                                color: kCyan,
                                fontSize: 14,
                                decoration: TextDecoration.none,
                                decorationColor: kCyan,
                              ),
                            ),
                          ),
                        ),
                      ],

                      // Utilities
                      _buildUtilities(context),
                      const SizedBox(height: 32),

                      // Call-to-Action
                      _buildCtaButton(context),
                      const SizedBox(height: 48),

                      // Alternative Authentication
                      _buildAlternativeAuth(context),
                    ],
                  ),
                ),
              ),
            ),
            // Loading Indicator
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                if (state is AuthLoading) {
                  return Container(
                    color: kBgColor.withValues(alpha: 0.7),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranding() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(colors: [kCyan, kPurple]),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kBgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Image.asset('assets/Icon.png', width: 48, height: 48),
          ),
        ),
        const SizedBox(height: 24),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            colors: [kCyan, kPurple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          child: const Text(
            "SMART FINANCE",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: kTextPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "HỆ THỐNG QUẢN LÝ TÀI CHÍNH",
          style: TextStyle(
            color: kTextSecondary,
            letterSpacing: 4,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildUtilities(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => _showForgotPasswordDialog(context),
            child: Text(
              "Quên mật khẩu?",
              style: TextStyle(color: kTextSecondary),
            ),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    // Dùng chung email từ form nếu người dùng đã nhập
    final TextEditingController resetEmailController = TextEditingController(
      text: emailController.text,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kBgColor,
        elevation: 20,
        shadowColor: kCyan.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: kCyan.withValues(alpha: 0.2)),
        ),
        title: const Row(
          children: [
            Icon(Icons.lock_reset_outlined, color: kCyan),
            SizedBox(width: 12),
            Text(
              'Khôi phục mật khẩu',
              style: TextStyle(
                color: kTextPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nhập email của bạn để nhận liên kết khôi phục mật khẩu.',
              style: TextStyle(color: kTextSecondary, height: 1.5),
            ),
            const SizedBox(height: 20),
            _GlassmorphicTextField(
              controller: resetEmailController,
              hintText: 'Email',
              icon: Icons.email_outlined,
              focusColor: kCyan,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
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
            style: TextButton.styleFrom(foregroundColor: kCyan),
            onPressed: () {
              final email = resetEmailController.text.trim();
              if (email.isNotEmpty) {
                context.read<AuthCubit>().resetPassword(email);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text(
              'GỬI',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCtaButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [kCyan, kPurple]),
        boxShadow: [
          BoxShadow(
            color: kPurple.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState?.validate() ?? false) {
            context.read<AuthCubit>().login(
              emailController.text.trim(),
              passwordController.text.trim(),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'ĐĂNG NHẬP',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAlternativeAuth(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Chưa có tài khoản? ", style: TextStyle(color: kTextSecondary)),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RegisterPage()),
            );
          },
          child: const Text(
            "Đăng ký ngay",
            style: TextStyle(color: kCyan, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _GlassmorphicTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final Color focusColor;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _GlassmorphicTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.focusColor,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  });

  @override
  State<_GlassmorphicTextField> createState() => _GlassmorphicTextFieldState();
}

class _GlassmorphicTextFieldState extends State<_GlassmorphicTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: kGlassBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isFocused ? widget.focusColor : kGlassBorder,
              width: 1.5,
            ),
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: _isObscured,
            keyboardType: widget.keyboardType,
            style: const TextStyle(color: kTextPrimary),
            validator: widget.validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 12,
              ),
              errorStyle: const TextStyle(color: kRose),
              hintText: widget.hintText,
              hintStyle: TextStyle(color: kTextSecondary),
              prefixIcon: Icon(
                widget.icon,
                color: _isFocused ? widget.focusColor : kTextSecondary,
              ),
              suffixIcon: widget.obscureText
                  ? IconButton(
                      icon: Icon(
                        _isObscured
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: kTextSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscured = !_isObscured;
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
