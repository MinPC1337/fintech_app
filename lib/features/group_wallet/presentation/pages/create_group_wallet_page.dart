import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/imgbb_client.dart';
import '../../../../core/utils/dialog_utils.dart';
import '../cubit/group_wallet_cubit.dart';
import '../cubit/group_wallet_state.dart';

/// Trang tạo ví nhóm mới — Có kết nối Cubit
class CreateGroupWalletPage extends StatefulWidget {
  const CreateGroupWalletPage({super.key});

  @override
  State<CreateGroupWalletPage> createState() => _CreateGroupWalletPageState();
}

class _CreateGroupWalletPageState extends State<CreateGroupWalletPage> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  Color _selectedColor = kCyan;
  final _picker = ImagePicker();
  String? _imageUrl;
  String? _selectedEmoji;
  bool _isUploadingImage = false;

  static final _imgbbKey = dotenv.env['IMGBB_KEY'] ?? '';

  static const _emojis = [
    '🏠',
    '✈️',
    '🍔',
    '🎁',
    '🎉',
    '🎓',
    '💼',
    '🚗',
    '🏥',
    '🛒',
    '🎮',
    '🐾',
    '💎',
    '💡',
    '⚽',
    '🍿',
    '🚀',
    '⛺',
  ];

  final _colors = [
    kCyan,
    kPurple,
    kRose,
    kEmerald,
    kElectricBlue,
    const Color(0xFFF59E0B),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _onCreate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên ví nhóm')),
      );
      return;
    }

    final cubit = context.read<GroupWalletCubit>();
    final success = await cubit.createGroupWallet(
      name,
      _selectedColor.value,
      imageUrl: _imageUrl,
      emoji: _selectedEmoji,
    );

    if (success && mounted) {
      showNotificationDialog(
        context,
        'Thành công',
        'Tạo ví nhóm thành công!',
        kEmerald,
        Icons.check_circle_outline,
      );
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.pop(context); // Close the dialog
        Navigator.pop(context); // Close CreateGroupWalletPage
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _isUploadingImage = true);
    try {
      final file = File(picked.path);
      final client = ImgbbClient(apiKey: _imgbbKey);
      final uploadedUrl = await client.uploadFile(file);
      setState(() {
        _imageUrl = uploadedUrl;
        _selectedEmoji = null; // Reset emoji when image is uploaded
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload ảnh thất bại. Vui lòng thử lại.')),
      );
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: BlocConsumer<GroupWalletCubit, GroupWalletState>(
          listener: (context, state) {
            if (state is GroupWalletLoaded && state.message != null) {
              // Chúng ta đã xử lý thành công ở _onCreate, chỉ cần dismiss message
              context.read<GroupWalletCubit>().dismissMessage();
            }
          },
          builder: (context, state) {
            final isLoading =
                state is GroupWalletLoading ||
                (state is GroupWalletLoaded && state.isActionInProgress);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Top bar ──────────────────────
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.06),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: kTextPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Tạo ví nhóm mới',
                        style: TextStyle(
                          color: kTextPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // ── Group image placeholder ──────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: _isUploadingImage ? null : _pickAndUploadImage,
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kCyan.withValues(alpha: 0.1),
                              border: Border.all(
                                color: kCyan.withValues(alpha: 0.25),
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: _isUploadingImage
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : (_imageUrl != null)
                                  ? CachedNetworkImage(imageUrl: _imageUrl!, fit: BoxFit.cover)
                                  : (_selectedEmoji != null)
                                  ? Center(
                                      child: Text(
                                        _selectedEmoji!,
                                        style: const TextStyle(fontSize: 40),
                                      ),
                                    )
                                  : Icon(
                                      Icons.add_a_photo_rounded,
                                      color: kCyan.withValues(alpha: 0.6),
                                      size: 36,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _imageUrl != null
                                ? 'Đổi ảnh nhóm'
                                : 'Thêm ảnh nhóm',
                            style: TextStyle(
                              color: kCyan.withValues(alpha: 0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Emoji Selector ──────────────────────
                  const _FieldLabel(label: 'Hoặc chọn Emoji biểu tượng'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _emojis.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final emoji = _emojis[index];
                        final isSelected = _selectedEmoji == emoji;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedEmoji = emoji;
                              _imageUrl =
                                  null; // Clear image if emoji is selected
                            });
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? kCyan.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.05),
                              border: Border.all(
                                color: isSelected
                                    ? kCyan
                                    : Colors.white.withValues(alpha: 0.1),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Name field ──────────────────────
                  const _FieldLabel(label: 'Tên ví nhóm'),
                  const SizedBox(height: 8),
                  _StyledTextField(
                    controller: _nameController,
                    hint: 'Ví dụ: Nhà chung 2026, Du lịch...',
                    icon: Icons.group_rounded,
                  ),
                  const SizedBox(height: 24),

                  // ── Description field ──────────────────────
                  const _FieldLabel(label: 'Mô tả (tùy chọn)'),
                  const SizedBox(height: 8),
                  _StyledTextField(
                    controller: _descController,
                    hint: 'Ghi chú thêm về ví nhóm...',
                    icon: Icons.notes_rounded,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 28),

                  // ── Color palette ──────────────────────
                  const _FieldLabel(label: 'Màu sắc nhóm'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _colors.map((c) {
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = c),
                          child: _ColorDot(
                            color: c,
                            selected: _selectedColor == c,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Create button ──────────────────────
                  Container(
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [
                          _selectedColor,
                          _selectedColor.withValues(alpha: 0.6),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _selectedColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: -4,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: isLoading ? null : _onCreate,
                        child: Center(
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Tạo ví nhóm',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: kTextSecondary.withValues(alpha: 0.9),
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.controller,
  });

  final String hint;
  final IconData icon;
  final int maxLines;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
      cursorColor: kCyan,
      cursorWidth: 2,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.25),
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: maxLines == 1
            ? Icon(icon, color: kCyan.withValues(alpha: 0.6), size: 20)
            : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 44),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        filled: true,
        fillColor: const Color(0xFF1E284A).withValues(alpha: 0.6),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: kCyan.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color, required this.selected});

  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: selected ? 0.3 : 0.15),
        border: Border.all(color: color, width: selected ? 2.5 : 1.2),
        boxShadow: [
          if (selected)
            BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 14),
        ],
      ),
    );
  }
}
