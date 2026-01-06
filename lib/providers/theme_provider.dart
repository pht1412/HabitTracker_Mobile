import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/theme_config.dart';

class ThemeProvider extends ChangeNotifier {
  // Trạng thái mặc định
  bool _isDarkMode = false;
  bool _isVipMode = false;

  bool get isDarkMode => _isDarkMode;
  bool get isVipMode => _isVipMode;

  // Constructor: Load cài đặt cũ khi mở App
  ThemeProvider() {
    _loadFromPrefs();
  }

  // 🔥 Logic chọn Theme: Trả về 1 trong 4 bộ theme đã định nghĩa
  ThemeData get currentTheme {
    if (_isVipMode) {
      return _isDarkMode ? AppTheme.vipDark : AppTheme.vipLight;
    } else {
      return _isDarkMode ? AppTheme.normalDark : AppTheme.normalLight;
    }
  }

  // Hàm bật/tắt Dark Mode
  void toggleTheme(bool isOn) {
    _isDarkMode = isOn;
    _saveToPrefs();
    notifyListeners(); // 📢 Báo cho toàn App vẽ lại giao diện
  }

  // Hàm bật/tắt VIP Mode (Nâng cấp/Hạ cấp)
  void toggleVip(bool isVip) {
    _isVipMode = isVip;
    _saveToPrefs();
    notifyListeners(); // 📢 Báo cho toàn App vẽ lại giao diện
  }

  // Lưu vào bộ nhớ máy
  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', _isDarkMode);
    prefs.setBool('isVipMode', _isVipMode);
  }

  // Đọc từ bộ nhớ máy
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _isVipMode = prefs.getBool('isVipMode') ?? false;
    notifyListeners();
  }
}