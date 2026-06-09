import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../injection_container.dart';
import '../../../domain/usecases/get_primary_wallet_stream_usecase.dart';
import '../../../domain/usecases/get_transactions_stream_usecase.dart';

class IncomeVsExpenseCard extends StatefulWidget {
  final String userId;
  final DateTime month;

  const IncomeVsExpenseCard({super.key, required this.userId, required this.month});

  @override
  State<IncomeVsExpenseCard> createState() => _IncomeVsExpenseCardState();
}

class _IncomeVsExpenseCardState extends State<IncomeVsExpenseCard> {
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  late final GetPrimaryWalletStreamUseCase getPrimaryWalletStreamUseCase;
  late final GetTransactionsStreamUseCase getTransactionsStreamUseCase;

  @override
  void initState() {
    super.initState();
    getPrimaryWalletStreamUseCase = sl<GetPrimaryWalletStreamUseCase>();
    getTransactionsStreamUseCase = sl<GetTransactionsStreamUseCase>();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kThemeSurfaceSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: StreamBuilder(
        stream: getPrimaryWalletStreamUseCase.call(widget.userId),
        builder: (context, walletSnap) {
          String? primaryWalletId;
          if (walletSnap.hasData) {
            walletSnap.data!.fold((f) => null, (w) {
              primaryWalletId = w?.id;
            });
          }

          return StreamBuilder<List<dynamic>>(
            stream: getTransactionsStreamUseCase.call(widget.userId),
            builder: (context, snapshot) {
              double currentMonthIncome = 0.0;
              double currentMonthExpense = 0.0;
              
              List<FlSpot> incomeSpots = [];
              List<FlSpot> expenseSpots = [];
              double maxY = 1.0;
              int daysInMonth = 30;

              if (snapshot.hasData && primaryWalletId != null) {
                final allTransactions = snapshot.data ?? [];
                final targetMonth = widget.month;
                
                daysInMonth = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;

                // Tính toán tháng hiện tại
                final currentMonthTxs = allTransactions.where((tx) {
                  return tx.timestamp.month == targetMonth.month &&
                      tx.timestamp.year == targetMonth.year;
                });

                currentMonthIncome = currentMonthTxs
                    .where((tx) => tx.toWalletId == primaryWalletId)
                    .fold(0.0, (sum, tx) => sum + tx.amount);

                currentMonthExpense = currentMonthTxs
                    .where((tx) => tx.fromWalletId == primaryWalletId)
                    .fold(0.0, (sum, tx) => sum + tx.amount);

                // Gom nhóm theo ngày
                Map<int, double> dailyIncome = {};
                Map<int, double> dailyExpense = {};

                for (var tx in currentMonthTxs) {
                  int day = tx.timestamp.day;
                  if (tx.toWalletId == primaryWalletId) {
                    dailyIncome[day] = (dailyIncome[day] ?? 0.0) + tx.amount;
                  } else if (tx.fromWalletId == primaryWalletId) {
                    dailyExpense[day] = (dailyExpense[day] ?? 0.0) + tx.amount;
                  }
                }

                double maxVal = 0.0;
                
                // Mặc định biểu đồ bắt đầu từ ngày 1 tới daysInMonth
                // Để biểu đồ mượt, ta có thể tích lũy hoặc vẽ theo từng ngày
                // Ở đây ta vẽ tổng thu/chi theo từng ngày
                for (int d = 1; d <= daysInMonth; d++) {
                  double inc = dailyIncome[d] ?? 0.0;
                  double exp = dailyExpense[d] ?? 0.0;

                  if (inc > maxVal) maxVal = inc;
                  if (exp > maxVal) maxVal = exp;

                  incomeSpots.add(FlSpot(d.toDouble(), inc));
                  expenseSpots.add(FlSpot(d.toDouble(), exp));
                }
                
                maxY = maxVal > 0 ? maxVal * 1.2 : 1.0;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thu nhập / Chi tiêu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thu nhập',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '+${currencyFormatter.format(currentMonthIncome).replaceAll('đ', '').trim()} đ',
                              style: const TextStyle(
                                color: kEmerald,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chi tiêu',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '-${currencyFormatter.format(currentMonthExpense).replaceAll('đ', '').trim()} đ',
                              style: const TextStyle(
                                color: kRose,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Biểu đồ Đường
                  SizedBox(
                    height: 110,
                    child: incomeSpots.isEmpty 
                    ? const Center(child: Text("Chưa có dữ liệu", style: TextStyle(color: Colors.white54, fontSize: 11)))
                    : LineChart(
                      LineChartData(
                        minX: 1,
                        maxX: daysInMonth.toDouble(),
                        minY: 0,
                        maxY: maxY,
                        lineTouchData: const LineTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 20,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                const style = TextStyle(
                                  color: Colors.white54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                );
                                // Chỉ hiển thị vài mốc ngày để không bị rối
                                int day = value.toInt();
                                if (day == 1 || day == 10 || day == 20 || day == daysInMonth) {
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    child: Text(day.toString(), style: style),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: maxY / 3 > 0 ? maxY / 3 : 1,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.white.withValues(alpha: 0.1),
                              strokeWidth: 1,
                              dashArray: [4, 4],
                            );
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: incomeSpots,
                            isCurved: true,
                            color: kEmerald,
                            barWidth: 2,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: kEmerald.withValues(alpha: 0.15),
                            ),
                          ),
                          LineChartBarData(
                            spots: expenseSpots,
                            isCurved: true,
                            color: kRose,
                            barWidth: 2,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: kRose.withValues(alpha: 0.15),
                            ),
                          ),
                        ],
                      ),
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
}
