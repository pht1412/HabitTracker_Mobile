import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// 🔥 BỔ SUNG IMPORT NÀY ĐỂ SỬA LỖI USERMODEL
import '../models/user_model.dart';
import '../models/habit_model.dart';
import '../models/ai_history_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sử dụng getter để an toàn hơn
  String get userId => _auth.currentUser?.uid ?? '';

  // ==================================================
  // 1. QUẢN LÝ THÓI QUEN (HABITS)
  // ==================================================

  Stream<List<HabitModel>> getHabitsStream() {
    if (userId.isEmpty) return Stream.value([]);
    return _db
        .collection('habits')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => HabitModel.fromJson(doc.data(), doc.id))
        .toList());
  }

  Future<String> addHabit(String title, String description, {String? reminderTime}) async {
    if (userId.isEmpty) throw Exception("User not logged in");

    DocumentReference docRef = await _db.collection('habits').add({
      'userId': userId,
      'title': title,
      'description': description,
      'colorCode': 0xFF4CAF50,
      'completedDays': [],
      'createdAt': FieldValue.serverTimestamp(),
      'reminderTime': reminderTime,
    });
    return docRef.id;
  }

  Future<void> updateHabit(String habitId, String title, {String? reminderTime}) async {
    await _db.collection('habits').doc(habitId).update({
      'title': title,
      'reminderTime': reminderTime,
    });
  }

  Future<void> toggleHabitCompletion(HabitModel habit) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    List<DateTime> newCompletedDays = List.from(habit.completedDays);

    final index = newCompletedDays.indexWhere((date) =>
    date.year == today.year && date.month == today.month && date.day == today.day);

    if (index != -1) {
      newCompletedDays.removeAt(index);
    } else {
      newCompletedDays.add(today);
    }

    await _db.collection('habits').doc(habit.id).update({
      'completedDays': newCompletedDays,
    });
  }

  Future<void> deleteHabit(String habitId) async {
    await _db.collection('habits').doc(habitId).delete();
  }

  // ==================================================
  // 2. LỊCH SỬ AI (AI HISTORY)
  // ==================================================

  Future<void> saveAIHistory(String advice, String mood) async {
    if (userId.isNotEmpty) {
      await _db.collection('users').doc(userId).collection('ai_history').add({
        'advice': advice,
        'mood': mood,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<List<AIHistoryModel>> getAIHistoryStream() {
    if (userId.isNotEmpty) {
      return _db.collection('users').doc(userId).collection('ai_history')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => AIHistoryModel.fromJson(doc.data(), doc.id)).toList());
    }
    return Stream.value([]);
  }

  Future<void> clearAIHistory() async {
    if (userId.isNotEmpty) {
      final collection = _db.collection('users').doc(userId).collection('ai_history');
      var snapshots = await collection.get();
      WriteBatch batch = _db.batch();
      for (var doc in snapshots.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  // ==================================================
  // 3. QUẢN LÝ VIP (PREMIUM)
  // ==================================================

  Future<bool> getUserPremiumStatus() async {
    if (userId.isEmpty) return false;
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['isPremium'] ?? false;
      }
      return false;
    } catch (e) {
      // print("Lỗi lấy trạng thái VIP: $e");
      return false;
    }
  }

  Future<void> updateUserPremium(bool isPremium) async {
    if (userId.isEmpty) return;
    await _db.collection('users').doc(userId).set({
      'isPremium': isPremium,
      'premiumSince': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ==================================================
  // 4. QUẢN LÝ HỒ SƠ USER (PROFILE - REALTIME)
  // ==================================================

  // Lắng nghe thay đổi User realtime để cập nhật Avatar/Tên ngay lập tức
  Stream<UserModel?> getUserStream() {
    if (userId.isEmpty) return Stream.value(null);

    return _db.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        // 🔥 Bây giờ UserModel đã được import nên dòng này sẽ chạy ngon lành
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    });
  }

  Future<void> updateUserProfile({String? name, String? avatarUrl}) async {
    if (userId.isEmpty) return;

    Map<String, dynamic> dataToUpdate = {};
    if (name != null && name.isNotEmpty) dataToUpdate['name'] = name;
    if (avatarUrl != null && avatarUrl.isNotEmpty) dataToUpdate['avatar'] = avatarUrl;

    if (dataToUpdate.isNotEmpty) {
      await _db.collection('users').doc(userId).update(dataToUpdate);
    }
  }
  // ==================================================
  // 🔥 KHU VỰC DÀNH RIÊNG CHO ADMIN 🔥
  // ==================================================

  // 1. Lấy danh sách TOÀN BỘ User
  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _db.collection('users').get();
    return snapshot.docs.map((doc) => UserModel.fromJson(doc.data())).toList();
  }

  // 2. Lấy danh sách TOÀN BỘ Thói quen (Quét sạch hệ thống)
  Future<List<HabitModel>> getAllHabitsSystemWide() async {
    // collectionGroup giúp lấy tất cả sub-collection có tên là 'habits' bất kể user nào
    final snapshot = await _db.collectionGroup('habits').get();

    // Lưu ý: HabitModel của bạn cần xử lý việc map dữ liệu
    return snapshot.docs.map((doc) => HabitModel.fromJson(doc.data(), doc.id)).toList();
  }


  // ==================================================
  // ⛔️ KHU VỰC NGUY HIỂM: CHỈ DÙNG CHO ADMIN DEMO ⛔️
  // ==================================================

  // 🔥 HÀM XÓA SẠCH SÀNH SANH (NUKE BUTTON)
  // Sau khi quay video xong, hãy xóa hoặc comment hàm này lại!
  Future<void> nukeAllHabitsSystemWide() async {
    // 1. Lấy tất cả thói quen trong hệ thống (bất kể của user nào)
    // Lưu ý: Dùng collectionGroup nếu bạn lưu subcollection,
    // hoặc collection('habits') nếu lưu root. Dựa vào code cũ của bạn là root 'habits'.
    final snapshot = await _db.collection('habits').get();

    // 2. Tạo Batch để xóa hàng loạt (nhanh và an toàn hơn for loop)
    WriteBatch batch = _db.batch();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    // 3. Thực thi lệnh xóa
    await batch.commit();
  }







}