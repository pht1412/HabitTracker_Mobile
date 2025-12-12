import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/habit_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  // 1. LẤY DANH SÁCH (Realtime Stream)
  Stream<List<HabitModel>> getHabitsStream() {
    return _db
        .collection('habits')
        .where('userId', isEqualTo: userId) // Chỉ lấy của user hiện tại
        .orderBy('createdAt', descending: true) // Mới nhất lên đầu
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => HabitModel.fromJson(doc.data(), doc.id))
        .toList());
  }

  // 2. THÊM THÓI QUEN MỚI
  Future<void> addHabit(String title, String description) async {
    await _db.collection('habits').add({
      'userId': userId,
      'title': title,
      'description': description,
      'colorCode': 0xFF4CAF50, // Mặc định xanh lá
      'completedDays': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 3. CHECK-IN / UN-CHECK (Quan trọng!)
  Future<void> toggleHabitCompletion(HabitModel habit) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); // Lấy ngày không lấy giờ

    List<DateTime> newCompletedDays = List.from(habit.completedDays);

    // Kiểm tra xem trong list đã có ngày hôm nay chưa
    final index = newCompletedDays.indexWhere((date) =>
    date.year == today.year &&
        date.month == today.month &&
        date.day == today.day);

    if (index != -1) {
      // Nếu có rồi -> Bỏ đi (Uncheck)
      newCompletedDays.removeAt(index);
    } else {
      // Nếu chưa có -> Thêm vào (Check)
      newCompletedDays.add(today);
    }

    await _db.collection('habits').doc(habit.id).update({
      'completedDays': newCompletedDays,
    });
  }

  // 4. XÓA
  Future<void> deleteHabit(String habitId) async {
    await _db.collection('habits').doc(habitId).delete();
  }
}