import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../models/habit_model.dart';
import '../../services/firestore_service.dart';
import 'auth/login_screen.dart';
import './stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();



  // Hàm hiện hộp thoại thêm nhanh
  void _showAddHabitDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Thói quen mới 🌱"),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(hintText: "Ví dụ: Uống nước, Chạy bộ..."),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                _firestoreService.addHabit(textController.text, "Mô tả ngắn");
                Navigator.pop(context);
              }
            },
            child: const Text("Thêm"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lấy user hiện tại để chào
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100], // Màu nền nhẹ
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Hôm nay", style: TextStyle(fontSize: 14, color: Colors.grey)),
            Text("Chào, ${user?.displayName ?? 'Bạn'} 👋",
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          // Nút mở màn hình thống kê
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: "Thống kê",
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StatsScreen())
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // Quay về màn hình Login
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),

      body: StreamBuilder<List<HabitModel>>(
        stream: _firestoreService.getHabitsStream(),
        builder: (context, snapshot) {
          // 1. Đang tải
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Có lỗi
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }

          // 3. Không có dữ liệu
          final habits = snapshot.data ?? [];
          if (habits.isEmpty) {
            return const Center(
              child: Text("Chưa có thói quen nào.\nBấm + để tạo ngay!",
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            );
          }

          // 4. Có dữ liệu -> Hiển thị list
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final habit = habits[index];
              final isDone = habit.isCompletedToday();

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

                  // Icon trạng thái (Check box)
                  leading: GestureDetector(
                    onTap: () => _firestoreService.toggleHabitCompletion(habit),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDone ? Colors.green : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDone ? Colors.green : Colors.grey, width: 2),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: isDone
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : const SizedBox(width: 20, height: 20), // Placeholder
                    ),
                  ),

                  // Tên thói quen
                  title: Text(
                    habit.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone ? Colors.grey : Colors.black,
                    ),
                  ),

                  // Streak (Tạm thời hiện số ngày đã làm)
                  // Thay thế toàn bộ dòng subtitle cũ bằng đoạn này:
                  subtitle: Row(
                    children: [
                      // 1. Icon ngọn lửa (Màu cam nếu có chuỗi, màu xám nếu mất chuỗi)
                      Icon(
                          Icons.local_fire_department,
                          color: habit.currentStreak > 0 ? Colors.orange : Colors.grey,
                          size: 20
                      ),
                      const SizedBox(width: 4),

                      // 2. Text hiển thị số ngày
                      Text(
                        "${habit.currentStreak} ngày liên tiếp", // Gọi getter .currentStreak đã viết trong Model
                        style: TextStyle(
                          color: habit.currentStreak > 0 ? Colors.orange : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // Nút xóa (Icon thùng rác)
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _firestoreService.deleteHabit(habit.id),
                  ),
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddHabitDialog,
        label: const Text("Thói quen mới"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
    );
  }
}