import '../models/habit_model.dart';

class StatsController {
  // Hàm tính toán dữ liệu cho 7 ngày gần nhất
  // Trả về: List<int> chứa số lượng thói quen hoàn thành mỗi ngày
  // [2, 0, 5, 3, ...] (Tương ứng 7 ngày từ quá khứ -> hôm nay)
  List<int> calculateWeeklyProgress(List<HabitModel> habits) {
    List<int> weeklyData = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Duyệt từ 6 ngày trước đến hôm nay (Tổng 7 ngày)
    for (int i = 6; i >= 0; i--) {
      final dateToCheck = today.subtract(Duration(days: i));
      int count = 0;

      for (var habit in habits) {
        // Kiểm tra xem thói quen này có hoàn thành vào ngày dateToCheck không
        bool isCompleted = habit.completedDays.any((d) =>
        d.year == dateToCheck.year &&
            d.month == dateToCheck.month &&
            d.day == dateToCheck.day);

        if (isCompleted) {
          count++;
        }
      }
      weeklyData.add(count);
    }
    return weeklyData;
  }

  // Đếm tổng số thói quen hoàn thành trong ngày hôm nay
  int countCompletedToday(List<HabitModel> habits) {
    return habits.where((h) => h.isCompletedToday()).length;
  }
}