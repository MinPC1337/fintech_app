import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fintech_app/core/theme/app_colors.dart';
import 'package:fintech_app/features/main/domain/entities/wallet_entity.dart';

class WalletCard extends StatefulWidget {
  final WalletEntity wallet;
  final bool isOwner;
  final double balance;

  const WalletCard({
    super.key,
    required this.wallet,
    required this.isOwner,
    required this.balance,
  });

  @override
  State<WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<WalletCard> {
  bool _isBalanceHidden = false;
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  Widget _buildCardChip() {
    return Container(
      width: 42,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE5C07B),
            Color(0xFFF3E5AB),
            Color(0xFFD4AF37),
            Color(0xFFB8860B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 3,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 18,
              height: 22,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.2),
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Container(
              height: 0.5,
              color: Colors.black.withValues(alpha: 0.2),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Container(
              height: 0.5,
              color: Colors.black.withValues(alpha: 0.2),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: 14,
            child: Container(
              width: 0.5,
              color: Colors.black.withValues(alpha: 0.2),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            right: 14,
            child: Container(
              width: 0.5,
              color: Colors.black.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAccountNumber(String acc) {
    if (acc.length == 10) {
      return '${acc.substring(0, 4)}${acc.substring(4, 7)}${acc.substring(7)}';
    }
    return acc;
  }

  @override
  Widget build(BuildContext context) {
    String rawAcc = widget.wallet.id.hashCode
        .abs()
        .toString()
        .padLeft(10, '0')
        .substring(0, 10);
    String formattedAcc = _formatAccountNumber(rawAcc);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A), // Deep vibrant blue
            Color(0xFF0F172A), // Dark slate
            Color(0xFF020617), // Very dark slate
          ],
          stops: [0.0, 0.6, 1.0],
        ),
        border: Border.all(color: kCyan.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: kCyan.withValues(alpha: 0.05),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background Elements (Holographic / Glassmorphism)
            Positioned(
              right: -60,
              top: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [kCyan.withValues(alpha: 0.15), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      kEmerald.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: Icon(
                Icons.language_rounded,
                size: 150,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header (Logo + Contactless)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.group_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.wallet.name.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.contactless_rounded,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 24,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Chip
                  _buildCardChip(),

                  const SizedBox(height: 20),

                  // Số tài khoản
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formattedAcc,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 22,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                          letterSpacing: 3.0,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              offset: const Offset(0, 2),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      if (widget.wallet.status == 'closed')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: kRose.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: kRose.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Text(
                            'ĐÃ ĐÓNG',
                            style: TextStyle(
                              color: kRose,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Footer: Tên + Balance
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SỐ DƯ VÍ NHÓM',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 10,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _isBalanceHidden
                                    ? '******'
                                    : currencyFormatter
                                          .format(widget.balance)
                                          .replaceAll('đ', '')
                                          .trim(),
                                 style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'đ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Nút ẩn hiện + Logo
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isBalanceHidden = !_isBalanceHidden;
                              });
                            },
                            child: Icon(
                              _isBalanceHidden
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white.withValues(alpha: 0.5),
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Premium Logo
                          Text(
                            widget.isOwner ? 'CHỦ NHÓM' : 'THÀNH VIÊN',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
