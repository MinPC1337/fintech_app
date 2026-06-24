import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../injection_container.dart';
import '../../../../auth/domain/entities/user.dart' as auth_entity;
import '../../../../auth/presentation/pages/profile_page.dart';
import '../../../data/datasources/notification_remote_data_source.dart';
import '../../pages/notifications_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
                      : CachedNetworkImage(
                          imageUrl: currentUser.avatarUrl,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => const Icon(
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
        child: StreamBuilder<int>(
          stream: sl<NotificationRemoteDataSource>().getUnreadCountStream(
            userId,
          ),
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedBellWidget(unreadCount: count),
                if (count > 0)
                  Positioned(
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
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class AnimatedBellWidget extends StatefulWidget {
  final int unreadCount;

  const AnimatedBellWidget({super.key, required this.unreadCount});

  @override
  State<AnimatedBellWidget> createState() => _AnimatedBellWidgetState();
}

class _AnimatedBellWidgetState extends State<AnimatedBellWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.unreadCount > 0) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AnimatedBellWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.unreadCount > 0 && oldWidget.unreadCount == 0) {
      _controller.repeat();
    } else if (widget.unreadCount == 0 && oldWidget.unreadCount > 0) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        double angle = 0;
        // Rung trong 30% thời gian đầu, sau đó nghỉ
        if (t < 0.3) {
          // Lắc 3 vòng (1 vòng = 2 pi)
          angle = math.sin((t / 0.3) * math.pi * 6) * 0.15;
        }

        return Transform.rotate(
          angle: angle,
          alignment: Alignment.topCenter,
          child: child,
        );
      },
      child: const Icon(
        Icons.notifications_none_rounded,
        color: kTextPrimary,
        size: 24,
      ),
    );
  }
}
