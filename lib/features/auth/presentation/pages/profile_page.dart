import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  File? _selectedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    fullNameController = TextEditingController(text: widget.currentUser.fullName);
  }

  @override
  void dispose() {
    fullNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _handleUpdate() async {
    if (fullNameController.text.trim().isEmpty) return;

    setState(() {
      _isUploading = true;
    });

    String avatarUrl = widget.currentUser.avatarUrl;

    try {
      if (_selectedImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('avatars/${widget.currentUser.uid}.jpg');
        await ref.putFile(_selectedImage!);
        avatarUrl = await ref.getDownloadURL();
      }

      if (mounted) {
        context.read<AuthCubit>().updateProfile(
              widget.currentUser.uid,
              fullNameController.text.trim(),
              avatarUrl,
              widget.currentUser.fcmToken,
            );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải ảnh lên: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ cá nhân')),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cập nhật hồ sơ thành công')),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi: ${state.message}')),
            );
          }
        },
        builder: (context, state) {
          if (state is AuthLoading || _isUploading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!) as ImageProvider
                              : (widget.currentUser.avatarUrl.isNotEmpty
                                  ? NetworkImage(widget.currentUser.avatarUrl)
                                  : null),
                          child: _selectedImage == null &&
                                  widget.currentUser.avatarUrl.isEmpty
                              ? const Icon(Icons.person, size: 50)
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Email: ${widget.currentUser.email}',
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
                    onPressed: _handleUpdate,
                    child: const Text('Cập nhật'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
