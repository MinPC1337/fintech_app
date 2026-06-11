import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'group_wallet_glass_card.dart';

/// Section "Thành viên hoạt động" — compact card showing active members.
/// Designed to be placed side-by-side with DebtsCard.
class GroupWalletMembersCard extends StatelessWidget {
  const GroupWalletMembersCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GroupWalletGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Thành viên hoạt động',
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {},
            child: Row(
              children: [
                Text(
                  'Xem tất cả thành viên',
                  style: TextStyle(
                    color: kCyan.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: kCyan.withValues(alpha: 0.8),
                  size: 10,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Members list
          ..._mockMembers.map((m) => _MemberItem(data: m)),
        ],
      ),
    );
  }
}

class _MemberItem extends StatelessWidget {
  const _MemberItem({required this.data});

  final _MockMember data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  data.avatarColor.withValues(alpha: 0.5),
                  data.avatarColor.withValues(alpha: 0.2),
                ],
              ),
              border: Border.all(
                color: data.avatarColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                data.initial,
                style: TextStyle(
                  color: data.avatarColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Name + role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.role,
                  style: TextStyle(
                    color: kTextSecondary.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Amount info
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Đã góp',
                style: TextStyle(
                  color: kTextSecondary.withValues(alpha: 0.5),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.contributed,
                style: TextStyle(
                  color: kEmerald,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Mock data ──────────────────────────────────────────
class _MockMember {
  final String name;
  final String initial;
  final String role;
  final String contributed;
  final Color avatarColor;

  const _MockMember({
    required this.name,
    required this.initial,
    required this.role,
    required this.contributed,
    required this.avatarColor,
  });
}

const _mockMembers = <_MockMember>[
  _MockMember(
    name: 'Bạn',
    initial: 'B',
    role: 'Quản trị viên',
    contributed: '4.300.000 đ',
    avatarColor: kCyan,
  ),
  _MockMember(
    name: 'Minh',
    initial: 'M',
    role: 'Thành viên',
    contributed: '2.000.000 đ',
    avatarColor: kPurple,
  ),
  _MockMember(
    name: 'Lan',
    initial: 'L',
    role: 'Thành viên',
    contributed: '1.800.000 đ',
    avatarColor: kEmerald,
  ),
  _MockMember(
    name: 'Hùng',
    initial: 'H',
    role: 'Thành viên',
    contributed: '1.100.000 đ',
    avatarColor: kRose,
  ),
];
