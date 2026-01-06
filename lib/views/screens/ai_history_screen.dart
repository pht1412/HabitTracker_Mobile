import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/ai_history_model.dart';
import '../../services/firestore_service.dart';

class AIHistoryScreen extends StatelessWidget {
  const AIHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Lịch sử tư vấn 🧠", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        // --- THÊM NÚT XÓA Ở ĐÂY ---
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: "Xóa lịch sử",
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: StreamBuilder<List<AIHistoryModel>>(
        stream: FirestoreService().getAIHistoryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("Chưa có lịch sử tư vấn nào", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final historyList = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              final item = historyList[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildMoodBadge(item.mood),
                          const Spacer(),
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt),
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.advice,
                        style: const TextStyle(fontSize: 15, height: 1.4),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Hàm hiển thị hộp thoại xác nhận xóa
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa tất cả?"),
        content: const Text("Bạn có chắc muốn xóa toàn bộ lịch sử tư vấn không? Hành động này không thể hoàn tác."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx); // Đóng hộp thoại

              // Gọi hàm xóa
              await FirestoreService().clearAIHistory();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Đã dọn dẹp lịch sử! 🗑️")),
                );
              }
            },
            child: const Text("Xóa ngay"),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodBadge(String mood) {
    String emoji = "😐";
    Color color = Colors.grey;
    String text = "Thường";

    if (mood == 'happy') { emoji = "😄"; color = Colors.green; text = "Vui"; }
    if (mood == 'tired') { emoji = "😫"; color = Colors.orange; text = "Mệt"; }
    if (mood == 'lazy')  { emoji = "😴"; color = Colors.purple; text = "Lười"; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(emoji),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}