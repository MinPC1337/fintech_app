import 'package:flutter/material.dart';

// --- Deep Space & Neon Theme Palette ---

// 1. Nền & Cấu trúc cơ bản
const Color kThemeBackground = Color(
  0xFF0B1224,
); // Navy sâu, tươi hơn đen tuyệt đối
const Color kThemeSurfacePrimary = Color(0xFF162033);
const Color kThemeSurfaceSecondary = Color(0xFF1E293B); // Slate 800
const Color kThemeGlassBase = Color(
  0x80162033,
); // Tăng độ trong suốt cho hiệu ứng kính

// 2. Màu Neon/Accent - Tài chính hóa
const Color kThemeNeonProfit = Color(0xFF34D399); // Emerald 400: Xanh lục tươi
const Color kThemeNeonLoss = Color(0xFFFB7185); // Rose 400: Đỏ hồng hiện đại
const Color kThemeNeonPrimary = Color(0xFF22D3EE); // Cyan 400: Xanh lơ sáng rực
const Color kThemeNeonSecondary = Color(
  0xFFC084FC,
); // Purple 400: Tím nhẹ nhàng hơn
const Color kThemeNeonWarning = Color(0xFFFFD700);
const Color kThemeNeonInfo = Color(
  0xFF38BDF8,
); // Sky 400: Xanh bầu trời tươi mát

// 3. Màu UI bổ sung (cho các thành phần cụ thể)
const Color kElectricBlue = Color(0xFF3388FF);
const Color kOceanBlue = Color(0xFF004C99);

// 4. Màu Text - Độ tương phản cao
const Color kThemeTextPrimary = Color(0xFFF0F4FF);
const Color kThemeTextSecondary = Color(0xFF8B94B8);
const Color kThemeTextMuted = Color(0xFF64748B); // Slate 500
const Color kThemeTextAccent = Color(0xFF22D3EE);

// 5. Border Effects
const Color kThemeBorderDefault = Color(0x3322D3EE); // Tăng độ rõ của viền Cyan
const Color kThemeBorderFocus = Color(0x9922D3EE);

// --- MAPPING ---
// Nền & Bề mặt
const Color kBgColor = kThemeBackground;
const Color kSurface = kThemeSurfaceSecondary;
const Color kGlassBg = kThemeGlassBase;

// Màu nhấn & Accent
const Color kCyan = kThemeNeonPrimary;
const Color kNeonCyan = kThemeNeonPrimary; // Alias cho kCyan
const Color kPurple = kThemeNeonSecondary;
const Color kRose = kThemeNeonLoss;
const Color kEmerald = kThemeNeonProfit;

// Text & Border
const Color kTextPrimary = kThemeTextPrimary;
const Color kTextSecondary = kThemeTextSecondary;
const Color kGlassBorder = kThemeBorderDefault;
const Color kBorder = kThemeBorderDefault;

// --- Gradients ---
class AppGradients {
  static const profit = LinearGradient(
    colors: [kThemeNeonProfit, Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const loss = LinearGradient(
    colors: [kThemeNeonLoss, Color(0xFFFF6B9D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const balance = LinearGradient(
    colors: [kThemeNeonPrimary, kThemeNeonSecondary, kThemeNeonLoss],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const ambient = LinearGradient(
    colors: [Color(0x1A06FFD9), Color(0x1AB24BFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

// --- Glow Effects ---
class AppGlows {
  static const cyan = BoxShadow(
    color: Color(0x6622D3EE), // Tăng quầng sáng
    blurRadius: 20,
  );
  static const purple = BoxShadow(color: Color(0x66C084FC), blurRadius: 20);
  static const profit = BoxShadow(color: Color(0x6634D399), blurRadius: 15);
  static const emerald = BoxShadow(color: Color(0x6634D399), blurRadius: 15);
  static const rose = BoxShadow(color: Color(0x66FB7185), blurRadius: 15);
}
