import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fintech_app/core/theme/app_colors.dart';
import 'package:fintech_app/features/auth/data/models/user_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MemberAvatarTile extends StatelessWidget {
  const MemberAvatarTile({
    super.key,
    required this.memberId,
    required this.onTap,
    this.isOwner = false,
  });

  final String memberId;
  final VoidCallback onTap;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .snapshots(),
      builder: (context, snapshot) {
        final user =
            snapshot.hasData &&
                snapshot.data!.exists &&
                snapshot.data!.data() != null
            ? UserModel.fromJson(snapshot.data!.data()!)
            : null;
        final initials = _memberInitials(user?.fullName ?? '', memberId);
        final displayName = user?.fullName.isNotEmpty == true
            ? user!.fullName
            : memberId;
        return GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: 72,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isOwner ? kPurple : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: user != null && user.avatarUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: user.avatarUrl,
                            width: 58,
                            height: 58,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) =>
                                _fallbackAvatar(initials),
                          )
                        : _fallbackAvatar(initials),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  displayName,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _fallbackAvatar(String initials) {
    return Container(
      color: kCyan.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(color: kCyan, fontWeight: FontWeight.w900),
      ),
    );
  }

  String _memberInitials(String fullName, String uid) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    if (fullName.isNotEmpty) return fullName[0].toUpperCase();
    return uid.substring(0, uid.length.clamp(1, 2)).toUpperCase();
  }
}

class MemberAvatarCircle extends StatelessWidget {
  const MemberAvatarCircle({
    super.key,
    required this.avatarUrl,
    required this.initials,
    this.borderColor,
  });

  final String avatarUrl;
  final String initials;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor ?? Colors.transparent,
          width: borderColor != null ? 2 : 0,
        ),
      ),
      child: ClipOval(
        child: avatarUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: avatarUrl,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) =>
                    _fallbackCircle(initials),
              )
            : _fallbackCircle(initials),
      ),
    );
  }

  Widget _fallbackCircle(String initials) {
    return Container(
      color: kCyan.withValues(alpha: 0.14),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: kCyan,
          fontSize: 30,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
