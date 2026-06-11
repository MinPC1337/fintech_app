import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Section "Ví nhóm của bạn" — horizontal scrollable wallet cards.
/// Mock data hardcoded for UI-first approach.
class GroupWalletCardCarousel extends StatelessWidget {
  const GroupWalletCardCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            const Text(
              'Ví nhóm của bạn',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {},
              child: Row(
                children: [
                  Text(
                    'Xem tất cả',
                    style: TextStyle(
                      color: kCyan.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: kCyan.withValues(alpha: 0.9),
                    size: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Horizontal card list
        SizedBox(
          height: 195,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: _mockWallets.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final w = _mockWallets[index];
              return _WalletMiniCard(data: w);
            },
          ),
        ),
      ],
    );
  }
}

class _WalletMiniCard extends StatelessWidget {
  const _WalletMiniCard({required this.data});

  final _MockWallet data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            data.accent.withValues(alpha: 0.18),
            const Color(0xFF11182B),
          ],
        ),
        border: Border.all(color: data.accent.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: data.accent.withValues(alpha: 0.1),
            blurRadius: 16,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: icon + member badge + menu
          Row(
            children: [
              // Group icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: data.accent.withValues(alpha: 0.15),
                  border: Border.all(
                    color: data.accent.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(data.emoji, style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 8),
              // Members badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_alt_rounded,
                      size: 12,
                      color: kTextSecondary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${data.memberCount}',
                      style: TextStyle(
                        color: kTextSecondary.withValues(alpha: 0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Menu dots
              Icon(
                Icons.more_horiz_rounded,
                color: kTextSecondary.withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ),
          const Spacer(),

          // Wallet name
          Text(
            data.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),

          // Balance
          Text(
            data.balance,
            style: TextStyle(
              color: kTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),

          // "Đã chi" + progress bar
          Row(
            children: [
              Expanded(
                child: Text(
                  'Đã chi ${data.spent}',
                  style: TextStyle(
                    color: kTextSecondary.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${data.percentage}%',
                style: TextStyle(
                  color: kTextSecondary.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: data.percentage / 100,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(data.accent),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mock data ──────────────────────────────────────────
class _MockWallet {
  final String name;
  final String emoji;
  final String balance;
  final String spent;
  final int memberCount;
  final int percentage;
  final Color accent;

  const _MockWallet({
    required this.name,
    required this.emoji,
    required this.balance,
    required this.spent,
    required this.memberCount,
    required this.percentage,
    required this.accent,
  });
}

const _mockWallets = <_MockWallet>[
  _MockWallet(
    name: 'Du lịch Đà Nẵng',
    emoji: '✈️',
    balance: '8.540.000 đ',
    spent: '6.460.000 đ',
    memberCount: 5,
    percentage: 76,
    accent: kCyan,
  ),
  _MockWallet(
    name: 'Thuê nhà 4A',
    emoji: '🏠',
    balance: '12.300.000 đ',
    spent: '7.700.000 đ',
    memberCount: 4,
    percentage: 63,
    accent: kPurple,
  ),
  _MockWallet(
    name: 'Sinh nhật Minh',
    emoji: '🎁',
    balance: '1.250.000 đ',
    spent: '750.000 đ',
    memberCount: 3,
    percentage: 60,
    accent: kRose,
  ),
];
