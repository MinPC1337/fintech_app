import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fintech_app/core/theme/app_colors.dart';
import 'package:fintech_app/features/auth/data/models/user_model.dart';
import '../widgets/group_wallet_detail_page/member_avatar_tile.dart';

class GroupWalletMembersPage extends StatelessWidget {
  const GroupWalletMembersPage({
    super.key,
    required this.members,
    required this.ownerId,
  });

  final List<String> members;
  final String ownerId;

  Future<List<UserModel>> _loadMemberUsers() async {
    final firestore = FirebaseFirestore.instance;
    final users = await Future.wait(
      members.map((memberId) async {
        try {
          final doc = await firestore.collection('users').doc(memberId).get();
          if (!doc.exists || doc.data() == null) return null;
          return UserModel.fromJson(doc.data()!);
        } catch (_) {
          return null;
        }
      }),
    );
    return users.whereType<UserModel>().toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Tất cả thành viên',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _loadMemberUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: kCyan));
          }
          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Không có thông tin thành viên nào.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kTextSecondary.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            itemCount: users.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = users[index];
              return MemberListTile(
                user: user,
                isOwner: user.uid == ownerId,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupWalletMemberDetailPage(
                      memberId: user.uid,
                      ownerId: ownerId,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class GroupWalletMemberDetailPage extends StatelessWidget {
  const GroupWalletMemberDetailPage({
    super.key,
    required this.memberId,
    required this.ownerId,
  });

  final String memberId;
  final String ownerId;

  Future<UserModel?> _fetchMember() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromJson(doc.data()!);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Thông tin thành viên',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: FutureBuilder<UserModel?>(
        future: _fetchMember(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: kCyan));
          }
          final member = snapshot.data;
          if (member == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Không thể tải thông tin thành viên.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kTextSecondary.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: MemberAvatarCircle(
                    avatarUrl: member.avatarUrl,
                    initials: _memberInitials(member.fullName, member.uid),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    member.fullName.isNotEmpty ? member.fullName : 'Thành viên',
                    style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    member.uid == ownerId ? 'Chủ nhóm' : 'Thành viên',
                    style: TextStyle(
                      color: kTextSecondary.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                DetailRow(
                  label: 'Email',
                  value: member.email.isNotEmpty ? member.email : 'Chưa có',
                ),
                const SizedBox(height: 12),
                DetailRow(
                  label: 'Tên hiển thị',
                  value: member.fullName.isNotEmpty
                      ? member.fullName
                      : 'Chưa có',
                ),
              ],
            ),
          );
        },
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

class MemberListTile extends StatelessWidget {
  const MemberListTile({
    super.key,
    required this.user,
    required this.isOwner,
    required this.onTap,
  });

  final UserModel user;
  final bool isOwner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kThemeSurfaceSecondary,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              MemberAvatarCircle(
                avatarUrl: user.avatarUrl,
                initials: _memberInitials(user.fullName, user.uid),
                borderColor: isOwner ? kPurple : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName.isNotEmpty ? user.fullName : 'Thành viên',
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email.isNotEmpty ? user.email : user.uid,
                      style: TextStyle(
                        color: kTextSecondary.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOwner)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: kPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Chủ',
                    style: TextStyle(
                      color: kPurple,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
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

class DetailRow extends StatelessWidget {
  const DetailRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: kThemeSurfaceSecondary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kThemeBorderDefault),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              color: kTextSecondary.withValues(alpha: 0.85),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: kTextPrimary.withValues(alpha: 0.95),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
