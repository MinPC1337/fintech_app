import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/get_primary_wallet_stream_usecase.dart';
import 'momo_deposit_page.dart';
import '../../data/datasources/notification_remote_data_source.dart';
import 'transfer_page.dart';
import 'send_to_user_page.dart';
import 'notifications_page.dart';
import 'package:intl/intl.dart';
import '../../domain/usecases/get_transactions_stream_usecase.dart';
import 'transaction_history_page.dart';
import 'transaction_success_page.dart';
import '../../../auth/presentation/pages/profile_page.dart';
import '../../../auth/domain/entities/user.dart' as auth_entity;
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  late final GetPrimaryWalletStreamUseCase getPrimaryWalletStreamUseCase;
  late final GetTransactionsStreamUseCase getTransactionsStreamUseCase;
  bool _isBalanceHidden = false; // Trạng thái ẩn/hiện số dư
  DateTime _selectedMonth = DateTime.now(); // Tháng đang chọn để xem báo cáo

  @override
  void initState() {
    super.initState();
    getPrimaryWalletStreamUseCase = sl<GetPrimaryWalletStreamUseCase>();
    getTransactionsStreamUseCase = sl<GetTransactionsStreamUseCase>();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        auth_entity.User? currentUser;
        if (state is AuthSuccess) {
          currentUser = state.user;
        }

        if (currentUser == null) {
          return const Scaffold(
            body: Center(child: Text("Cần đăng nhập trước")),
          );
        }

        return Scaffold(
          backgroundColor: kBgColor,
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Khối Tiêu đề & Cá nhân hóa
                  _buildHeader(context, currentUser),
                  const SizedBox(height: 32),

                  // 2. Thẻ Số dư (Hero Section)
                  _buildBalanceHero(currentUser),
                  const SizedBox(height: 32),

                  // Tiêu đề Thao tác nhanh
                  const Text(
                    'THAO TÁC NHANH',
                    style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 3. Khối Thao tác nhanh (Quick Actions Row)
                  _buildQuickActions(context),
                  const SizedBox(height: 40),

                  const Text(
                    'BÁO CÁO TỔNG QUAN',
                    style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Khối Thống kê tháng
                  _buildMonthlySummary(currentUser),
                  const SizedBox(height: 32),

                  // 5. Khối Lịch sử Giao dịch
                  _buildTimelineSection(currentUser),

                  // Khoảng trống dưới cùng để không bị che bởi thanh lơ lửng Navigation
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return 'CHÀO BUỔI SÁNG';
    } else if (hour >= 11 && hour < 13) {
      return 'CHÀO BUỔI TRƯA';
    } else if (hour >= 13 && hour < 18) {
      return 'CHÀO BUỔI CHIỀU';
    } else {
      return 'CHÀO BUỔI TỐI';
    }
  }

  Widget _buildHeader(BuildContext context, auth_entity.User currentUser) {
    final displayName = currentUser.fullName;
    final nameToDisplay = (displayName.trim().isNotEmpty)
        ? displayName
        : 'Người Dùng';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                letterSpacing: 2.0,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              nameToDisplay,
              style: const TextStyle(
                color: kTextPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildNotificationIcon(context, currentUser.uid),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilePage(currentUser: currentUser),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(1), // Viền mỏng 1px
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.balance,
                ),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: kBgColor, // Nền âm bản cắt vào viền
                  ),
                  child: ClipOval(
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.grey, // Ám màu môi trường
                        BlendMode.luminosity, // Hiệu ứng mix-blend-luminosity
                      ),
                      child: Image.asset(
                        'assets/Futuristic Pro.png',
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.person_outline,
                              color: Colors.white,
                              size: 40,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotificationIcon(BuildContext context, String userId) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NotificationsPage(userId: userId)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: kThemeGlassBase,
          shape: BoxShape.circle,
          border: Border.all(color: kThemeBorderDefault),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              color: kTextPrimary,
              size: 24,
            ),
            StreamBuilder<int>(
              stream: sl<NotificationRemoteDataSource>().getUnreadCountStream(
                userId,
              ),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                if (count == 0) return const SizedBox.shrink();

                return Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    decoration: BoxDecoration(
                      color: kRose,
                      shape: BoxShape.circle,
                      border: Border.all(color: kBgColor, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: kRose.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Text(
                      count > 9 ? '9+' : count.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceHero(auth_entity.User currentUser) {
    return StreamBuilder(
      stream: getPrimaryWalletStreamUseCase.call(currentUser.uid),
      builder: (context, walletSnapshot) {
        double balance = 0.0;
        if (walletSnapshot.hasData) {
          walletSnapshot.data!.fold(
            (failure) => null,
            (wallet) => balance = wallet?.balance ?? 0.0,
          );
        }

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: kCyan.withValues(alpha: 0.15),
                blurRadius: 40,
                spreadRadius: -10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      kCyan.withValues(alpha: 0.15),
                      kPurple.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: kCyan.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative "Energy Core" light
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kPurple.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildCardChip(),
                            IconButton(
                              onPressed: () => setState(
                                () => _isBalanceHidden = !_isBalanceHidden,
                              ),
                              icon: Icon(
                                _isBalanceHidden
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: kCyan.withValues(alpha: 0.6),
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'SỐ DƯ KHẢ DỤNG',
                          style: TextStyle(
                            color: kTextSecondary.withValues(alpha: 0.7),
                            letterSpacing: 2.0,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _isBalanceHidden
                                  ? '••••••••'
                                  : currencyFormatter
                                        .format(balance)
                                        .replaceAll('đ', '')
                                        .trim(),
                              style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'VND',
                              style: TextStyle(
                                color: kCyan,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              currentUser.uid,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const Icon(
                              Icons.contactless_outlined,
                              color: kCyan,
                              size: 20,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthlySummary(auth_entity.User currentUser) {
    return StreamBuilder<List<dynamic>>(
      stream: getTransactionsStreamUseCase.call(currentUser.uid),
      builder: (context, snapshot) {
        final allTransactions = snapshot.data ?? [];

        // Lọc giao dịch theo tháng/năm đã chọn
        final monthlyTxs = allTransactions
            .where(
              (tx) =>
                  tx.timestamp.month == _selectedMonth.month &&
                  tx.timestamp.year == _selectedMonth.year,
            )
            .toList();

        final totalIncome = monthlyTxs
            .where((tx) => tx.type == 'Income')
            .fold(0.0, (sum, tx) => sum + tx.amount);
        final totalExpense = monthlyTxs
            .where((tx) => tx.type == 'Expense')
            .fold(0.0, (sum, tx) => sum + tx.amount);

        // Tính toán tỉ lệ cho thanh Progress
        final double total = totalIncome + totalExpense;
        final double incomeRatio = total > 0 ? totalIncome / total : 0.0;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: kThemeSurfacePrimary.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bộ chọn tháng
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'PHÂN TÍCH LUỒNG TIỀN',
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: kCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kCyan.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => _changeMonth(-1),
                          icon: const Icon(
                            Icons.chevron_left,
                            color: kCyan,
                            size: 18,
                          ),
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(),
                        ),
                        Text(
                          DateFormat('MM/yyyy').format(_selectedMonth),
                          style: const TextStyle(
                            color: kCyan,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _changeMonth(1),
                          icon: const Icon(
                            Icons.chevron_right,
                            color: kCyan,
                            size: 18,
                          ),
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Chỉ số Thu nhập & Chi tiêu
              Row(
                children: [
                  _buildStatItem(
                    label: 'THU NHẬP',
                    amount: totalIncome,
                    color: kEmerald,
                    icon: Icons.arrow_downward_rounded,
                  ),
                  _buildStatItem(
                    label: 'CHI TIÊU',
                    amount: totalExpense,
                    color: kRose,
                    icon: Icons.arrow_upward_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Thanh tỉ lệ (Ratio Bar)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      height: 8,
                      child: LinearProgressIndicator(
                        value: incomeRatio,
                        backgroundColor: kRose.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          kEmerald,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
      );
    });
  }

  Widget _buildCardChip() {
    return Container(
      width: 40,
      height: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFD700), // Gold
            Color(0xFFB8860B), // Dark Goldenrod
            Color(0xFFFFD700),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 14,
              height: 18,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black26, width: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 12),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            currencyFormatter.format(amount).replaceAll('đ', '').trim(),
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildActionItem(
            icon: Icons.account_balance_wallet_outlined,
            color: kCyan,
            label: 'Nạp tiền',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MomoDepositPage()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionItem(
            icon: Icons.send_outlined,
            color: kPurple,
            label: 'Chuyển tiền',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SendToUserPage()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionItem(
            icon: Icons.arrow_upward_rounded,
            color: kRose,
            label: 'Rút tiền',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TransferPage()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: kThemeGlassBase,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kThemeBorderDefault),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: kTextPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineSection(auth_entity.User currentUser) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'GIAO DỊCH GẦN ĐÂY',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TransactionHistoryPage(userId: currentUser.uid),
                  ),
                );
              },
              child: const Text(
                'XEM TẤT CẢ', // Micro-CTA màu Xanh Neon
                style: TextStyle(
                  color: kCyan,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<dynamic>>(
          stream: getTransactionsStreamUseCase.call(currentUser.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(color: kCyan);
            }
            if (snapshot.hasError) {
              return Text(
                'Lỗi: ${snapshot.error}',
                style: const TextStyle(color: kRose),
              );
            }

            final allTransactions = snapshot.data ?? [];
            if (allTransactions.isEmpty) {
              return const Text(
                'Chưa có giao dịch nào.',
                style: TextStyle(color: kTextSecondary),
              );
            }

            // Chỉ lấy 5 giao dịch mới nhất để hiển thị tại trang Home
            final transactions = allTransactions.take(5).toList();
            return Column(
              children: List.generate(transactions.length, (index) {
                final tx = transactions[index];

                // Parse date
                final timeDisplay = DateFormat(
                  'dd/MM/yyyy HH:mm',
                ).format(tx.timestamp);

                // Mỗi bản ghi đã thuộc về đúng user qua trường 'userId',
                // nên chỉ cần kiểm tra type để phân loại Thu/Chi
                final isIncome = tx.type == 'Income';
                final sign = isIncome ? '+' : '-';

                return _buildTimelineItem(
                  isIncome: isIncome,
                  title: tx.note.isNotEmpty
                      ? tx.note
                      : (isIncome ? 'Nhận tiền' : 'Chuyển tiền'),
                  time: timeDisplay,
                  amount:
                      '$sign${currencyFormatter.format(tx.amount).replaceAll('đ', '').trim()}',
                  onTap: () {
                    String formatCategory(String categoryId) {
                      switch (categoryId) {
                        case 'deposit': return 'Nạp tiền';
                        case 'internal_transfer': return 'Chuyển tiền nội bộ';
                        case 'transfer': return 'Rút tiền';
                        default:
                          if (categoryId.isEmpty) return 'Chưa phân loại';
                          return categoryId.replaceAll('_', ' ').replaceFirstMapped(
                              RegExp(r'^[a-z]'), (m) => m.group(0)!.toUpperCase());
                      }
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TransactionSuccessPage(
                          amount: tx.amount,
                          receiver: isIncome
                              ? 'Ví cá nhân'
                              : (tx.receiverId ?? 'Hệ thống'),
                          sender: isIncome ? (tx.senderId ?? 'Ví MoMo') : null,
                          categoryName: formatCategory(tx.categoryId),
                          timestamp: tx.timestamp,
                          note: tx.note,
                          isInternal: true,
                          isViewOnly: true,
                          isIncome: isIncome,
                        ),
                      ),
                    );
                  },
                );
              }),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required bool isIncome,
    required String title,
    required String time,
    required String amount,
    VoidCallback? onTap,
  }) {
    final color = isIncome ? kEmerald : kRose; // Phân loại màu thông minh
    final icon = isIncome ? Icons.south_west_rounded : Icons.north_east_rounded;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kThemeSurfaceSecondary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withValues(alpha: 0.2), // Viền sáng màu đặc trưng
          width: 1,
        ),
        boxShadow: [
          // Shadow màu ở "đầu" viền thẻ (bên trái)
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(-4, 0), // Đẩy bóng về bên trái
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon biểu tượng với nền mờ
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: kTextPrimary.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    color: kTextSecondary.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Cột hiển thị số tiền
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$amount đ',
                style: TextStyle(
                  color: isIncome ? kEmerald : kTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              if (isIncome)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  height: 2,
                  width: 20,
                  decoration: BoxDecoration(
                    color: kEmerald.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          ),
        ],
      ),
    ));
  }
}
