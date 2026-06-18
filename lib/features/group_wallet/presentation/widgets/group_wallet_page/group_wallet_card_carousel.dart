import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../main/domain/entities/wallet_entity.dart';

/// Section "Ví nhóm của bạn" — horizontal scrollable wallet cards.
/// Now uses real WalletEntity data from Cubit.
class GroupWalletCardCarousel extends StatelessWidget {
  const GroupWalletCardCarousel({
    super.key,
    required this.wallets,
    required this.memberNames,
    required this.memberAvatars,
    required this.onTapWallet,
  });

  final List<WalletEntity> wallets;
  final Map<String, String> memberNames;
  final Map<String, String> memberAvatars;
  final void Function(WalletEntity wallet) onTapWallet;

  @override
  Widget build(BuildContext context) {
    if (wallets.isEmpty) {
      return const SizedBox.shrink();
    }

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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: kCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${wallets.length} ví',
                style: TextStyle(
                  color: kCyan,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
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
            itemCount: wallets.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final wallet = wallets[index];
              return GestureDetector(
                onTap: () => onTapWallet(wallet),
                child: _WalletMiniCard(
                  wallet: wallet,
                  memberNames: memberNames,
                  memberAvatars: memberAvatars,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WalletMiniCard extends StatelessWidget {
  const _WalletMiniCard({
    required this.wallet,
    required this.memberNames,
    required this.memberAvatars,
  });

  final WalletEntity wallet;
  final Map<String, String> memberNames;
  final Map<String, String> memberAvatars;

  Color get _accent {
    if (wallet.accentArgb != null) {
      return Color(wallet.accentArgb!);
    }
    // Fallback colors based on index hash
    const fallbackColors = [kCyan, kPurple, kRose, kEmerald, kElectricBlue];
    return fallbackColors[wallet.id.hashCode.abs() % fallbackColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    final memberCount = wallet.members.length;
    final balance = _formatCurrency(wallet.balance);

    return Container(
      width: 170,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: 0.18), const Color(0xFF11182B)],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.1),
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
                  color: accent.withValues(alpha: 0.15),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: wallet.imageUrl != null && wallet.imageUrl!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            wallet.imageUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      : wallet.emoji != null && wallet.emoji!.isNotEmpty
                      ? Text(
                          wallet.emoji!,
                          style: const TextStyle(fontSize: 16),
                        )
                      : Icon(Icons.group_rounded, color: accent, size: 18),
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
                      '$memberCount',
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
          Row(
            children: [
              if (wallet.status == 'closed') ...[
                const Icon(Icons.lock_rounded, size: 14, color: kTextSecondary),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  wallet.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Balance
          Text(
            balance,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Member avatars row
          SizedBox(
            height: 24,
            child: _MemberAvatarRow(
              memberIds: wallet.members,
              memberNames: memberNames,
              memberAvatars: memberAvatars,
              accent: accent,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final intAmount = amount.toInt();
    final str = intAmount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    buffer.write(' đ');
    return buffer.toString();
  }
}

class _MemberAvatarRow extends StatelessWidget {
  const _MemberAvatarRow({
    required this.memberIds,
    required this.memberNames,
    required this.memberAvatars,
    required this.accent,
  });

  final List<String> memberIds;
  final Map<String, String> memberNames;
  final Map<String, String> memberAvatars;
  final Color accent;

  static const _avatarColors = [kCyan, kPurple, kRose, kEmerald, kElectricBlue];
  static const _maxVisible = 4;

  @override
  Widget build(BuildContext context) {
    final visible = memberIds.take(_maxVisible).toList();
    final extra = memberIds.length - _maxVisible;

    return Row(
      children: [
        for (var i = 0; i < visible.length; i++)
          Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 0),
            child: Transform.translate(
              offset: Offset(-i * 6.0, 0),
              child: _MiniAvatar(
                initial: _getInitial(visible[i]),
                avatarUrl: memberAvatars[visible[i]],
                color: _avatarColors[i % _avatarColors.length],
              ),
            ),
          ),
        if (extra > 0)
          Transform.translate(
            offset: Offset(-visible.length * 6.0, 0),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Center(
                child: Text(
                  '+$extra',
                  style: TextStyle(
                    color: kTextSecondary.withValues(alpha: 0.8),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _getInitial(String uid) {
    final name = memberNames[uid];
    if (name != null && name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return '?';
  }
}

class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar({
    required this.initial,
    required this.color,
    this.avatarUrl,
  });

  final String initial;
  final Color color;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        image: (avatarUrl != null && avatarUrl!.isNotEmpty)
            ? DecorationImage(
                image: NetworkImage(avatarUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: (avatarUrl != null && avatarUrl!.isNotEmpty)
          ? null
          : Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ),
    );
  }
}
