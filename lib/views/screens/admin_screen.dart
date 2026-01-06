import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../models/habit_model.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;

  List<UserModel> _users = [];
  List<HabitModel> _allHabits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _firestoreService.getAllUsers(),
        _firestoreService.getAllHabitsSystemWide(),
      ]);

      if (mounted) {
        setState(() {
          _users = results[0] as List<UserModel>;
          _allHabits = results[1] as List<HabitModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Lỗi Admin Data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- HÀM XÓA DỮ LIỆU (NUKE) ---
  void _confirmNuke(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("⚠️ CẢNH BÁO CẤP ĐỘ ĐỎ"),
        content: const Text(
          "Bạn đang kích hoạt lệnh xóa TOÀN BỘ THÓI QUEN của TẤT CẢ NGƯỜI DÙNG.\n\nBạn có chắc chắn không?",
          style: TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.red)));
              try {
                await _firestoreService.nukeAllHabitsSystemWide();
                if (mounted) {
                  Navigator.pop(context);
                  _loadAdminData();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("💥 Đã xóa sạch toàn bộ thói quen!")));
                }
              } catch (e) {
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("XÁC NHẬN XÓA"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Admin Dashboard 🛡️", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.green), onPressed: _loadAdminData),
          // IconButton(
          //     tooltip: "Xóa toàn bộ dữ liệu (Demo)",
          //     icon: const Icon(Icons.delete_forever, color: Colors.red),
          //     onPressed: () => _confirmNuke(context)
          // ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () async { await FirebaseAuth.instance.signOut(); },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryColor,
          tabs: const [
            Tab(text: "Tổng Quan", icon: Icon(Icons.dashboard_customize)),
            Tab(text: "Quản Lý User", icon: Icon(Icons.group)),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          _buildUserListTab(),
        ],
      ),
    );
  }

  // 🔥 TAB 1: DASHBOARD (ĐÃ LOẠI BỎ THẺ "HÔM NAY", GIỮ DOANH THU)
  Widget _buildDashboardTab() {
    final premiumUsers = _users.where((u) => u.isPremium).length;
    final totalRevenue = premiumUsers * 29000;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSummaryCard("Tổng Người Dùng", "${_users.length}", Icons.people, Colors.blue),
          const SizedBox(height: 16),
          _buildSummaryCard("Tổng Thói Quen", "${_allHabits.length}", Icons.check_circle, Colors.green),
          const SizedBox(height: 16),
          _buildSummaryCard("User VIP", "$premiumUsers", Icons.diamond, Colors.amber),
          const SizedBox(height: 16),
          _buildSummaryCard("Doanh Thu (Est)", "${_formatCurrency(totalRevenue)}đ", Icons.monetization_on, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
            ],
          ),
        ],
      ),
    );
  }

  // 🔥 TAB 2: CHI TIẾT USER (ĐÃ CẬP NHẬT LOGIC HIỂN THỊ)
  Widget _buildUserListTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final userHabits = _allHabits.where((h) => h.userId == user.id).toList();

        // 1. Đã xong hôm nay (Kiểm tra thực tế ngày hôm nay)
        final completedToday = userHabits.where((h) => h.isCompletedToday()).length;

        // 2. Đang thắp (Logic Streak cũ: Có chuỗi liên tiếp > 0)
        final onStreakCount = userHabits.where((h) => h.currentStreak > 0).length;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: user.isPremium ? Colors.amber[100] : Colors.green[50],
              backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
              child: user.avatar == null
                  ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : "U",
                  style: TextStyle(color: user.isPremium ? Colors.amber[800] : Colors.green[800]))
                  : null,
            ),
            title: Row(
              children: [
                Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                if (user.role == 'admin')
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                    child: const Text("ADMIN", style: TextStyle(color: Colors.white, fontSize: 10)),
                  )
              ],
            ),
            subtitle: Text(user.email, style: const TextStyle(fontSize: 12)),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Cột 1: Tổng thói quen
                    _buildDetailStat("Tổng Habit", "${userHabits.length}", Colors.black87),

                    // Cột 2: Làm xong hôm nay (Real-time Audit)
                    _buildDetailStat("Xong hôm nay", "$completedToday", Colors.green),

                    // Cột 3: Đang thắp lửa (Logic Streak cũ - thay thế "Chưa xong")
                    _buildDetailStat("🔥 Đang cháy", "$onStreakCount", Colors.orange),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}