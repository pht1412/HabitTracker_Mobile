import 'package:flutter/material.dart';
import '../../controllers/ai_coach_controller.dart';
import '../../controllers/ai_analysis_helper.dart';
import '../../models/habit_model.dart';
import '../screens/ai_history_screen.dart';

class AICoachSheet extends StatefulWidget {
  final List<HabitModel> habits;

  const AICoachSheet({super.key, required this.habits});

  @override
  State<AICoachSheet> createState() => _AICoachSheetState();
}

class _AICoachSheetState extends State<AICoachSheet> {
  String? _advice;
  bool _isLoading = true;
  final AICoachController _controller = AICoachController();
  UserMood _selectedMood = UserMood.neutral;

  @override
  void initState() {
    super.initState();
    _getAdvice();
  }

  Future<void> _getAdvice() async {
    setState(() => _isLoading = true);
    final result = await _controller.askAICoach(
      widget.habits,
      mood: _selectedMood,
    );
    if (mounted) {
      setState(() {
        _advice = result;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          /// ===== HANDLE BAR =====
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          /// ===== HEADER: ICON + TITLE + HISTORY =====
          Row(
            children: [
              // Spacer trái để căn giữa title
              const SizedBox(width: 40),

              // Icon + Title (center)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      "AI Habit Coach",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              // Nút lịch sử (góc phải)
              IconButton(
                icon: const Icon(Icons.history, color: Colors.grey),
                tooltip: "Xem lịch sử",
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AIHistoryScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          /// ===== MOOD SELECTOR =====
          const Text(
            "Hôm nay bạn thế nào?",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMoodBtn(UserMood.happy, "😄", "Vui"),
              _buildMoodBtn(UserMood.neutral, "😐", "Thường"),
              _buildMoodBtn(UserMood.tired, "😫", "Mệt"),
              _buildMoodBtn(UserMood.lazy, "😴", "Lười"),
            ],
          ),

          const SizedBox(height: 24),

          /// ===== AI RESPONSE =====
          Expanded(
            child: _isLoading
                ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.purple),
                  SizedBox(height: 16),
                  Text(
                    "AI đang suy nghĩ...",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
                : Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.purple.withOpacity(0.1),
                ),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _advice ?? "Không có dữ liệu",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// ===== CLOSE BUTTON =====
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Đã hiểu!",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  /// ===== MOOD BUTTON =====
  Widget _buildMoodBtn(UserMood mood, String emoji, String label) {
    final bool isSelected = _selectedMood == mood;

    return GestureDetector(
      onTap: () {
        if (_selectedMood != mood) {
          setState(() => _selectedMood = mood);
          _getAdvice();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color:
          isSelected ? Colors.purple.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.purple
                : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.purple : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
