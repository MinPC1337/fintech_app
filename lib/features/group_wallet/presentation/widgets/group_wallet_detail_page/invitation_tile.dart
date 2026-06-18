import 'package:flutter/material.dart';
import 'package:fintech_app/core/theme/app_colors.dart';
import 'package:fintech_app/features/main/domain/entities/invitation_entity.dart';


class InvitationTile extends StatelessWidget {
  const InvitationTile({
    super.key,
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kThemeSurfaceSecondary,
        borderRadius: BorderRadius.circular(18),
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
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Từ: ${invitation.senderEmail}',
            style: TextStyle(
              color: kTextSecondary.withValues(alpha: 0.85),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Email nhận: ${invitation.receiverEmail}',
            style: TextStyle(
              color: kTextSecondary.withValues(alpha: 0.85),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _InvitationButton(
                  label: 'Chấp nhận',
                  color: kEmerald,
                  onTap: onAccept,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InvitationButton(
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

class _InvitationButton extends StatelessWidget {
  const _InvitationButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
