import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/push_notification_service.dart';
import 'home_page.dart';
import 'settings_page.dart';
import 'qr_scanner_page.dart';
import 'transfer_page.dart';
import 'send_to_user_page.dart';
import 'budget_page.dart';
import 'group_wallet_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  // Danh sách các trang. Index 0 là HomePage hiện tại của bạn.
  @override
  void initState() {
    super.initState();
    // Cập nhật FCM Token khi người dùng vào màn hình chính
    PushNotificationService.updateToken();
  }

  final List<Widget> _pages = [
    const HomePage(),
    const BudgetPage(),
    const GroupWalletPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      // Cho phép nội dung tràn xuống dưới thanh điều hướng lơ lửng
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _buildFloatingNavBar(),
    );
  }

  Widget _buildFloatingNavBar() {
    return SizedBox(
      height: 125, // Độ cao tổng thể để chứa cả nút Scan nhô lên
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 1. Thanh Dock Glassmorphism (Kính mờ không gian)
          Positioned(
            bottom: 15, // bottom-8: Cách đáy 32px tạo cảm giác lơ lửng
            left: 24, // Thụt vào 2 bên
            right: 24,
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32), // Pill Shape
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5), // Bóng đổ sâu
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // Blur 20px
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.03,
                      ), // Nền trắng mờ 3%
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: 0.1,
                        ), // Viền mảnh 10%
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildNavItem(0, Icons.home_outlined, 'Home'),
                        _buildNavItem(1, Icons.pie_chart_outline, 'Stats'),
                        const SizedBox(
                          width: 64,
                        ), // Không gian trống cho nút Scan ở giữa
                        _buildNavItem(2, Icons.group_outlined, 'Group'),
                        _buildNavItem(3, Icons.settings_outlined, 'Settings'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. Điểm nhấn trung tâm (Elevated Scan Button)
          Positioned(
            bottom: 30, // Đẩy trồi lên khỏi thanh dock
            child: _buildScanButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // Squircle mô phỏng Force Field
          color: isSelected ? kCyan.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          size: 28,
          // Active: Sáng rực Cyan | Inactive: Trắng đục mờ 40%
          color: isSelected ? kCyan : Colors.white.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildScanButton() {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        // Màu đen nguyên bản trùng với nền app để tạo viền chìm (Negative Space)
        // cắt sâu vào thanh dock kính mờ bên dưới
        color: kBgColor,
      ),
      padding: const EdgeInsets.all(6), // Tạo độ dày cho viền chìm
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Dải màu bùng nổ Cyan -> Tím
          gradient: const LinearGradient(
            colors: [kCyan, kPurple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            // Quầng sáng ảo ảnh Neon Glow
            BoxShadow(
              color: kCyan.withValues(alpha: 0.6),
              blurRadius: 30,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _handleScanButton(),
            child: const Icon(
              Icons.qr_code_scanner,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

  /// Mở QrScannerPage và định tuyến thông minh dựa trên nội dung QR:
  Future<void> _handleScanButton() async {
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (_) => const QrScannerPage(
          title: 'Quét mã QR',
          hint: 'Quét QR MoMo để rút tiền\nhoặc QR ví để chuyển nội bộ',
        ),
      ),
    );

    if (result == null || result.isEmpty || !mounted) return;

    final rawTrimmed = result.trim();

    // ── DEBUG ──────────────────────────────────────────
    debugPrint('┌──────────────────────────────────────────┐');
    debugPrint('│ [MainPage] QR result received');
    debugPrint('│  Raw    : "$rawTrimmed"');
    debugPrint('│  Length : ${rawTrimmed.length} chars');
    debugPrint('└──────────────────────────────────────────┘');
    // ──────────────────────────────────────────

    // 1. EMVCo QR (MoMo UAT / VietQR) — bắt đầu bằng "000201"
    if (rawTrimmed.startsWith('000201')) {
      final phone = _extractPhoneFromEmvco(rawTrimmed);
      debugPrint('[MainPage] EMVCo QR detected. Phone parsed: $phone');
      if (phone != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TransferPage(initialPhone: phone)),
        );
        return;
      }
      if (mounted) _showUnknownQrSheet(rawTrimmed);
      return;
    }

    // 2. Số điện thoại thẳng 10 số
    if (RegExp(r'^0\d{9}$').hasMatch(rawTrimmed)) {
      debugPrint(
        '[MainPage] → ROUTE: TransferPage (plain phone = $rawTrimmed)',
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TransferPage(initialPhone: rawTrimmed),
        ),
      );
      return;
    }

    // 3. Số tài khoản (10 số) hoặc Deeplink ví cá nhân
    String? extractedAccount;
    if (rawTrimmed.startsWith('fintech://receive?account=')) {
      extractedAccount = rawTrimmed.replaceAll(
        'fintech://receive?account=',
        '',
      );
    } else if (RegExp(r'^\d{10}$').hasMatch(rawTrimmed)) {
      extractedAccount = rawTrimmed;
    }

    if (extractedAccount != null && extractedAccount.isNotEmpty) {
      debugPrint(
        '[MainPage] → ROUTE: SendToUserPage (Acc = $extractedAccount)',
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SendToUserPage(initialReceiverUid: extractedAccount),
        ),
      );
      return;
    }

    // 3. Không nhận dạng được → bottom sheet chọn hành động
    debugPrint('[MainPage] → ROUTE: Unknown QR — showing bottom sheet');
    if (!mounted) return;
    _showUnknownQrSheet(result);
  }

  void _showUnknownQrSheet(String rawValue) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: kThemeSurfaceSecondary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: kThemeBorderDefault),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kThemeBorderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Không nhận dạng được QR',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Nội dung: $rawValue',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: kTextSecondary, fontSize: 12),
            ),
            const SizedBox(height: 24),
            _sheetAction(
              icon: Icons.phone_android,
              color: kElectricBlue,
              label: 'Rút tiền ra MoMo',
              subtitle: 'Nhập số điện thoại thủ công',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TransferPage()),
                );
              },
            ),
            const SizedBox(height: 12),
            _sheetAction(
              icon: Icons.send_rounded,
              color: kPurple,
              label: 'Chuyển vào ví nội bộ',
              subtitle: 'Nhập mã ví thủ công',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SendToUserPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetAction({
    required IconData icon,
    required Color color,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: kTextPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: kTextSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 14),
          ],
        ),
      ),
    );
  }

  /// Parse số điện thoại từ EMVCo QR (chuẩn MoMo UAT).
  /// Cấu trúc: Tag 38 → Sub-tag 01 → Sub-sub-tag 01 = SĐT.
  String? _extractPhoneFromEmvco(String qr) {
    try {
      // Lấy value của Tag 38 (Merchant Account Information)
      final tag38 = _emvcoTagValue(qr, '38');
      if (tag38 == null) {
        debugPrint('[EMVCo] Tag 38 not found');
        return null;
      }
      debugPrint('[EMVCo] Tag38 value: $tag38');

      // Trong tag 38, lấy Sub-tag 01
      final sub01 = _emvcoTagValue(tag38, '01');
      if (sub01 == null) {
        debugPrint('[EMVCo] Sub-tag 01 not found in Tag38');
        return null;
      }
      debugPrint('[EMVCo] Sub-tag01 value: $sub01');

      // Trong sub-tag 01, lấy Sub-sub-tag 01 = phone
      final phone = _emvcoTagValue(sub01, '01');
      debugPrint('[EMVCo] Phone field: $phone');

      if (phone != null && RegExp(r'^0[3-9]\d{8}$').hasMatch(phone)) {
        return phone;
      }
      return null;
    } catch (e) {
      debugPrint('[EMVCo] Parse error: $e');
      return null;
    }
  }

  /// Tìm value của [tag] trong chuỗi TLV EMVCo (mỗi entry: 2-char tag + 2-char len + value).
  String? _emvcoTagValue(String data, String tag) {
    int pos = 0;
    while (pos + 4 <= data.length) {
      final currentTag = data.substring(pos, pos + 2);
      final lenStr = data.substring(pos + 2, pos + 4);
      final len = int.tryParse(lenStr);
      if (len == null || pos + 4 + len > data.length) break;
      final value = data.substring(pos + 4, pos + 4 + len);
      if (currentTag == tag) return value;
      pos += 4 + len;
    }
    return null;
  }
}
