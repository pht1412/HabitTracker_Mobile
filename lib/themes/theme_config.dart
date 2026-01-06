// ✅ Dùng 'as material' để trỏ đúng thư viện gốc
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';

class AppTheme {
  // ==================================================
  // 🔹 1. THEME MODERN (NGƯỜI DÙNG THƯỜNG) - GREEN EDITION 🌿
  // ==================================================

  // Bảng màu Xanh chủ đạo (Lấy từ Logo/Login Screen)
  static const Color _greenPrimary = Color(0xFF66BB6A); // Xanh lá tươi
  static const Color _greenDark = Color(0xFF43A047);    // Xanh đậm hơn
  static const Color _greenBackground = Color(0xFFF1F8E9); // Xanh mint cực nhạt

  static final material.ThemeData normalLight = material.ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: _greenPrimary,
    scaffoldBackgroundColor: _greenBackground,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(
      seedColor: _greenPrimary,
      brightness: Brightness.light,
      surface: Colors.white,
      primary: _greenPrimary,
      secondary: _greenDark,
    ),
    cardTheme: const material.CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
    ).copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    appBarTheme: const material.AppBarTheme(
      backgroundColor: _greenBackground,
      foregroundColor: Color(0xFF1B5E20), // Chữ màu xanh rêu đậm cho dễ đọc
      elevation: 0,
      centerTitle: false,
    ),
  );

  static final material.ThemeData normalDark = material.ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: const Color(0xFFA5D6A7), // Xanh nhạt cho Dark Mode
    scaffoldBackgroundColor: const Color(0xFF1B5E20), // Xanh rêu tối
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFA5D6A7),
      brightness: Brightness.dark,
      surface: const Color(0xFF2E7D32),
    ),
    cardTheme: const material.CardThemeData(
      elevation: 0,
      color: Color(0xFF2E7D32),
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
    ).copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    appBarTheme: const material.AppBarTheme(
      backgroundColor: Color(0xFF1B5E20),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
  );

  // ==================================================
  // 👑 2. THEME LUXURY (VIP) - GIỮ NGUYÊN VÀNG
  // ==================================================
  // Phong cách: Gradient, Glow, Sang trọng (Không đổi để giữ phân cấp)

  static final material.ThemeData vipLight = material.ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: const Color(0xFFD4AF37),
    scaffoldBackgroundColor: const Color(0xFFFFFBF0), // Kem sữa
    fontFamily: 'Serif',
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFD4AF37),
      secondary: Color(0xFFB8860B),
      surface: Colors.white,
    ),
    cardTheme: material.CardThemeData(
      elevation: 10,
      shadowColor: const Color(0xFFD4AF37).withOpacity(0.2),
      color: Colors.white,
    ).copyWith(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFD4AF37), width: 0.5),
      ),
    ),
    appBarTheme: const material.AppBarTheme(
      backgroundColor: Color(0xFFFFFBF0),
      foregroundColor: Color(0xFF5D4037),
      elevation: 0,
    ),
  );

  static final material.ThemeData vipDark = material.ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: const Color(0xFFFFD700),
    scaffoldBackgroundColor: Colors.black,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFFD700),
      secondary: Color(0xFFFFA000),
      surface: Color(0xFF1C1C1E),
    ),
    cardTheme: material.CardThemeData(
      elevation: 15,
      shadowColor: const Color(0xFFFFD700).withOpacity(0.3),
      color: const Color(0xFF1C1C1E),
    ).copyWith(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFFFD700), width: 0.5),
      ),
    ),
    appBarTheme: const material.AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Color(0xFFFFD700),
      elevation: 0,
    ),
  );
}