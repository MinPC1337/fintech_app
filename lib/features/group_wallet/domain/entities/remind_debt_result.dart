class RemindDebtResult {
  final String notificationId;
  final String borrowerId;
  final String title;
  final String body;
  final String debtId;
  final String walletId;

  const RemindDebtResult({
    required this.notificationId,
    required this.borrowerId,
    required this.title,
    required this.body,
    required this.debtId,
    required this.walletId,
  });
}
