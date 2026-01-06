import 'package:home_widget/home_widget.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/habit_model.dart';
import 'firestore_service.dart';

const String androidWidgetProvider = 'HomeWidgetProvider';

class HomeWidgetService {

  // 1. CẬP NHẬT DỮ LIỆU LÊN WIDGET (Có thêm tham số isChecked)
  static Future<void> updateWidget(List<HabitModel> habits, {bool isChecked = false}) async {
    HabitModel? nextHabit;
    final todoHabits = habits.where((h) => !h.isCompletedToday()).toList();

    if (todoHabits.isNotEmpty) {
      nextHabit = todoHabits.first;
    }

    if (nextHabit != null) {
      await HomeWidget.saveWidgetData<String>('habit_title', nextHabit.title);
      await HomeWidget.saveWidgetData<String>('habit_time', nextHabit.reminderTime ?? "Hôm nay");
      await HomeWidget.saveWidgetData<String>('habit_id', nextHabit.id);
    } else {
      await HomeWidget.saveWidgetData<String>('habit_title', "Đã xong hết! 🎉");
      await HomeWidget.saveWidgetData<String>('habit_time', "");
      await HomeWidget.saveWidgetData<String>('habit_id', "");
    }

    // 🔥 MỚI: Lưu trạng thái check để Kotlin đọc
    await HomeWidget.saveWidgetData<bool>('is_checked', isChecked);

    await HomeWidget.updateWidget(
      name: androidWidgetProvider,
      androidName: androidWidgetProvider,
    );
  }

  static Future<void> initialize() async {
    await HomeWidget.registerInteractivityCallback(backgroundCallback);
  }
}

// 3. HÀM CHẠY NGẦM
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  if (uri?.host == 'btn_check') {
    await Firebase.initializeApp();
    final firestoreService = FirestoreService();

    // Lấy ID hiện tại để xử lý
    final habitId = await HomeWidget.getWidgetData<String>('habit_id');

    if (habitId != null && habitId.isNotEmpty) {
      // --- BƯỚC 1: PHẢN HỒI NGAY LẬP TỨC (HIỆN TÍCH XANH) ---
      // Ta giữ nguyên Title và Time cũ, chỉ đổi isChecked = true
      await HomeWidget.saveWidgetData<bool>('is_checked', true);
      await HomeWidget.updateWidget(
        name: androidWidgetProvider,
        androidName: androidWidgetProvider,
      );

      // --- BƯỚC 2: GỌI FIRESTORE (XỬ LÝ NGẦM) ---
      final habits = await firestoreService.getHabitsStream().first;
      try {
        final habit = habits.firstWhere((h) => h.id == habitId);
        await firestoreService.toggleHabitCompletion(habit);

        // --- BƯỚC 3: CẬP NHẬT THÓI QUEN MỚI (RESET TÍCH) ---
        // Lấy danh sách mới nhất sau khi đã check
        final updatedHabits = await firestoreService.getHabitsStream().first;
        // Gọi updateWidget chuẩn -> Nó sẽ tự lấy thói quen tiếp theo và set isChecked = false
        await HomeWidgetService.updateWidget(updatedHabits);

      } catch (e) {
        print("Lỗi check-in từ widget: $e");
        // Nếu lỗi, reset lại trạng thái check về false
        await HomeWidget.saveWidgetData<bool>('is_checked', false);
        await HomeWidget.updateWidget(
            name: androidWidgetProvider,
            androidName: androidWidgetProvider);
      }
    }
  }
}