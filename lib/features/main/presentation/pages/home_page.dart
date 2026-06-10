import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/user.dart' as auth_entity;
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';

// Import new home widgets
import '../widgets/home/home_header.dart';
import '../widgets/home/total_assets_card.dart';
import '../widgets/home/quick_actions_row.dart';
import '../widgets/home/monthly_overview_section.dart';
import '../widgets/home/group_wallets_card.dart';

class HomePage extends StatefulWidget {
  final bool isActive;
  const HomePage({super.key, this.isActive = true});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header
                  HomeHeader(currentUser: currentUser),
                  const SizedBox(height: 24),

                  // 2. Total Assets Card
                  TotalAssetsCard(userId: currentUser.uid, isActive: widget.isActive),
                  const SizedBox(height: 24),

                  // 3. Quick Actions
                  const QuickActionsRow(),
                  const SizedBox(height: 24),

                  // 4. Monthly Overview Section (Tổng quan & Picker)
                  MonthlyOverviewSection(userId: currentUser.uid, isActive: widget.isActive),
                  const SizedBox(height: 16),

                  GroupWalletsCard(userId: currentUser.uid),
                  const SizedBox(height: 16),

                  // Bottom Spacing for bottom navigation bar
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
