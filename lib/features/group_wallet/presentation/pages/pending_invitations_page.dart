import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fintech_app/core/theme/app_colors.dart';
import 'package:fintech_app/features/group_wallet/presentation/cubit/group_wallet_cubit.dart';
import 'package:fintech_app/features/group_wallet/presentation/cubit/group_wallet_state.dart';
import 'package:fintech_app/features/main/domain/entities/invitation_entity.dart';

class PendingInvitationsPage extends StatelessWidget {
  const PendingInvitationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroupWalletCubit, GroupWalletState>(
      builder: (context, state) {
        if (state is GroupWalletInitial || state is GroupWalletLoading) {
          return Scaffold(
            backgroundColor: kBgColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Text(
                'Lời mời ví nhóm',
                style: TextStyle(color: kTextPrimary),
              ),
            ),
            body: const Center(child: CircularProgressIndicator(color: kCyan)),
          );
        }

        if (state is GroupWalletFailure) {
          return Scaffold(
            backgroundColor: kBgColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Text(
                'Lời mời ví nhóm',
                style: TextStyle(color: kTextPrimary),
              ),
            ),
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: kRose,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        final loaded = state as GroupWalletLoaded;
        final invitations = loaded.pendingInvitations;

        return Scaffold(
          backgroundColor: kBgColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Lời mời ví nhóm',
              style: TextStyle(color: kTextPrimary),
            ),
          ),
          body: SafeArea(
            bottom: false,
            child: invitations.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Bạn chưa có lời mời tham gia ví nhóm nào.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: kTextSecondary.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    itemCount: invitations.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final invite = invitations[index];
                      final walletName =
                          invite.walletName; // Sử dụng trực tiếp từ lời mời

                      return _InvitationCard(
                        invitation: invite,
                        walletName: walletName,
                        onAccept: () => context
                            .read<GroupWalletCubit>()
                            .acceptInvitation(invite.id),
                        onReject: () => context
                            .read<GroupWalletCubit>()
                            .rejectInvitation(invite.id),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({
    required this.invitation,
    required this.walletName,
    required this.onAccept,
    required this.onReject,
  });

  final InvitationEntity invitation;
  final String walletName;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kThemeSurfaceSecondary,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kThemeBorderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lời mời tham gia nhóm "$walletName"',
            style: const TextStyle(
              color: kTextPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Từ: ${invitation.senderEmail}',
            style: TextStyle(
              color: kTextSecondary.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Email nhận: ${invitation.receiverEmail}',
            style: TextStyle(
              color: kTextSecondary.withValues(alpha: 0.75),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Chấp nhận',
                  color: kEmerald,
                  onTap: onAccept,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  label: 'Từ chối',
                  color: kRose,
                  onTap: onReject,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
