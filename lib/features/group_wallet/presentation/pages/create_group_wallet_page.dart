import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Trang tạo ví nhóm mới — placeholder UI.
/// Logic (tên, ảnh nhóm, màu, v.v.) sẽ được bổ sung sau.
class CreateGroupWalletPage extends StatelessWidget {
  const CreateGroupWalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: SingleChildScrollView(
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
                      child: Icon(
                        Icons.add_a_photo_rounded,
                        color: kCyan.withValues(alpha: 0.6),
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Thêm ảnh nhóm',
                      style: TextStyle(
                        color: kCyan.withValues(alpha: 0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Name field ──────────────────────
              _FieldLabel(label: 'Tên ví nhóm'),
              const SizedBox(height: 8),
              _StyledTextField(
                hint: 'Ví dụ: Nhà chung 2026, Du lịch...',
                icon: Icons.group_rounded,
              ),
              const SizedBox(height: 24),

              // ── Description field ──────────────────────
              _FieldLabel(label: 'Mô tả (tùy chọn)'),
              const SizedBox(height: 8),
              _StyledTextField(
                hint: 'Ghi chú thêm về ví nhóm...',
                icon: Icons.notes_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 28),

              // ── Color palette ──────────────────────
              _FieldLabel(label: 'Màu sắc nhóm'),
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
                  children: [
                    _ColorDot(color: kCyan, selected: true),
                    _ColorDot(color: kPurple, selected: false),
                    _ColorDot(color: kRose, selected: false),
                    _ColorDot(color: kEmerald, selected: false),
                    _ColorDot(color: kElectricBlue, selected: false),
                    _ColorDot(
                      color: const Color(0xFFF59E0B),
                      selected: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // ── Create button ──────────────────────
              Container(
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [kCyan, kPurple],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kCyan.withValues(alpha: 0.3),
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
                    onTap: () {
                      // TODO: logic tạo ví nhóm
                      Navigator.pop(context);
                    },
                    child: const Center(
                      child: Text(
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
  });

  final String hint;
  final IconData icon;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
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
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
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
        border: Border.all(
          color: color,
          width: selected ? 2.5 : 1.2,
        ),
        boxShadow: [
          if (selected)
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 14,
            ),
        ],
      ),
    );
  }
}
