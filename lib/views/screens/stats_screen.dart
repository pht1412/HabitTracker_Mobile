import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/stats_controller.dart';
import '../../models/habit_model.dart';
import '../../services/firestore_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final StatsController _statsController = StatsController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thống kê & Phân tích 📊"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: StreamBuilder<List<HabitModel>>(
        stream: _firestoreService.getHabitsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Chưa có dữ liệu để phân tích"));
          }

          final habits = snapshot.data!;
          final weeklyData = _statsController.calculateWeeklyProgress(habits);
          final completedToday = _statsController.countCompletedToday(habits);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Thẻ tổng quan
                _buildSummaryCard(completedToday, habits.length),

                const SizedBox(height: 30),

                // 2. Tiêu đề biểu đồ
                const Text(
                  "Hiệu suất 7 ngày qua",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // 3. Biểu đồ cột (Bar Chart)
                SizedBox(
                  height: 300,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: habits.length.toDouble() + 1, // Max trục Y = Tổng số thói quen + 1

                      // Ẩn các đường kẻ lưới, khung viền
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),

                      // Cấu hình trục
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              // Logic để hiện Thứ (T2, T3...)
                              final index = value.toInt();
                              final now = DateTime.now();
                              // Tính lùi ngày dựa trên index (Index 6 là hôm nay)
                              // Index: 0 1 2 3 4 5 6
                              // Ngày:  -6 -5 -4 -3 -2 -1 Today
                              final dayToShow = now.subtract(Duration(days: 6 - index));
                              final dayName = DateFormat('E', 'vi').format(dayToShow); // Cần setup locale VN sau

                              // Tạm thời dùng tiếng Anh: Mon, Tue... nếu chưa config locale
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  DateFormat('E').format(dayToShow),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // Dữ liệu cột
                      barGroups: weeklyData.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.toDouble(),
                              color: entry.value > 0 ? const Color(0xFF4CAF50) : Colors.grey[300],
                              width: 20,
                              borderRadius: BorderRadius.circular(4),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: habits.length.toDouble(), // Chiều cao tối đa (background xám)
                                color: Colors.grey[200],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
    );
  }

  Widget _buildSummaryCard(int done, int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Hôm nay", style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                "${((done / (total == 0 ? 1 : total)) * 100).toStringAsFixed(0)}%",
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 30),
          )
        ],
      ),
    );
  }
}