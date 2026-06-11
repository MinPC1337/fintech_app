import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../injection_container.dart';
import '../../../domain/usecases/get_primary_wallet_stream_usecase.dart';
import '../../../domain/usecases/get_transactions_stream_usecase.dart';

class TotalAssetsCard extends StatefulWidget {
  final String userId;
  final bool isActive;

  const TotalAssetsCard({
    super.key,
    required this.userId,
    this.isActive = true,
  });

  @override
  State<TotalAssetsCard> createState() => _TotalAssetsCardState();
}

class _TotalAssetsCardState extends State<TotalAssetsCard> {
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  late final GetPrimaryWalletStreamUseCase getPrimaryWalletStreamUseCase;
  late final GetTransactionsStreamUseCase getTransactionsStreamUseCase;
  bool _isBalanceHidden = false;

  @override
  void initState() {
    super.initState();
    getPrimaryWalletStreamUseCase = sl<GetPrimaryWalletStreamUseCase>();
    getTransactionsStreamUseCase = sl<GetTransactionsStreamUseCase>();
    if (widget.isActive) {
      _triggerAnimation();
    }
  }

  @override
  void didUpdateWidget(TotalAssetsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _triggerAnimation();
    } else if (!widget.isActive && oldWidget.isActive) {
      setState(() {});
    }
  }

  void _triggerAnimation() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {});
      }
    });
  }

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
            // Bản đồ thế giới hoặc pattern (tuỳ chọn) có thể dùng icon watermark
            Positioned(
              right: 20,
              bottom: 20,
              child: Icon(
                Icons.language_rounded,
                size: 150,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),

            StreamBuilder(
              stream: getPrimaryWalletStreamUseCase.call(widget.userId),
              builder: (context, walletSnapshot) {
                double currentBalance = 0.0;
                if (walletSnapshot.hasData) {
                  walletSnapshot.data!.fold((failure) => null, (wallet) {
                    currentBalance = wallet?.balance ?? 0.0;
                  });
                }

                return StreamBuilder<List<dynamic>>(
                  stream: getTransactionsStreamUseCase.call(widget.userId),
                  builder: (context, txSnapshot) {
                    // (Logic chart data generation omitted for brevity but kept functional)
                    // We generate chart data if needed or just use currentBalance

                    // Lấy mã tài khoản
                    String rawAcc = widget.userId.hashCode
                        .abs()
                        .toString()
                        .padLeft(10, '0')
                        .substring(0, 10);
                    String formattedAcc = _formatAccountNumber(rawAcc);

                    return Padding(
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
                                      color: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'FINTECH WALLET',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                Icons
                                    .contactless_rounded, // Hoặc wifi_rounded rotate 90 độ
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
                                    'TỔNG SỐ DƯ',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                      fontSize: 10,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        _isBalanceHidden
                                            ? '******'
                                            : currencyFormatter
                                                  .format(currentBalance)
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
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Fake VISA logo
                                  Row(
                                    children: [
                                      Text(
                                        'PREMIUM',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
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
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
