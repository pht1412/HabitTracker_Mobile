import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/firestore_service.dart'; // ✅ Import Firestore Service

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false; // Biến để hiện vòng xoay khi đang check

  // --- LOGIC XỬ LÝ KHI BẤM NÚT VIP ---
  Future<void> _handleVipToggle(bool value, ThemeProvider themeProvider) async {
    // 1. Nếu người dùng muốn TẮT VIP -> Cho tắt luôn, không cần hỏi
    if (!value) {
      themeProvider.toggleVip(false);
      return;
    }

    // 2. Nếu người dùng muốn BẬT VIP -> Phải kiểm tra thẻ bài
    setState(() => _isLoading = true); // Hiện Loading

    // Gọi Firestore kiểm tra xem user này có phải đại gia không?
    bool isPremium = await _firestoreService.getUserPremiumStatus();

    // Tắt Loading
    if (mounted) setState(() => _isLoading = false);

    if (isPremium) {
      // ✅ ĐÃ LÀ VIP: Cho phép bật
      themeProvider.toggleVip(true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("👑 Chào mừng VIP quay trở lại!")),
        );
      }
    } else {
      // ❌ CHƯA LÀ VIP: Hiện hộp thoại dụ dỗ mua hàng
      if (mounted) _showUpgradeDialog(themeProvider);
    }
  }

  // --- HỘP THOẠI NÂNG CẤP (DEMO CHO GIẢNG VIÊN XEM) ---
  void _showUpgradeDialog(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
        title: const Text("👑 Nâng cấp VIP"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Giao diện Gold Luxury chỉ dành cho thành viên VIP."),
            SizedBox(height: 10),
            Text("Nâng cấp ngay để mở khóa toàn bộ tính năng!", style: TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Để sau"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              Navigator.pop(ctx); // Đóng hộp thoại cũ
              _processDemoPayment(themeProvider); // Bắt đầu giả lập thanh toán
            },
            child: const Text("Nâng cấp ngay (Demo)"),
          )
        ],
      ),
    );
  }

  // --- GIẢ LẬP QUÁ TRÌNH THANH TOÁN ---
  Future<void> _processDemoPayment(ThemeProvider themeProvider) async {
    setState(() => _isLoading = true);

    // 1. Giả vờ đợi 1.5 giây (như đang thanh toán thật)
    await Future.delayed(const Duration(milliseconds: 1500));

    // 2. Ghi vào Firestore: User này giờ đã là VIP
    await _firestoreService.updateUserPremium(true);

    if (mounted) {
      setState(() => _isLoading = false);

      // 3. Tự động bật VIP lên luôn cho người dùng sướng
      themeProvider.toggleVip(true);

      // 4. Bắn pháo hoa ăn mừng (hoặc thông báo)
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("🎉 Thanh toán thành công!"),
          content: const Text("Cảm ơn bạn đã ủng hộ. Hãy tận hưởng giao diện VIP!"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Tuyệt vời"))
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isVip = themeProvider.isVipMode;

    return Scaffold(
      appBar: AppBar(title: const Text("Cài đặt & Giao diện")),
      // Nếu đang loading thì hiện vòng xoay đè lên màn hình
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // CARD 1: CÀI ĐẶT CHUNG
              Card(
                child: ListTile(
                  leading: Icon(themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode),
                  title: const Text("Chế độ Tối (Dark Mode)"),
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (val) => themeProvider.toggleTheme(val),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Text("GÓI THÀNH VIÊN", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),

              // CARD 2: KHU VỰC VIP (ĐIỂM NHẤN)
              Card(
                // Đổi màu nền card khi là VIP
                color: isVip
                    ? (themeProvider.isDarkMode ? Colors.amber[900] : Colors.amber[100])
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.workspace_premium, color: isVip ? Colors.amber : Colors.grey, size: 40),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isVip ? "THÀNH VIÊN VIP 👑" : "Thành viên Thường",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isVip ? (themeProvider.isDarkMode ? Colors.white : Colors.brown) : null
                                  ),
                                ),
                                Text(
                                  isVip ? "Đang tận hưởng giao diện Gold Luxury" : "Nâng cấp để mở khóa giao diện VIP",
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: const Text("Kích hoạt chế độ VIP"),
                        subtitle: const Text("Giao diện Thượng lưu"),
                        value: isVip,
                        activeColor: Colors.amber,
                        // 🔥 GỌI HÀM XỬ LÝ THÔNG MINH CỦA CHÚNG TA
                        onChanged: (val) => _handleVipToggle(val, themeProvider),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // LỚP LOADING (Hiện khi đang check server)
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.amber),
              ),
            ),
        ],
      ),
    );
  }
}