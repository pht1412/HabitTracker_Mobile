import '../models/habit_model.dart';

// 1. Định nghĩa các loại tâm trạng
enum UserMood { happy, tired, lazy, neutral }

class AnalysisResult {
  final String reportText;
  final String? notificationTitle;
  final String? notificationBody;

  AnalysisResult(this.reportText, {this.notificationTitle, this.notificationBody});
}

class AIAnalysisHelper {
  static AnalysisResult analyzeAndGenerateReport(
      List<HabitModel> habits, {
        UserMood currentMood = UserMood.neutral, // Nhận tâm trạng từ UI
      }) {
    if (habits.isEmpty) return AnalysisResult("Người dùng chưa có thói quen nào.");

    StringBuffer report = StringBuffer();
    // Ghi tâm trạng vào báo cáo để Gemini biết đường ứng biến
    report.writeln("DỮ LIỆU THÓI QUEN (Tâm trạng hiện tại: ${currentMood.name}):");

    final now = DateTime.now();
    String? notiTitle;
    String? notiBody;

    for (var habit in habits) {
      // Logic tính toán cơ bản
      int totalDaysExists = now.difference(habit.createdAt).inDays + 1;
      if (totalDaysExists < 1) totalDaysExists = 1;
      int completedCount = habit.completedDays.length;
      double rate = (completedCount / totalDaysExists) * 100;

      // Logic tính ngày bỏ lỡ gần nhất (Recency)
      int daysSinceLastDone = 999;
      if (habit.completedDays.isNotEmpty) {
        // Sắp xếp ngày giảm dần để lấy ngày mới nhất
        habit.completedDays.sort((a, b) => b.compareTo(a));
        final lastDate = habit.completedDays.first;
        daysSinceLastDone = now.difference(lastDate).inDays;
      }

      // --- LOGIC PHÂN TÍCH THÍCH ỨNG (ADAPTIVE RULES) ---
      String status = "Bình thường";

      // RULE 1: ƯU TIÊN TÂM TRẠNG (Mood First)
      if (currentMood == UserMood.tired) {
        status = "🛌 User đang mệt, cần nghỉ ngơi";
        // Nếu user mệt, ghi đè thông báo thành lời động viên nhẹ nhàng
        if (notiTitle == null) {
          notiTitle = "🌱 Nghỉ ngơi nhé!";
          notiBody = "Sức khỏe quan trọng hơn Streak. Hãy thư giãn, mai ta làm lại!";
        }
      }
      else if (currentMood == UserMood.lazy) {
        // Nếu lười, AI cần "gắt" hơn
        if (daysSinceLastDone >= 1) {
          status = "💤 Đang lười biếng";
          notiTitle = "🚀 Đứng dậy ngay!";
          notiBody = "Đừng để sự lười biếng đánh bại chuỗi ${habit.currentStreak} ngày của bạn!";
        }
      }

      // RULE 2: LOGIC BỎ LỠ (Nếu tâm trạng bình thường)
      else {
        // Nếu đang cháy
        if (habit.currentStreak >= 3 && daysSinceLastDone == 0) {
          status = "🔥 Đang rất cháy";
          if (notiTitle == null) {
            notiTitle = "🔥 Tuyệt vời! ${habit.currentStreak} ngày";
            notiBody = "Giữ vững phong độ nhé!";
          }
        }
        // Nếu bỏ lỡ đúng 3 ngày (Thời điểm vàng để nhắc nhở)
        else if (daysSinceLastDone >= 3 && daysSinceLastDone < 7) {
          status = "⚠️ Bỏ lỡ $daysSinceLastDone ngày";
          notiTitle = "⚠️ Cứu lấy chuỗi của bạn!";
          notiBody = "Chỉ cần 1 lần check-in hôm nay để quay lại đường đua!";
        }
        // Nếu nguy cơ cao (Rate thấp)
        else if (rate < 30 && totalDaysExists > 3) {
          status = "⚠️ Nguy cơ bỏ cuộc (Rate: ${rate.toInt()}%)";
        }
      }

      report.writeln("- [${habit.title}]: $status (Bỏ lỡ: $daysSinceLastDone ngày)");
    }

    return AnalysisResult(
      report.toString(),
      notificationTitle: notiTitle,
      notificationBody: notiBody,
    );
  }
}