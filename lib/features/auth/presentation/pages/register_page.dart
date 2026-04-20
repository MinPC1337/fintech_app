import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../../../../core/theme/app_colors.dart';

class RegisterPage extends StatelessWidget {
  RegisterPage({super.key});

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthVerificationRequired) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
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
                      Icon(Icons.mark_email_unread_outlined, color: kCyan),
                      SizedBox(width: 12),
                      Text(
                        'Xác thực Email',
                        style: TextStyle(
                          color: kTextPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  content: Text(
                    'Đăng ký thành công! Một email xác thực đã được gửi đến ${state.user.email}. Vui lòng kiểm tra hộp thư của bạn để hoàn tất.',
                    style: TextStyle(color: kTextSecondary, height: 1.5),
                  ),
                  actions: [
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: kCyan),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'OK, ĐÃ HIỂU',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            }
          });
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text('Lỗi: ${state.message}')));
        }
      },
      child: Scaffold(
        backgroundColor: kBgColor,
        // Loại bỏ AppBar để không có nút mũi tên quay lại
        body: Stack(
          children: [
            // Atmosphere
            Positioned(
              top: -50,
              right: -150,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kPurple.withValues(alpha: 0.4),
                      blurRadius: 80.0,
                      spreadRadius: 50.0,
                    ),
                  ],
                ),
              ),
            ),
            // Main Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBranding(),
                      const SizedBox(height: 48),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(32.0),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                          child: Container(
                            padding: const EdgeInsets.all(24.0),
                            decoration: BoxDecoration(
                              color: kGlassBg,
                              borderRadius: BorderRadius.circular(32.0),
                              border: Border.all(
                                color: kCyan.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _GlassmorphicTextField(
                                    controller: fullNameController,
                                    hintText: 'Họ và tên',
                                    icon: Icons.person_outline,
                                    focusColor: kCyan,
                                  ),
                                  const SizedBox(height: 20),
                                  _GlassmorphicTextField(
                                    controller: emailController,
                                    hintText: 'Email',
                                    icon: Icons.email_outlined,
                                    focusColor: kCyan,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 20),
                                  _GlassmorphicTextField(
                                    controller: passwordController,
                                    hintText: 'Mật khẩu',
                                    icon: Icons.lock_outline,
                                    focusColor: kPurple,
                                    obscureText: true,
                                  ),
                                  const SizedBox(height: 20),
                                  _GlassmorphicTextField(
                                    controller: confirmPasswordController,
                                    hintText: 'Xác nhận mật khẩu',
                                    icon: Icons.shield_outlined,
                                    focusColor: kRose,
                                    obscureText: true,
                                    validator: (value) {
                                      if (value != passwordController.text) {
                                        return 'Mật khẩu chưa khớp';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 32),
                                  _buildCtaButton(context),
                                  const SizedBox(height: 24),
                                  _buildFooterNav(context),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
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
            child: const Icon(Icons.wallet_outlined, color: kCyan, size: 40),
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
            "FINTECH",
            style: TextStyle(
              fontSize: 40,
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

  Widget _buildCtaButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [kPurple, kCyan]),
        boxShadow: [
          BoxShadow(
            color: kCyan.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState?.validate() ?? false) {
            context.read<AuthCubit>().register(
              emailController.text.trim(),
              passwordController.text.trim(),
              fullNameController.text.trim(),
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
          'TẠO TÀI KHOẢN',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFooterNav(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Đã có tài khoản? ", style: TextStyle(color: kTextSecondary)),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            "Đăng nhập ngay",
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
