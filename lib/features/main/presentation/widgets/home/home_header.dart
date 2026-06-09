import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../injection_container.dart';
import '../../../../auth/domain/entities/user.dart' as auth_entity;
import '../../../../auth/presentation/pages/profile_page.dart';
import '../../../data/datasources/notification_remote_data_source.dart';
import '../../pages/notifications_page.dart';

class HomeHeader extends StatelessWidget {
  final auth_entity.User currentUser;

  const HomeHeader({super.key, required this.currentUser});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return 'Chào buổi sáng,';
    } else if (hour >= 11 && hour < 13) {
      return 'Chào buổi trưa,';
    } else if (hour >= 13 && hour < 18) {
      return 'Chào buổi chiều,';
    } else {
      return 'Chào buổi tối,';
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = currentUser.fullName;
    final nameToDisplay = (displayName.trim().isNotEmpty)
        ? displayName.split(' ').last
        : 'Bạn';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
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
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.balance,
                ),
                child: ClipOval(
                  child: (currentUser.avatarUrl.isEmpty)
                      ? ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            Colors.grey,
                            BlendMode.luminosity,
                          ),
                          child: Image.asset(
                            'assets/app_icon.png',
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 40,
                                ),
                          ),
                        )
                      : Image.network(
                          currentUser.avatarUrl,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 40,
                              ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: const TextStyle(
                    color: kThemeTextSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      nameToDisplay,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(' 👋', style: TextStyle(fontSize: 18)),
                  ],
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            _buildNotificationIcon(context, currentUser.uid),
            const SizedBox(width: 16),
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
}
