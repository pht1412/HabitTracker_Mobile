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

  // 🔥 1. CHỈNH MÀU BIỂU ĐỒ (CỘT)
  // Logic: Chân cột đậm (vững chãi), đỉnh cột nhạt (nhẹ nhàng)
  LinearGradient get _barGradient => const LinearGradient(
    colors: [
      Color(0xFF2E7D32), // Màu Xanh Đậm (Green 800) - Ở dưới đáy
      Color(0xFF66BB6A), // Màu Xanh Nhạt (Green 400) - Ở trên đỉnh
    ],
    stops: [0.2, 0.9], // Màu đậm chiếm 20% dưới, sau đó chuyển dần sang nhạt
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Phân Tích Hiệu Suất"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: StreamBuilder<List<HabitModel>>(
        stream: _firestoreService.getHabitsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final habits = snapshot.data!;
          final weeklyData = _statsController.calculateWeeklyProgress(habits);
          final completedToday = _statsController.countCompletedToday(habits);

          final totalHabits = habits.length;
          final completionRate = totalHabits == 0 ? 0.0 : (completedToday / totalHabits);
          final bestStreak = habits.isEmpty
              ? 0
              : habits.map((h) => h.currentStreak).reduce((curr, next) => curr > next ? curr : next);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                _buildOverviewCard(completionRate, completedToday, totalHabits),

                const SizedBox(height: 20),

                // Grid thống kê
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatItem(Icons.list_alt, "Tổng thói quen", "$totalHabits", Colors.teal),
                    _buildStatItem(Icons.check_circle_outline, "Đã xong", "$completedToday", Colors.green),
                    _buildStatItem(Icons.local_fire_department, "Streak tốt nhất", "$bestStreak ngày", Colors.orange),
                    _buildStatItem(Icons.percent, "Tỉ lệ hoàn thành", "${(completionRate * 100).toInt()}%", Colors.lightGreen),
                  ],
                ),

                const SizedBox(height: 30),

                Text(
                  "Biểu đồ 7 ngày qua",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
                const SizedBox(height: 20),

                // Container Biểu đồ
                Container(
                  height: 300,
                  padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: totalHabits.toDouble() + 1,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              final now = DateTime.now();
                              final dayToShow = now.subtract(Duration(days: 6 - index));
                              final dayName = DateFormat('E', 'vi').format(dayToShow);

                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  dayName,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).hintColor
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: weeklyData.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.toDouble(),
                              gradient: _barGradient, // ✅ Áp dụng Gradient mới
                              width: 16,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: totalHabits.toDouble(),
                                color: Colors.grey.withOpacity(0.1),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                if (habits.isNotEmpty) ...[
                  Text(
                    "🔥 Top Chuỗi (Streak)",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                  const SizedBox(height: 10),
                  _buildTopHabitsList(habits),
                ],
                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }

  // 🔥 2. CHỈNH MÀU CARD TIẾN ĐỘ (LEFT -> RIGHT)
  Widget _buildOverviewCard(double rate, int done, int total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // 👇 CẤU HÌNH GRADIENT CHI TIẾT TẠI ĐÂY
        gradient: const LinearGradient(
          colors: [
            Color(0xFF81C784), // Màu 1: Xanh lá mạ (Rất sáng) - Bên Trái
            Color(0xFF2E7D32), // Màu 2: Xanh rừng già (Rất đậm) - Bên Phải
          ],
          // Quy định điểm dừng (Percentage)
          stops: [0.0, 1.0], // 0% là màu sáng, 100% là màu đậm -> Chuyển màu toàn bộ chiều dài

          begin: Alignment.centerLeft,  // Bắt đầu từ mép trái giữa
          end: Alignment.centerRight,   // Kết thúc ở mép phải giữa
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          // Bóng đổ màu xanh đậm để tạo chiều sâu
          BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Hiệu suất hôm nay", style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                "${(rate * 100).toStringAsFixed(0)}%",
                style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Đã xong $done/$total việc",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Container(
            height: 80, width: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: Icon(
                rate == 1.0 ? Icons.emoji_events : Icons.analytics,
                color: Colors.white, size: 40
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
          Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
        ],
      ),
    );
  }

  Widget _buildTopHabitsList(List<HabitModel> habits) {
    final topHabits = List<HabitModel>.from(habits)
      ..sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
    final top3 = topHabits.take(3).toList();

    return Column(
      children: top3.map((habit) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withOpacity(0.1),
              child: const Icon(Icons.local_fire_department, color: Colors.orange),
            ),
            title: Text(habit.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(
              "${habit.currentStreak} ngày",
              style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text("Chưa có dữ liệu", style: TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }
}