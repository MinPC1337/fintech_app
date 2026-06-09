import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../injection_container.dart';
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
              Text(
                'Xem tất cả',
                style: TextStyle(
                  color: kCyan.withValues(alpha: 0.8),
                  fontSize: 12,
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
                children: wallets.map((wallet) => _buildGroupWalletItem(wallet)).toList(),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.group_rounded, color: color, size: 24),
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
                const SizedBox(height: 4),
                Text(
                  '${wallet.members.length} thành viên',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Số dư',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${currencyFormatter.format(wallet.balance).replaceAll('đ', '').trim()} đ',
                style: const TextStyle(
                  color: Colors.white,
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
}
