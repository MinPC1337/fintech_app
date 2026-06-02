import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart';
import '../../data/models/notification_model.dart';
import '../../data/datasources/notification_remote_data_source.dart';
import 'transaction_history_page.dart';

class NotificationsPage extends StatelessWidget {
  final String userId;

  const NotificationsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: kBgColor,
        appBar: AppBar(
          backgroundColor: kBgColor,
          elevation: 0,
          title: const Text('Thông báo', style: TextStyle(color: kTextPrimary)),
          iconTheme: const IconThemeData(color: kTextPrimary),
          bottom: const TabBar(
            labelColor: kCyan,
            unselectedLabelColor: kTextSecondary,
            indicatorColor: kCyan,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: 'Biến động số dư'),
              Tab(text: 'Thông báo'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            TransactionHistoryPage(userId: userId),
            _buildNotificationsTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsTab(BuildContext context) {
    return StreamBuilder<List<NotificationModel>>(
      stream: sl<NotificationRemoteDataSource>().getNotificationsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kCyan));
        }

        final allNotifications = snapshot.data ?? [];
        final notifications = allNotifications
            .where((n) => n.type != 'transaction')
            .toList();

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  size: 64,
                  color: kTextSecondary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chưa có thông báo nào',
                  style: TextStyle(color: kTextSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final item = notifications[index];
            return _buildNotificationItem(context, item);
          },
        );
      },
    );
  }

  Widget _buildNotificationItem(BuildContext context, NotificationModel item) {
    final Color accentColor = switch (item.type) {
      'transaction' => kCyan,
      'debt_reminder' => kRose,
      _ => kPurple,
    };

    final String emojiIcon = switch (item.type) {
      'transaction' => '💳',
      'debt_reminder' => '⏰',
      _ => '🔔',
    };

    final String typeLabel = switch (item.type) {
      'transaction' => 'Biến động',
      'debt_reminder' => 'Nhắc nợ',
      _ => 'Thông báo',
    };

    return GestureDetector(
      onTap: () {
        if (!item.isRead) {
          sl<NotificationRemoteDataSource>().markAsRead(item.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: item.isRead
              ? kThemeGlassBase
              : accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: item.isRead
                ? kThemeBorderDefault.withValues(alpha: 0.1)
                : accentColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left accent border for unread
                  if (!item.isRead)
                    Container(
                      width: 4,
                      decoration: BoxDecoration(color: accentColor),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Text(
                              emojiIcon,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accentColor.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        typeLabel,
                                        style: TextStyle(
                                          color: accentColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      DateFormat(
                                        'HH:mm - dd/MM/yyyy',
                                      ).format(item.timestamp),
                                      style: TextStyle(
                                        color: kTextSecondary.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    color: kTextPrimary,
                                    fontWeight: item.isRead
                                        ? FontWeight.w500
                                        : FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.body,
                                  style: TextStyle(
                                    color: kTextSecondary.withValues(
                                      alpha: 0.9,
                                    ),
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
