import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../../domain/entities/user.dart';

class ProfilePage extends StatefulWidget {
  final User currentUser;

  const ProfilePage({super.key, required this.currentUser});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController fullNameController;

  @override
  void initState() {
    super.initState();
    fullNameController = TextEditingController(
      text: widget.currentUser.fullName,
    );
  }

  @override
  void dispose() {
    fullNameController.dispose();
    super.dispose();
  }

  void _handleUpdate() {
    if (fullNameController.text.trim().isEmpty) return;

    context.read<AuthCubit>().updateProfile(
      widget.currentUser.uid,
      fullNameController.text.trim(),
      widget.currentUser.avatarUrl,
      widget.currentUser.fcmToken,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Hồ sơ cá nhân',
          style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: kTextPrimary),
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cập nhật hồ sơ thành công')),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Lỗi: ${state.message}')));
          }
        },
        builder: (context, state) {
          final bool isLoading = state is AuthLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar Section
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [kCyan, kPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: kBgColor,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/app_icon.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Email Info (Non-editable)
                _buildFieldLabel('ĐỊA CHỈ EMAIL'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kSurface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Text(
                    widget.currentUser.email,
                    style: const TextStyle(color: kTextSecondary, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 24),

                // Full Name Input
                _buildFieldLabel('HỌ VÀ TÊN'),
                const SizedBox(height: 8),
                TextField(
                  controller: fullNameController,
                  style: const TextStyle(color: kTextPrimary),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: kSurface,
                    hintText: 'Nhập họ tên của bạn',
                    hintStyle: const TextStyle(color: kTextSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: kCyan, width: 1),
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Update Button
                ElevatedButton(
                  onPressed: isLoading ? null : _handleUpdate,
                  style:
                      ElevatedButton.styleFrom(
                        backgroundColor: kCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ).copyWith(
                        backgroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.disabled)
                              ? Colors.grey
                              : kCyan,
                        ),
                      ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'LƯU THAY ĐỔI',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: kTextSecondary.withValues(alpha: 0.7),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
    );
  }
}
