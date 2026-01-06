import 'package:flutter/material.dart';
import '../models/habit_model.dart';
import '../services/gemini_service.dart';
import '../services/notification_service.dart';
import 'ai_analysis_helper.dart'; // Đảm bảo đã có Enum UserMood ở đây
import '../services/firestore_service.dart';

class AICoachController {
  final GeminiService _geminiService = GeminiService();
  final NotificationService _notificationService = NotificationService();
  final FirestoreService _firestoreService = FirestoreService();


  // Thêm tham số mood (mặc định là neutral)
  Future<String?> askAICoach(List<HabitModel> habits, {UserMood mood = UserMood.neutral}) async {
    try {
      if (habits.isEmpty) {
        return "Bạn chưa có thói quen nào. Hãy tạo thói quen mới để tôi có thể hỗ trợ nhé!";
      }

      // 1. GỌI HELPER VỚI TÂM TRẠNG
      final analysisResult = AIAnalysisHelper.analyzeAndGenerateReport(
          habits,
          currentMood: mood // <--- Truyền mood vào đây
      );

      // 2. KÍCH HOẠT THÔNG BÁO (Adaptive Notification)
      if (analysisResult.notificationTitle != null && analysisResult.notificationBody != null) {
        debugPrint("🔔 AI Coach kích hoạt thông báo: ${analysisResult.notificationTitle}");

        await _notificationService.showInstantNotification(
          title: analysisResult.notificationTitle!,
          body: analysisResult.notificationBody!,
        );
      }

      // 3. TẠO PROMPT THÍCH ỨNG
      // Hướng dẫn Gemini thay đổi giọng điệu
      String toneInstruction = "thân thiện, bình thường";
      if (mood == UserMood.tired) toneInstruction = "nhẹ nhàng, thông cảm, khuyên nghỉ ngơi";
      if (mood == UserMood.lazy) toneInstruction = "nghiêm khắc, thúc giục, hài hước châm biếm";
      if (mood == UserMood.happy) toneInstruction = "hào hứng, ăn mừng";

      String prompt = """
      Bạn là AI Coach.
      Tâm trạng người dùng: ${mood.name} -> Hãy dùng giọng điệu: $toneInstruction.
      
      Dữ liệu phân tích:
      ----------------
      ${analysisResult.reportText}
      ----------------
      
      Nhiệm vụ:
      1. Đọc dữ liệu và tâm trạng.
      2. Đưa ra 1 lời khuyên ngắn gọn (dưới 60 từ) phù hợp nhất lúc này.
      """;

      debugPrint("📤 Đang gửi Prompt (Mood: ${mood.name})...");
      String? response = await _geminiService.testConnectionWithPrompt(prompt);

      if (response != null && !response.contains("Lỗi")) {
        await _firestoreService.saveAIHistory(response, mood.name);
        debugPrint("💾 Đã lưu lịch sử AI thành công!");
      }
      return response;

    } catch (e) {
      return "Lỗi phân tích: $e";
    }
  }
}