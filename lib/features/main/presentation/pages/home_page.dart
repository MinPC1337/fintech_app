import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/get_primary_wallet_stream_usecase.dart';
import 'momo_deposit_page.dart';
import 'transfer_page.dart';
import 'receive_money_page.dart';
import 'send_to_user_page.dart';
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
                  const SizedBox(height: 48),

                  // 2. Khối Trung tâm Số dư (Hero Section)
                  _buildBalanceHero(currentUser),
                  const SizedBox(height: 48),

                  // 3. Khối Thao tác nhanh (Bento Quick Actions)
                  _buildBentoActions(context),
                  const SizedBox(height: 40),

                  // 4. Khối Lịch sử Giao dịch (Fluid Transaction Timeline)
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
                    errorBuilder: (context, error, stackTrace) => const Icon(
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'TỔNG SỐ DƯ (VND)',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                letterSpacing: 3.0, // tracking-[0.2em]
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  kCyan,
                  kCyan.withValues(alpha: 0.4),
                ], // Gradient sáng xuống mờ
              ).createShader(bounds),
              child: Text(
                currencyFormatter.format(balance).replaceAll('đ', '').trim(),
                style: const TextStyle(
                  fontSize: 52, // Con số khổng lồ
                  fontWeight: FontWeight.w900,
                  color: kCyan,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: kEmerald.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: kEmerald.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.trending_up, color: kEmerald, size: 16),
                  const SizedBox(width: 8),
                  const Text(
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
        );
      },
    );
  }

  Widget _buildBentoActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildBentoCard(
                icon: Icons.account_balance_wallet_outlined,
                iconColor: kCyan,
                title: 'Nạp tiền',
                subtitle: 'Qua MoMo',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MomoDepositPage()),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildBentoCard(
                icon: Icons.qr_code_rounded,
                iconColor: kEmerald,
                title: 'Nhận tiền',
                subtitle: 'Mã QR ví',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReceiveMoneyPage()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildBentoCard(
                icon: Icons.send_outlined,
                iconColor: kPurple,
                title: 'Chuyển vào ví',
                subtitle: 'Nội bộ',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SendToUserPage()),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildBentoCard(
                icon: Icons.arrow_upward_rounded,
                iconColor: kRose,
                title: 'Rút tiền',
                subtitle: 'Ra MoMo',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TransferPage()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kThemeGlassBase,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kThemeBorderDefault),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (iconColor == kCyan) AppGlows.cyan,
                      if (iconColor == kPurple) AppGlows.purple,
                      if (iconColor == kEmerald)
                        BoxShadow(
                          color: kEmerald.withValues(alpha: 0.3),
                          blurRadius: 12,
                        ),
                      if (iconColor == kRose)
                        BoxShadow(
                          color: kRose.withValues(alpha: 0.3),
                          blurRadius: 12,
                        ),
                    ],
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(color: kTextSecondary, fontSize: 11),
                  ),
              ],
            ),
          ),
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
                  isFirst: index == 0,
                  isLast: index == transactions.length - 1,
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
    required bool isFirst,
    required bool isLast,
    required bool isIncome,
    required String title,
    required String time,
    required String amount,
  }) {
    final color = isIncome ? kEmerald : kRose; // Phân loại màu thông minh
    final icon = isIncome ? Icons.south_west_rounded : Icons.north_east_rounded;

    return IntrinsicHeight(
      child: Row(
        children: [
          // Dây rốn Năng lượng (Timeline Line)
          SizedBox(
            width: 32,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: isFirst ? 40 : 0, // Căn chỉnh dòng bắt đầu
                  bottom: isLast ? null : 0, // Căn chỉnh dòng kết thúc
                  height: isLast ? 40 : null,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          kCyan.withValues(alpha: 0.6),
                          kPurple.withValues(alpha: 0.2),
                        ],
                      ),
                    ),
                  ),
                ),
                // Điểm giao dịch (Node)
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: kBgColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Thẻ Giao dịch (Transaction Card)
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kThemeSurfaceSecondary, // --surface-secondary
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kThemeBorderDefault), // border cyan
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
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
                          style: const TextStyle(
                            color: kTextPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          time,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$amount đ',
                    style: TextStyle(
                      color: isIncome
                          ? kEmerald
                          : kTextPrimary, // Emerald cho Thu, Trắng cho Chi
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
