import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../injection_container.dart';
import '../../../domain/usecases/get_primary_wallet_stream_usecase.dart';
import '../../../domain/usecases/get_transactions_stream_usecase.dart';

class TotalAssetsCard extends StatefulWidget {
  final String userId;

  const TotalAssetsCard({super.key, required this.userId});

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
                border: Border.all(color: Colors.black.withValues(alpha: 0.3), width: 0.5),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Positioned(top: 8, left: 0, right: 0, child: Container(height: 0.5, color: Colors.black.withValues(alpha: 0.3))),
          Positioned(bottom: 8, left: 0, right: 0, child: Container(height: 0.5, color: Colors.black.withValues(alpha: 0.3))),
          Positioned(top: 0, bottom: 0, left: 12, child: Container(width: 0.5, color: Colors.black.withValues(alpha: 0.3))),
          Positioned(top: 0, bottom: 0, right: 12, child: Container(width: 0.5, color: Colors.black.withValues(alpha: 0.3))),
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
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
            walletSnapshot.data!.fold(
              (failure) => null,
              (wallet) {
                currentBalance = wallet?.balance ?? 0.0;
                primaryWalletId = wallet?.id;
              },
            );
          }

          return StreamBuilder<List<dynamic>>(
            stream: getTransactionsStreamUseCase.call(widget.userId),
            builder: (context, txSnapshot) {
              final allTransactions = txSnapshot.data ?? [];
              
              // Lọc các giao dịch liên quan đến ví chính
              final relevantTx = allTransactions.where((tx) => 
                tx.fromWalletId == primaryWalletId || tx.toWalletId == primaryWalletId
              ).toList();

              // Sắp xếp tăng dần theo thời gian (cũ -> mới)
              relevantTx.sort((a, b) => a.timestamp.compareTo(b.timestamp));

              // Tính toán số dư quá khứ để vẽ biểu đồ và so sánh
              final now = DateTime.now();
              final thirtyDaysAgo = now.subtract(const Duration(days: 30));
              
              double balance30DaysAgo = currentBalance;
              // Ngược về quá khứ: 
              // Nếu là chi tiêu (fromWallet) -> quá khứ chưa chi -> cộng lại
              // Nếu là thu nhập (toWallet) -> quá khứ chưa thu -> trừ đi
              for (var tx in relevantTx.reversed) {
                if (tx.timestamp.isAfter(thirtyDaysAgo)) {
                  if (tx.fromWalletId == primaryWalletId) {
                    balance30DaysAgo += tx.amount; // Hoàn tác chi
                  } else if (tx.toWalletId == primaryWalletId) {
                    balance30DaysAgo -= tx.amount; // Hoàn tác thu
                  }
                }
              }

              // Tính tỷ lệ phần trăm thay đổi
              double growth = currentBalance - balance30DaysAgo;
              double percentChange = 0.0;
              if (balance30DaysAgo > 0) {
                percentChange = (growth / balance30DaysAgo) * 100;
              } else if (growth > 0) {
                percentChange = 100.0;
              }

              // Tạo dữ liệu cho biểu đồ 30 ngày (Lấy 15 điểm cho mượt)
              List<FlSpot> spots = [];
              double maxBalance = currentBalance;
              double minBalance = currentBalance;
              
              if (relevantTx.isNotEmpty) {
                for (int i = 0; i <= 30; i += 2) { // 15 points
                  DateTime targetDate = thirtyDaysAgo.add(Duration(days: i));
                  
                  // Tính số dư tại targetDate
                  // Bắt đầu từ balance30DaysAgo, duyệt từ cũ -> mới
                  double balAtDate = balance30DaysAgo;
                  for (var tx in relevantTx) {
                    if (tx.timestamp.isAfter(thirtyDaysAgo) && 
                        tx.timestamp.isBefore(targetDate)) {
                      if (tx.toWalletId == primaryWalletId) {
                        balAtDate += tx.amount;
                      } else if (tx.fromWalletId == primaryWalletId) {
                        balAtDate -= tx.amount;
                      }
                    }
                  }
                  
                  if (balAtDate > maxBalance) maxBalance = balAtDate;
                  if (balAtDate < minBalance) minBalance = balAtDate;
                  
                  spots.add(FlSpot((i / 2).toDouble(), balAtDate));
                }
              }

              // Fallback nếu không có giao dịch
              if (spots.isEmpty || spots.length < 2) {
                spots = const [
                  FlSpot(0, 0),
                  FlSpot(1, 0),
                  FlSpot(2, 0),
                ];
                maxBalance = 1;
                minBalance = 0;
              }

              // Để biểu đồ không chạm sát đáy/đỉnh
              double chartMaxY = maxBalance + (maxBalance - minBalance) * 0.2;
              double chartMinY = minBalance - (maxBalance - minBalance) * 0.2;
              if (chartMaxY == chartMinY) {
                chartMaxY += 1000000;
                chartMinY -= 1000000;
              }
              if (chartMinY < 0) chartMinY = 0;

              return Stack(
                children: [
                  // Background Chart
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 100, 
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      child: _buildBackgroundChart(spots, chartMinY, chartMaxY),
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(24.0),
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
                        
                        const SizedBox(height: 16),
                        
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
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'đ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Biến động
                        Row(
                          children: [
                            Icon(
                              percentChange >= 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down, 
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
                        const SizedBox(height: 60), 
                      ],
                    ),
                  ),
                  
                  // Tooltip/Data point thật ở cuối biểu đồ
                  Positioned(
                    right: 40,
                    bottom: 60,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _isBalanceHidden
                                    ? '***'
                                    : '${currencyFormatter.format(currentBalance).replaceAll('đ', '').trim()} đ',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                DateFormat('dd/MM').format(now),
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 9),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(color: kCyan, blurRadius: 10, spreadRadius: 2),
                            ],
                            border: Border.all(color: kCyan, width: 2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
          );
        },
      ),
    );
  }

  Widget _buildBackgroundChart(List<FlSpot> spots, double minY, double maxY) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF4A65FF),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4A65FF).withValues(alpha: 0.3),
                  const Color(0xFF4A65FF).withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        minX: spots.first.x,
        maxX: spots.last.x,
        minY: minY,
        maxY: maxY,
      ),
    );
  }
}
