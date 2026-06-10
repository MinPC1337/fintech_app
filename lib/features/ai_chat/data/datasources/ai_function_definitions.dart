import 'package:google_generative_ai/google_generative_ai.dart';

/// Định nghĩa tất cả các [Tool] mà Gemini có thể gọi để lấy dữ liệu thực tế.
///
/// Danh sách function:
/// - [getWalletBalance]   — Lấy số dư ví cá nhân hiện tại
/// - [getRecentTransactions] — Lấy lịch sử giao dịch gần đây
/// - [getBudgetStatus]    — Lấy trạng thái ngân sách tháng hiện tại
/// - [getGroupWallets]    — Lấy danh sách ví nhóm user đang tham gia
/// - [getPendingDebts]    — Lấy danh sách nợ chưa trả (cả nợ đi & nợ về)
class AiFunctionDefinitions {
  AiFunctionDefinitions._();

  /// Tool duy nhất chứa tất cả function declarations.
  static Tool get appDataTool => Tool(
    functionDeclarations: [
      _getWalletBalance,
      _getRecentTransactions,
      _getBudgetStatus,
      _getGroupWallets,
      _getPendingDebts,
    ],
  );

  // ────────────────────────────────────────────────────
  // Function: getWalletBalance
  // ────────────────────────────────────────────────────

  static final FunctionDeclaration _getWalletBalance = FunctionDeclaration(
    'getWalletBalance',
    'Lấy số dư ví cá nhân hiện tại của người dùng. '
        'Dùng khi user hỏi về số dư, còn bao nhiêu tiền, '
        'hoặc trước khi tư vấn về giao dịch cần kiểm tra balance.',
    Schema.object(properties: {}),
  );

  // ────────────────────────────────────────────────────
  // Function: getRecentTransactions
  // ────────────────────────────────────────────────────

  static final FunctionDeclaration _getRecentTransactions =
      FunctionDeclaration(
        'getRecentTransactions',
        'Lấy lịch sử giao dịch gần đây của người dùng. '
            'Dùng khi user hỏi về giao dịch gần đây, lịch sử thu/chi, '
            'hoặc muốn biết đã giao dịch những gì.',
        Schema.object(
          properties: {
            'limit': Schema.integer(
              description: 'Số lượng giao dịch cần lấy (mặc định 5, tối đa 10)',
            ),
            'type': Schema.string(
              description:
                  'Lọc theo loại giao dịch: "Income" (thu) hoặc "Expense" (chi). '
                  'Để trống để lấy tất cả.',
            ),
          },
        ),
      );

  // ────────────────────────────────────────────────────
  // Function: getBudgetStatus
  // ────────────────────────────────────────────────────

  static final FunctionDeclaration _getBudgetStatus = FunctionDeclaration(
    'getBudgetStatus',
    'Lấy trạng thái ngân sách của một tháng cụ thể — hạn mức và chi tiêu thực tế '
        'theo từng danh mục. Dùng khi user hỏi về ngân sách, chi tiêu, '
        'còn bao nhiêu trong danh mục nào, hoặc có vượt ngân sách không.',
    Schema.object(
      properties: {
        'month': Schema.integer(
          description: 'Tháng cần lấy ngân sách (1-12). Mặc định là tháng hiện tại nếu không cung cấp.',
        ),
        'year': Schema.integer(
          description: 'Năm cần lấy ngân sách (VD: 2024). Mặc định là năm hiện tại nếu không cung cấp.',
        ),
      },
    ),
  );

  // ────────────────────────────────────────────────────
  // Function: getGroupWallets
  // ────────────────────────────────────────────────────

  static final FunctionDeclaration _getGroupWallets = FunctionDeclaration(
    'getGroupWallets',
    'Lấy danh sách các ví nhóm mà người dùng đang tham gia, '
        'bao gồm tên nhóm, số dư quỹ, vai trò (admin/thành viên). '
        'Dùng khi user hỏi về ví nhóm của họ hoặc muốn biết đang trong nhóm nào.',
    Schema.object(properties: {}),
  );

  // ────────────────────────────────────────────────────
  // Function: getPendingDebts
  // ────────────────────────────────────────────────────

  static final FunctionDeclaration _getPendingDebts = FunctionDeclaration(
    'getPendingDebts',
    'Lấy danh sách nợ chưa thanh toán của người dùng — '
        'bao gồm nợ phải trả (borrower) và nợ chưa thu được (lender). '
        'Dùng khi user hỏi về nợ, ai nợ tôi, tôi nợ ai, '
        'hoặc tổng tiền nợ hiện tại.',
    Schema.object(properties: {}),
  );
}
