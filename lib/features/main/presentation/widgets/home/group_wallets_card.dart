import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../injection_container.dart';
import '../../../../auth/data/models/user_model.dart';
import '../../pages/main_page.dart';
import '../../../../group_wallet/domain/usecases/watch_group_wallets_usecase.dart';
import '../../../domain/entities/wallet_entity.dart';

class GroupWalletsCard extends StatefulWidget {
  final String userId;

  const GroupWalletsCard({super.key, required this.userId});

  @override
  State<GroupWalletsCard> createState() => _GroupWalletsCardState();
}

class _GroupWalletsCardState extends State<GroupWalletsCard> {
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  late final WatchGroupWalletsUseCase watchGroupWalletsUseCase;

  @override
  void initState() {
    super.initState();
    watchGroupWalletsUseCase = sl<WatchGroupWalletsUseCase>();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kThemeSurfaceSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ví nhóm',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () {
                  MainPage.of(context)?.changeTab(2);
                },
                child: Text(
                  'Xem tất cả',
                  style: TextStyle(
                    color: kCyan.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<WalletEntity>>(
            stream: watchGroupWalletsUseCase.call(widget.userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: kCyan));
              }

              final wallets = snapshot.data ?? [];
              if (wallets.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(Icons.group_off_rounded, color: Colors.white.withValues(alpha: 0.2), size: 48),
                        const SizedBox(height: 8),
                        Text(
                          'Chưa tham gia ví nhóm nào',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: wallets.take(3).map((wallet) => _buildGroupWalletItem(wallet)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGroupWalletItem(WalletEntity wallet) {
    final color = wallet.accentArgb != null ? Color(wallet.accentArgb!) : kPurple;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: wallet.imageUrl != null && wallet.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.network(
                      wallet.imageUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : wallet.emoji != null && wallet.emoji!.isNotEmpty
                    ? Center(
                        child: Text(
                          wallet.emoji!,
                          style: const TextStyle(fontSize: 20),
                        ),
                      )
                    : Icon(Icons.group_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wallet.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                _buildMemberAvatars(wallet.members, color),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Số dư',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${currencyFormatter.format(wallet.balance).replaceAll('đ', '').trim()} đ',
                style: TextStyle(
                  color: color.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberAvatars(List<String> members, Color accentColor) {
    if (members.isEmpty) return const SizedBox();
    
    const double avatarSize = 22.0;
    const double overlap = 8.0;
    const int maxDisplay = 5;
    final int displayCount = members.length > maxDisplay ? maxDisplay - 1 : members.length;
    final int remainingCount = members.length - displayCount;

    return SizedBox(
      height: avatarSize,
      width: (displayCount + (remainingCount > 0 ? 1 : 0)) * (avatarSize - overlap) + overlap,
      child: Stack(
        children: List.generate(displayCount + (remainingCount > 0 ? 1 : 0), (index) {
          final isLast = remainingCount > 0 && index == displayCount;
          
          if (isLast) {
            return Positioned(
              left: index * (avatarSize - overlap),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: kThemeSurfaceSecondary, width: 2.0),
                ),
                child: CircleAvatar(
                  radius: (avatarSize - 4) / 2,
                  backgroundColor: Colors.grey[800],
                  child: Text('+$remainingCount', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            );
          }

          final memberId = members[index];
          return Positioned(
            left: index * (avatarSize - overlap),
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('users').doc(memberId).snapshots(),
              builder: (context, snapshot) {
                final user = snapshot.hasData && snapshot.data!.exists && snapshot.data!.data() != null
                    ? UserModel.fromJson(snapshot.data!.data()!)
                    : null;
                
                final hasAvatar = user != null && user.avatarUrl.isNotEmpty;
                
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: kThemeSurfaceSecondary, width: 2.0),
                  ),
                  child: CircleAvatar(
                    radius: (avatarSize - 4) / 2,
                    backgroundColor: _getAvatarColor(memberId),
                    backgroundImage: hasAvatar ? NetworkImage(user.avatarUrl) : null,
                    child: hasAvatar ? null : const Icon(Icons.person, size: 12, color: Colors.white),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }

  Color _getAvatarColor(String id) {
    final colors = [
      const Color(0xFFE57373), // red
      const Color(0xFF81C784), // green
      const Color(0xFF64B5F6), // blue
      const Color(0xFFFFB74D), // orange
      const Color(0xFFBA68C8), // purple
      const Color(0xFF4DB6AC), // teal
      const Color(0xFFF06292), // pink
    ];
    final index = id.hashCode.abs() % colors.length;
    return colors[index];
  }
}
