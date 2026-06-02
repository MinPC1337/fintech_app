import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart';
import '../../../auth/domain/entities/user.dart' as auth_entity;
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/usecases/get_transactions_stream_usecase.dart';
import '../../domain/usecases/get_primary_wallet_stream_usecase.dart';
import '../../domain/usecases/watch_out_categories_usecase.dart';
import 'transaction_success_page.dart';

String _categoryDisplayLabel(
  String categoryId,
  List<CategoryEntity> walletCategories,
) {
  switch (categoryId) {
    case 'deposit':
      return 'Nạp tiền';
    case 'internal_transfer':
      return 'Chuyển tiền nội bộ';
    case 'transfer':
      return 'Rút tiền';
    default:
      if (categoryId.isEmpty) return 'Chưa phân loại';
      for (final c in walletCategories) {
        if (c.id == categoryId) return c.name;
      }
      return categoryId
          .replaceAll('_', ' ')
          .replaceFirstMapped(
            RegExp(r'^[a-z]'),
            (match) => match.group(0)!.toUpperCase(),
          );
  }
}

class TransactionHistoryPage extends StatelessWidget {
  final String userId;

  const TransactionHistoryPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );
    final getTransactionsUseCase = sl<GetTransactionsStreamUseCase>();
    final getPrimaryWalletUseCase = sl<GetPrimaryWalletStreamUseCase>();
    final watchCategoriesUseCase = sl<WatchOutCategoriesUseCase>();

    return Container(
      color: kBgColor,
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          auth_entity.User? profileUser;
          if (authState is AuthSuccess) profileUser = authState.user;

          return StreamBuilder(
            stream: getPrimaryWalletUseCase.call(userId),
            builder: (context, walletSnapshot) {
              String? primaryWalletId;
              if (walletSnapshot.hasData) {
                walletSnapshot.data!.fold(
                  (f) => null,
                  (w) => primaryWalletId = w?.id,
                );
              }

              return StreamBuilder<List<dynamic>>(
                stream: getTransactionsUseCase.call(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: kCyan),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Lỗi: ${snapshot.error}',
                        style: const TextStyle(color: kRose),
                      ),
                    );
                  }

                  final allTransactions = (snapshot.data ?? []).where((tx) {
                    if (primaryWalletId == null) return false;
                    return tx.toWalletId == primaryWalletId ||
                        tx.fromWalletId == primaryWalletId;
                  }).toList();

                  if (allTransactions.isEmpty) {
                    return const Center(
                      child: Text(
                        'Chưa có giao dịch nào.',
                        style: TextStyle(color: kTextSecondary),
                      ),
                    );
                  }

                  return StreamBuilder<List<CategoryEntity>>(
                    stream: watchCategoriesUseCase.call(userId),
                    builder: (context, catSnapshot) {
                      final walletCategories = catSnapshot.data ?? [];

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        itemCount: allTransactions.length,
                        itemBuilder: (context, index) {
                          final tx = allTransactions[index];
                          final timeDisplay = DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format(tx.timestamp);
                          final isIncrease = tx.toWalletId == primaryWalletId;
                          final sign = isIncrease ? '+' : '-';
                          final color = isIncrease ? kEmerald : kRose;
                          final icon = isIncrease
                              ? Icons.south_west_rounded
                              : Icons.north_east_rounded;
                          final title = tx.note.isNotEmpty
                              ? tx.note
                              : (isIncrease ? 'Nhận tiền' : 'Chuyển tiền');

                          String formatWallet(String? id) {
                            if (id == null || id.isEmpty) return 'Ví MoMo';
                            if (id == userId) {
                              final name =
                                  profileUser != null &&
                                      profileUser.fullName.isNotEmpty
                                  ? profileUser.fullName
                                  : 'Người dùng';
                              return 'Ví cá nhân - $name';
                            }
                            return 'Ví cá nhân - $id';
                          }

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TransactionSuccessPage(
                                    amount: tx.amount,
                                    sender: isIncrease
                                        ? formatWallet(tx.senderId)
                                        : formatWallet(userId),
                                    receiver: isIncrease
                                        ? formatWallet(userId)
                                        : formatWallet(tx.receiverId),
                                    categoryName: _categoryDisplayLabel(
                                      tx.categoryId,
                                      walletCategories,
                                    ),
                                    timestamp: tx.timestamp,
                                    note: tx.note,
                                    isInternal: true,
                                    isViewOnly: true,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: kThemeSurfaceSecondary.withValues(
                                  alpha: 0.5,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.15),
                                    blurRadius: 12,
                                    offset: const Offset(-4, 0),
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
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(icon, color: color, size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: kTextPrimary.withValues(
                                              alpha: 0.9,
                                            ),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          timeDisplay,
                                          style: const TextStyle(
                                            color: kTextSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '$sign${currencyFormatter.format(tx.amount).replaceAll('đ', '').trim()}',
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
