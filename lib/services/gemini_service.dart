import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  // API KEY CỦA BẠN
  static const String _apiKey = 'AIzaSyAIV9Y9paZXeknDspqIFT7pMrXezmqIbfg';

  late final GenerativeModel _model;

  void init() {
    try {
      // ✅ QUAY VỀ MODEL 1.5 FLASH (Ổn định nhất)
      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
      );
      debugPrint("✅ Gemini Service Initialized ");
    } catch (e) {
      debugPrint("❌ Lỗi khởi tạo Gemini: $e");
    }
  }

  Future<String?> testConnectionWithPrompt(String prompt) async {
    try {
      debugPrint("📡 Đang gọi Google Gemini...");
      final content = [Content.text(prompt)];

      final response = await _model.generateContent(content);

      // Kiểm tra nếu response rỗng
      if (response.text == null || response.text!.isEmpty) {
        return "AI đang suy nghĩ... Hãy thử lại sau chút nhé!";
      }

      debugPrint("🤖 Gemini trả lời: ${response.text}");
      return response.text;

    } catch (e) {
      debugPrint("❌ Lỗi kết nối AI: $e");

      // ✅ XỬ LÝ LỖI THÂN THIỆN VỚI NGƯỜI DÙNG
      // Thay vì in nguyên lỗi tiếng Anh, ta trả về thông báo dễ hiểu
      if (e.toString().contains("503") || e.toString().contains("overloaded")) {
        return "Server AI đang quá tải 🤯\nBạn chờ 1 lát rồi thử lại nhé!";
      }

      return "Không thể kết nối với AI lúc này.\nVui lòng kiểm tra mạng.";
    }
  }
}