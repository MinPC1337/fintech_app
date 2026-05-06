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

                  // 4. Khối Lịch sử Giao dịch
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
      builder: (context, snapshot) {
        double balance = 0.0;
        if (snapshot.hasData) {
          snapshot.data!.fold(
            (failure) => null,
            (wallet) => balance = wallet?.balance ?? 0.0,
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                color: kThemeGlassBase,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: kThemeBorderDefault),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'TỔNG SỐ DƯ (VND)',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      letterSpacing: 3.0,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [kCyan, kCyan.withValues(alpha: 0.4)],
                    ).createShader(bounds),
                    child: Text(
                      currencyFormatter
                          .format(balance)
                          .replaceAll('đ', '')
                          .trim(),
                      style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        color: kCyan,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: kEmerald.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: kEmerald.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.trending_up, color: kEmerald, size: 16),
                        SizedBox(width: 8),
                        Text(
                          '+12% so với tháng trước',
                          style: TextStyle(
                            color: kEmerald,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
              'LỊCH SỬ GIAO DỊCH',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            TextButton(
              onPressed: () {},
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

            final transactions = snapshot.data ?? [];
            if (transactions.isEmpty) {
              return const Text(
                'Chưa có giao dịch nào.',
                style: TextStyle(color: kTextSecondary),
              );
            }

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
  }) {
    final color = isIncome ? kEmerald : kRose; // Phân loại màu thông minh
    final icon = isIncome ? Icons.south_west_rounded : Icons.north_east_rounded;

    return Container(
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
    );
  }
}
