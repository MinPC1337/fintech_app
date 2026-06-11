import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../injection_container.dart';
import '../../../domain/usecases/get_primary_wallet_stream_usecase.dart';
import '../../../domain/usecases/get_transactions_stream_usecase.dart';

class TotalAssetsCard extends StatefulWidget {
  final String userId;
  final bool isActive;

  const TotalAssetsCard({super.key, required this.userId, this.isActive = true});

  @override
  State<TotalAssetsCard> createState() => _TotalAssetsCardState();
}

class _TotalAssetsCardState extends State<TotalAssetsCard> {
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  late final GetPrimaryWalletStreamUseCase getPrimaryWalletStreamUseCase;
  late final GetTransactionsStreamUseCase getTransactionsStreamUseCase;
  bool _isBalanceHidden = false;
  bool _showChartData = false;

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
      setState(() {
        _showChartData = false;
      });
    }
  }

  void _triggerAnimation() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _showChartData = true;
        });
      }
    });
  }

  Widget _buildCardChip() {
    return Container(
      width: 38,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFD700),
            Color(0xFFD4AF37),
            Color(0xFFB8860B),
            Color(0xFFFFD700),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Các đường viền chip
          Center(
            child: Container(
              width: 16,
              height: 20,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.3),
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Container(
              height: 0.5,
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Container(
              height: 0.5,
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: 12,
            child: Container(
              width: 0.5,
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            right: 12,
            child: Container(
              width: 0.5,
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
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
            Color(0xFF1E284A), // Đậm hơn một chút
            Color(0xFF11182B),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: kCyan.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: StreamBuilder(
        stream: getPrimaryWalletStreamUseCase.call(widget.userId),
        builder: (context, walletSnapshot) {
          double currentBalance = 0.0;
          String? primaryWalletId;

          if (walletSnapshot.hasData) {
            walletSnapshot.data!.fold((failure) => null, (wallet) {
              currentBalance = wallet?.balance ?? 0.0;
              primaryWalletId = wallet?.id;
            });
          }

          return StreamBuilder<List<dynamic>>(
            stream: getTransactionsStreamUseCase.call(widget.userId),
            builder: (context, txSnapshot) {
              final allTransactions = txSnapshot.data ?? [];

              // Lọc các giao dịch liên quan đến ví chính
              final relevantTx = allTransactions
                  .where(
                    (tx) =>
                        tx.fromWalletId == primaryWalletId ||
                        tx.toWalletId == primaryWalletId,
                  )
                  .toList();

              // Sắp xếp tăng dần theo thời gian (cũ -> mới)
              relevantTx.sort((a, b) => a.timestamp.compareTo(b.timestamp));

              // Tính toán số dư quá khứ để vẽ biểu đồ và so sánh (3 tháng gần nhất)
              final now = DateTime.now();
              DateTime getPastMonth(int monthsAgo) {
                int year = now.year;
                int month = now.month - monthsAgo;
                while (month <= 0) {
                  year--;
                  month += 12;
                }
                return DateTime(year, month, now.day);
              }

              final oneMonthAgo = getPastMonth(1);
              final twoMonthsAgo = getPastMonth(2);
              final threeMonthsAgo = getPastMonth(3);

              double bal1 = currentBalance;
              double bal2 = currentBalance;
              double bal3 = currentBalance;

              for (var tx in relevantTx.reversed) {
                double change = 0;
                if (tx.fromWalletId == primaryWalletId) {
                  change = tx.amount;
                } else if (tx.toWalletId == primaryWalletId) {
                  change = -tx.amount;
                }

                if (tx.timestamp.isAfter(oneMonthAgo)) {
                  bal1 += change;
                }
                if (tx.timestamp.isAfter(twoMonthsAgo)) {
                  bal2 += change;
                }
                if (tx.timestamp.isAfter(threeMonthsAgo)) {
                  bal3 += change;
                }
              }

              // Tính tỷ lệ phần trăm thay đổi so với 1 tháng trước
              double growth = currentBalance - bal1;
              double percentChange = 0.0;
              if (bal1 > 0) {
                percentChange = (growth / bal1) * 100;
              } else if (growth > 0) {
                percentChange = 100.0;
              }

              double maxBalance = [
                bal3,
                bal2,
                bal1,
                currentBalance,
              ].reduce((a, b) => a > b ? a : b);
              if (maxBalance <= 0) maxBalance = 1;
              double chartMaxY = maxBalance * 1.3;

              List<FlSpot> targetSpots = [
                FlSpot(0, bal3),
                FlSpot(1, bal2),
                FlSpot(2, bal1),
                FlSpot(3, currentBalance),
              ];

              return Stack(
                children: [
                  // Biểu đồ so sánh
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 12,
                    height: 90,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0,
                        end: _showChartData ? 3.0 : 0.0,
                      ),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeInOut,
                      builder: (context, animatedX, child) {
                        List<FlSpot> currentSpots = [];
                        if (animatedX == 0) {
                          currentSpots = [targetSpots.first];
                        } else {
                          for (int i = 0; i < targetSpots.length - 1; i++) {
                            FlSpot p1 = targetSpots[i];
                            FlSpot p2 = targetSpots[i + 1];
                            if (animatedX >= p2.x) {
                              currentSpots.add(p1);
                            } else if (animatedX >= p1.x && animatedX < p2.x) {
                              currentSpots.add(p1);
                              double t = (animatedX - p1.x) / (p2.x - p1.x);
                              double interpolatedY = p1.y + (p2.y - p1.y) * t;
                              currentSpots.add(FlSpot(animatedX, interpolatedY));
                              break;
                            }
                          }
                          if (animatedX >= targetSpots.last.x) {
                            currentSpots.add(targetSpots.last);
                          }
                        }

                        return _buildFintechLineChart(
                          currentSpots,
                          chartMaxY,
                          [
                            'Th${threeMonthsAgo.month}',
                            'Th${twoMonthsAgo.month}',
                            'Th${oneMonthAgo.month}',
                            '${now.day}/${now.month}',
                          ],
                        );
                      },
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header (Tổng tài sản + Chip)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Tổng tài sản',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
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
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                            _buildCardChip(),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Số tài khoản
                        Text(
                          widget.userId.hashCode
                              .abs()
                              .toString()
                              .padLeft(10, '0')
                              .substring(0, 10),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Số dư chính
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
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
                                fontSize: 32,
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
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Biến động
                        Row(
                          children: [
                            Icon(
                              percentChange >= 0
                                  ? Icons.arrow_drop_up
                                  : Icons.arrow_drop_down,
                              color: percentChange >= 0 ? kEmerald : kRose,
                              size: 24,
                            ),
                            Text(
                              '${percentChange.abs().toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: percentChange >= 0 ? kEmerald : kRose,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'so với tháng trước',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        // Khoảng trống để chứa biểu đồ
                        const SizedBox(height: 90),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFintechLineChart(
    List<FlSpot> spots,
    double maxY,
    List<String> labels,
  ) {
    return LineChart(
      duration: Duration.zero,
      LineChartData(
        minX: 0,
        maxX: 3,
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4 > 0 ? maxY / 4 : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withValues(alpha: 0.05),
              strokeWidth: 1,
              dashArray: [4, 4],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index < 0 || index >= labels.length) {
                  return const SizedBox.shrink();
                }
                final isCurrent = index == labels.length - 1;
                return SideTitleWidget(
                  key: ValueKey('line_label_$value'),
                  axisSide: meta.axisSide,
                  space: 12,
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: isCurrent
                          ? kCyan
                          : Colors.white.withValues(alpha: 0.5),
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            gradient: const LinearGradient(
              colors: [kCyan, kEmerald],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final isLast = index == spots.length - 1 && spot.x == 3;
                return FlDotCirclePainter(
                  radius: isLast ? 5 : 3,
                  color: isLast ? Colors.white : kCyan,
                  strokeWidth: isLast ? 3 : 2,
                  strokeColor: isLast ? kEmerald : Colors.white,
                );
              },
              checkToShowDot: (spot, barData) {
                // Show dots only on integers
                return spot.x == spot.x.roundToDouble();
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  kEmerald.withValues(alpha: 0.3),
                  kCyan.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) =>
                const Color(0xFF1E284A).withValues(alpha: 0.9),
            tooltipRoundedRadius: 8,
            tooltipBorder: const BorderSide(color: kCyan, width: 1),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                return LineTooltipItem(
                  '${currencyFormatter.format(touchedSpot.y).replaceAll('đ', '').trim()} đ',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
