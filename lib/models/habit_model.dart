import 'package:cloud_firestore/cloud_firestore.dart';

class HabitModel {
  String id;
  String userId;
  String title;
  String description;
  int colorCode; // Lưu màu dưới dạng số nguyên (VD: 0xFF4CAF50)
  List<DateTime> completedDays; // Danh sách các ngày đã hoàn thành
  DateTime createdAt;
  String? reminderTime;

  HabitModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.colorCode = 0xFF2196F3, // Mặc định màu xanh dương
    this.completedDays = const [],
    required this.createdAt,
    this.reminderTime,
  });

  // Chuyển từ JSON (Firestore) -> Object Dart
  factory HabitModel.fromJson(Map<String, dynamic> json, String docId) {
    return HabitModel(
      id: docId,
      userId: json['userId'] ?? '',
      title: json['title'] ?? 'Không tên',
      description: json['description'] ?? '',
      colorCode: json['colorCode'] ?? 0xFF2196F3,
      // Xử lý mảng ngày tháng từ Firestore
      completedDays: (json['completedDays'] as List<dynamic>?)
          ?.map((e) => (e as Timestamp).toDate())
          .toList() ??
          [],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      reminderTime: json['reminderTime'],
    );
  }

  // Chuyển từ Object Dart -> JSON (để bắn lên Firestore)
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'colorCode': colorCode,
      'completedDays': completedDays, // Firestore tự hiểu List<DateTime>
      'createdAt': createdAt,
      'reminderTime': reminderTime,
    };
  }

  // Kiểm tra xem HÔM NAY đã làm chưa?
  bool isCompletedToday() {
    final now = DateTime.now();
    return completedDays.any((date) =>
    date.year == now.year &&
        date.month == now.month &&
        date.day == now.day);
  }

// ... (Giữ nguyên code cũ của HabitModel)

// --- LOGIC TÍNH STREAK (Thêm vào cuối class HabitModel) ---

// 1. Tính chuỗi hiện tại (Current Streak)
  int get currentStreak {
    if (completedDays.isEmpty) return 0;

    // Sắp xếp ngày từ mới nhất -> cũ nhất
    final sortedDays = List<DateTime>.from(completedDays)
      ..sort((a, b) => b.compareTo(a));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Nếu ngày gần nhất không phải hôm nay hoặc hôm qua -> Mất chuỗi
    final lastCompleted = DateTime(
        sortedDays.first.year, sortedDays.first.month, sortedDays.first.day);

    if (lastCompleted != today && lastCompleted != yesterday) {
      return 0;
    }

    int streak = 0;
    // Duyệt ngược từ ngày gần nhất
    for (int i = 0; i < sortedDays.length; i++) {
      final date = DateTime(
          sortedDays[i].year, sortedDays[i].month, sortedDays[i].day);

      // Ngày đầu tiên (Anchor)
      if (i == 0) {
        streak++;
        continue;
      }

      final prevDate = DateTime(
          sortedDays[i - 1].year, sortedDays[i - 1].month,
          sortedDays[i - 1].day);

      // Nếu ngày này cách ngày trước đúng 1 ngày -> +1 Streak
      if (prevDate
          .difference(date)
          .inDays == 1) {
        streak++;
      } else {
        // Nếu ngắt quãng -> Dừng đếm
        break;
      }
    }
    return streak;
  }

// 2. Tính dữ liệu cho biểu đồ tuần (Weekly Progress)
// Trả về Map: {Thứ 2: true, Thứ 3: false...}
  Map<int, bool> getLast7DaysCompletion() {
    final Map<int, bool> result = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Duyệt 7 ngày gần nhất (từ hôm nay lùi về)
    for (int i = 0; i < 7; i++) {
      final checkDate = today.subtract(Duration(days: i));

      // Kiểm tra ngày này có trong danh sách completedDays không
      bool isDone = completedDays.any((d) =>
      d.year == checkDate.year &&
          d.month == checkDate.month &&
          d.day == checkDate.day);

      // Key là weekday (1 = Thứ 2, 7 = CN)
      result[checkDate.weekday] = isDone;
    }
    return result;
  }
}
// ...