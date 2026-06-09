import 'package:equatable/equatable.dart';

/// Các loại hành động mà AI có thể đề xuất.
enum AIActionType {
  navigate,
  showBalance,
  openDeposit,
  openTransfer,
  openSendMoney,
  openBudget,
  openGroupWallet,
  openSettings,
  openProfile,
  openNotifications,
  openTransactionHistory,
  none,
}

/// Entity mô tả một hành động AI muốn thực thi trong app.
class AIAction extends Equatable {
  final AIActionType type;
  final String? targetRoute;
  final Map<String, dynamic>? params;

  const AIAction({
    required this.type,
    this.targetRoute,
    this.params,
  });

  const AIAction.none() : this(type: AIActionType.none);

  @override
  List<Object?> get props => [type, targetRoute, params];

  /// Parse action type từ string trả về bởi AI hoặc Firestore.
  static AIActionType parseType(String? actionStr) {
    if (actionStr == null) return AIActionType.none;

    // 1. Thử parse trực tiếp từ enum name (camelCase — khi đọc từ Firestore)
    //    VD: 'openDeposit', 'openTransfer', 'navigate', 'none', ...
    try {
      return AIActionType.values.byName(actionStr);
    } catch (_) {
      // fallthrough — thử parse dạng AI trả về (snake_case/short)
    }

    // 2. Parse từ string AI trả về (snake_case hoặc dạng ngắn)
    switch (actionStr.toLowerCase()) {
      case 'navigate':
        return AIActionType.navigate;
      case 'show_balance':
        return AIActionType.showBalance;
      case 'open_deposit':
      case 'deposit':
        return AIActionType.openDeposit;
      case 'open_transfer':
      case 'transfer':
        return AIActionType.openTransfer;
      case 'open_send_money':
      case 'send_money':
        return AIActionType.openSendMoney;
      case 'open_budget':
      case 'budget':
        return AIActionType.openBudget;
      case 'open_group_wallet':
      case 'group_wallet':
        return AIActionType.openGroupWallet;
      case 'open_settings':
      case 'settings':
        return AIActionType.openSettings;
      case 'open_profile':
      case 'profile':
        return AIActionType.openProfile;
      case 'open_notifications':
      case 'notifications':
        return AIActionType.openNotifications;
      case 'open_transaction_history':
      case 'transaction_history':
        return AIActionType.openTransactionHistory;
      default:
        return AIActionType.none;
    }
  }

  /// Tạo [AIAction] từ target route string (trả về bởi AI JSON).
  factory AIAction.fromTarget(String? actionStr, String? target) {
    final type = parseType(actionStr);

    if (type == AIActionType.navigate && target != null) {
      // Map target string → specific AIActionType
      final mapped = parseType(target);
      if (mapped != AIActionType.none) {
        return AIAction(type: mapped, targetRoute: target);
      }
      return AIAction(type: AIActionType.navigate, targetRoute: target);
    }

    return AIAction(type: type, targetRoute: target);
  }
}
