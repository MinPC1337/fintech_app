import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../../domain/entities/user.dart';

class ProfilePage extends StatelessWidget {
  final User currentUser;

  ProfilePage({super.key, required this.currentUser});

  final TextEditingController fullNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    fullNameController.text = currentUser.fullName;

    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ cá nhân')),
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
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: currentUser.avatarUrl.isNotEmpty
                      ? NetworkImage(currentUser.avatarUrl)
                      : null,
                  child: currentUser.avatarUrl.isEmpty
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  'Email: ${currentUser.email}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: fullNameController,
                  decoration: const InputDecoration(labelText: 'Họ và tên'),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    context.read<AuthCubit>().updateProfile(
                      currentUser.uid,
                      fullNameController.text.trim(),
                      currentUser.avatarUrl,
                      currentUser.fcmToken,
                    );
                  },
                  child: const Text('Cập nhật'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
