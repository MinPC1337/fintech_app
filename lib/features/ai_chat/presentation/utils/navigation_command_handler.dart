import 'package:flutter/material.dart';
import '../../domain/entities/ai_action.dart';
import '../../../main/presentation/pages/main_page.dart';
import '../../../main/presentation/pages/budget_page.dart';
import '../../../group_wallet/presentation/pages/group_wallet_page.dart';
import '../../../main/presentation/pages/settings_page.dart';
import '../../../main/presentation/pages/momo_deposit_page.dart';
import '../../../main/presentation/pages/transfer_page.dart';
import '../../../main/presentation/pages/send_to_user_page.dart';
import '../../../main/presentation/pages/notifications_page.dart';
import '../../../main/presentation/pages/transaction_history_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NavigationCommandHandler {
  static void handle(BuildContext context, AIAction action) {
    if (action.type == AIActionType.none) return;

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    switch (action.type) {
      case AIActionType.navigate:
        // Cần map `targetRoute` nếu cần thiết, 
        // nhưng thông thường Gemini đã map sang các type cụ thể.
        break;
      case AIActionType.showBalance:
        // Đã hiển thị trên Chat UI hoặc Trang chủ, không nhất thiết navigate
        break;
      case AIActionType.openDeposit:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MomoDepositPage()));
        break;
      case AIActionType.openTransfer:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TransferPage()));
        break;
      case AIActionType.openSendMoney:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SendToUserPage()));
        break;
      case AIActionType.openBudget:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetPage()));
        break;
      case AIActionType.openGroupWallet:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupWalletPage()));
        break;
      case AIActionType.openSettings:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
        break;
      case AIActionType.openProfile:
        // ProfilePage cần currentUser (được pass từ HomePage, nhưng ở đây có thể tạo route riêng hoặc pop)
        // Note: ProfilePage yêu cầu auth_entity.User, do đó đơn giản nhất là đẩy về Home hoặc xử lý phức tạp hơn
        // Tạm thời push về MainPage
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainPage()), (route) => false);
        break;
      case AIActionType.openNotifications:
        Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsPage(userId: userId)));
        break;
      case AIActionType.openTransactionHistory:
        Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionHistoryPage(userId: userId)));
        break;
      case AIActionType.none:
        break;
    }
  }
}
