import 'package:cloud_firestore/cloud_firestore.dart';

class AIHistoryModel {
  final String id;
  final String advice;      // Lời khuyên của AI
  final String mood;        // Tâm trạng lúc hỏi (Vui, Buồn...)
  final DateTime createdAt; // Thời gian hỏi

  AIHistoryModel({
    required this.id,
    required this.advice,
    required this.mood,
    required this.createdAt,
  });

  // Chuyển từ JSON (Firestore) sang Object
  factory AIHistoryModel.fromJson(Map<String, dynamic> json, String id) {
    return AIHistoryModel(
      id: id,
      advice: json['advice'] ?? '',
      mood: json['mood'] ?? 'neutral',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  // Chuyển từ Object sang JSON (để lưu lên Firestore)
  Map<String, dynamic> toJson() {
    return {
      'advice': advice,
      'mood': mood,
      'createdAt': createdAt,
    };
  }
}