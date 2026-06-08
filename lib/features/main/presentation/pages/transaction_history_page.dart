import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/emoji_mapping.dart';
import '../../../../injection_container.dart';
import '../../../auth/domain/entities/user.dart' as auth_entity;
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/usecases/get_transactions_stream_usecase.dart';
import '../../domain/usecases/get_primary_wallet_stream_usecase.dart';
import '../../domain/usecases/watch_out_categories_usecase.dart';
import 'transaction_success_page.dart';
import '../../data/datasources/notification_remote_data_source.dart';

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

class TransactionHistoryPage extends StatefulWidget {
  final String userId;

  const TransactionHistoryPage({super.key, required this.userId});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  @override
  void initState() {
    super.initState();
    // Mark all transaction-type notifications as read when opening this tab
    sl<NotificationRemoteDataSource>().markAllAsReadForUserAndType(
      widget.userId,
      'transaction',
    );
  }

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
            stream: getPrimaryWalletUseCase.call(widget.userId),
            builder: (context, walletSnapshot) {
              String? primaryWalletId;
              if (walletSnapshot.hasData) {
                walletSnapshot.data!.fold(
                  (f) => null,
                  (w) => primaryWalletId = w?.id,
                );
              }

              return StreamBuilder<List<dynamic>>(
                stream: getTransactionsUseCase.call(widget.userId),
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
                    stream: watchCategoriesUseCase.call(widget.userId),
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
                          String getCategoryEmoji(
                            String categoryId,
                            List<CategoryEntity> walletCategories,
                            bool isIncrease,
                          ) {
                            // Try to find category in the list
                            for (final cat in walletCategories) {
                              if (cat.id == categoryId && cat.emoji != null) {
                                return cat.emoji!;
                              }
                            }

                            // Fallback to special transaction types
                            if (categoryId == 'deposit') return '💰';
                            if (categoryId == 'internal_transfer') return '💳';
                            if (categoryId == 'transfer') return '💸';

                            // Fallback to category name pattern matching
                            final emoji = getEmojiForCategoryName(categoryId);
                            if (emoji != '🏦') {
                              return emoji; // Return if not default
                            }

                            // Ultimate fallback based on transaction direction
                            return getDefaultTransactionEmoji(isIncrease);
                          }

                          final isIncrease = tx.toWalletId == primaryWalletId;
                          final sign = isIncrease ? '+' : '-';
                          // Changed red to TextPrimary for negative for elegance, but the user might want a subtle red or just white. Let's use kTextPrimary or kThemeTextPrimary. Actually, a neutral white for negative is very modern. Or maybe kRose. I will stick to kTextPrimary for negative (modern minimalist). Wait, let's use a subtle color for negative, maybe kThemeTextPrimary.
                          final amountColor = isIncrease
                              ? kEmerald
                              : kTextPrimary;
                          final emoji = getCategoryEmoji(
                            tx.categoryId,
                            walletCategories,
                            isIncrease,
                          );

                          final title = tx.note.isNotEmpty
                              ? tx.note
                              : (isIncrease ? 'Nhận tiền' : 'Chuyển tiền');

                          String formatWallet(String? id) {
                            if (id == null || id.isEmpty) return 'Ví MoMo';
                            if (id == widget.userId) {
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
                                        : formatWallet(widget.userId),
                                    receiver: isIncrease
                                        ? formatWallet(widget.userId)
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
                              decoration: BoxDecoration(
                                color: kThemeGlassBase,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: kThemeBorderDefault,
                                  width: 0.5,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 10,
                                    sigmaY: 10,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color:
                                                (isIncrease
                                                        ? kEmerald
                                                        : kThemeSurfacePrimary)
                                                    .withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color:
                                                  (isIncrease
                                                          ? kEmerald
                                                          : kTextSecondary)
                                                      .withValues(alpha: 0.1),
                                            ),
                                          ),
                                          child: Text(
                                            emoji,
                                            style: const TextStyle(
                                              fontSize: 22,
                                            ),
                                          ),
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
                                                  color: kTextPrimary
                                                      .withValues(alpha: 0.95),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
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
                                            color: amountColor,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
