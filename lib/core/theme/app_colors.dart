import 'package:flutter/material.dart';

// --- Deep Space & Neon Theme Palette ---

// 1. Nền & Cấu trúc cơ bản
const Color kThemeBackground = Color(0xFF010208);
const Color kThemeSurfacePrimary = Color(0xFF0A0E1A);
const Color kThemeSurfaceSecondary = Color(0xFF121829);
const Color kThemeGlassBase = Color(0x990A0E1A); // rgba(10, 14, 26, 0.6)

// 2. Màu Neon/Accent - Tài chính hóa
const Color kThemeNeonProfit = Color(0xFF00FF94);
const Color kThemeNeonLoss = Color(0xFFFF3366);
const Color kThemeNeonPrimary = Color(0xFF06FFD9);
const Color kThemeNeonSecondary = Color(0xFFB24BFF);
const Color kThemeNeonWarning = Color(0xFFFFD700);
const Color kThemeNeonInfo = Color(0xFF00D4FF);

// 3. Màu UI bổ sung (cho các thành phần cụ thể)
const Color kElectricBlue = Color(0xFF3388FF);
const Color kOceanBlue = Color(0xFF004C99);

// 4. Màu Text - Độ tương phản cao
const Color kThemeTextPrimary = Color(0xFFF0F4FF);
const Color kThemeTextSecondary = Color(0xFF8B94B8);
const Color kThemeTextMuted = Color(0xFF4A5578);
const Color kThemeTextAccent = Color(0xFF06FFD9);

// 5. Border Effects
const Color kThemeBorderDefault = Color(0x2606FFD9); // rgba(6, 255, 217, 0.15)
const Color kThemeBorderFocus = Color(0x8006FFD9); // rgba(6, 255, 217, 0.5)

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
    colors: [kThemeNeonProfit, kThemeNeonInfo],
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
    color: Color(0x4D06FFD9), // rgba(6, 255, 217, 0.3)
    blurRadius: 20,
  );
  static const purple = BoxShadow(
    color: Color(0x4DB24BFF), // rgba(178, 75, 255, 0.3)
    blurRadius: 20,
  );
  static const profit = BoxShadow(
    color: Color(0x6600FF94), // rgba(0, 255, 148, 0.4)
    blurRadius: 15,
  );
}
