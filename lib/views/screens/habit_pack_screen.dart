import 'package:flutter/material.dart';
import '../../models/habit_pack_model.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';

class HabitPackScreen extends StatefulWidget {
  const HabitPackScreen({super.key});

  @override
  State<HabitPackScreen> createState() => _HabitPackScreenState();
}

class _HabitPackScreenState extends State<HabitPackScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  bool _isUserPremium = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    bool status = await _firestoreService.getUserPremiumStatus();
    if (mounted) {
      setState(() {
        _isUserPremium = status;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final packs = HabitPack.getSamplePacks();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Thư viện Lộ trình 🏆", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          if (_isUserPremium)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text("PRO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            )
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: packs.length,
        itemBuilder: (context, index) {
          final pack = packs[index];
          final isLocked = pack.isPremium && !_isUserPremium;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: pack.isPremium
                  ? const BorderSide(color: Colors.amber, width: 2)
                  : BorderSide.none,
            ),
            // Gói thường dùng màu xanh lá cực nhạt
            color: pack.isPremium ? Colors.amber[50] : Colors.green[50],
            elevation: 2,
            child: InkWell(
              onTap: () {
                if (isLocked) {
                  _showPaywall(context);
                } else {
                  _showPackDetail(context, pack);
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 60, height: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: pack.isPremium ? Colors.amber[100] : const Color(0xFF66BB6A).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(pack.emoji, style: const TextStyle(fontSize: 30)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                pack.name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 6),
                              if (pack.isPremium)
                                const Icon(Icons.workspace_premium, color: Colors.amber, size: 20),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pack.description,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: pack.isPremium ? Colors.amber[200] : const Color(0xFFC8E6C9),
                                borderRadius: BorderRadius.circular(8)
                            ),
                            child: Text(
                              "${pack.habits.length} thói quen",
                              style: TextStyle(
                                  color: pack.isPremium ? Colors.brown : Colors.green[900],
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Icon(
                        isLocked ? Icons.lock : Icons.arrow_forward_ios,
                        size: 20,
                        color: isLocked ? Colors.red : Colors.grey
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- MÀN HÌNH PAYWALL VÀ CHI TIẾT (GIỮ NGUYÊN LOGIC, CHỈ SỬA THEME) ---
  void _showPaywall(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 30),

              const Icon(Icons.diamond, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 20),

              const Text("Mở khóa Habit Pro 🚀", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text(
                "Đầu tư cho bản thân là khoản đầu tư siêu lợi nhuận.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 30),

              _buildBenefitItem(Icons.check_circle, "Mở khóa gói CEO, 75 Hard, Monk Mode"),
              _buildBenefitItem(Icons.check_circle, "AI Coach không giới hạn"),
              _buildBenefitItem(Icons.check_circle, "Tắt toàn bộ quảng cáo"),

              const Spacer(),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Gói Hàng Tháng", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("29.000đ / tháng", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)));
                    await Future.delayed(const Duration(seconds: 2));
                    await _firestoreService.updateUserPremium(true);
                    if (mounted) {
                      setState(() {
                        _isUserPremium = true;
                      });
                    }
                    if (context.mounted) Navigator.pop(context);
                    if (context.mounted) Navigator.pop(context);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Chúc mừng! Bạn đã là thành viên VIP! 💎"), backgroundColor: Colors.amber),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                  ),
                  child: const Text("ĐĂNG KÝ NGAY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 10),
              const Text("Hủy bất kỳ lúc nào.", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showPackDetail(BuildContext context, HabitPack pack) {
    TimeOfDay startTime = const TimeOfDay(hour: 7, minute: 0);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(pack.emoji, style: const TextStyle(fontSize: 40)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pack.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            Text("Bởi Chuyên gia AI", style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text("Bạn muốn bắt đầu lúc mấy giờ?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: startTime);
                      if (picked != null) {
                        setStateSheet(() => startTime = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.green.withOpacity(0.05),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Giờ bắt đầu:", style: TextStyle(fontSize: 16)),
                          Text(
                            startTime.format(context),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text("Lộ trình chi tiết:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.separated(
                      itemCount: pack.habits.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final habit = pack.habits[index];
                        final habitTime = _calculateTime(startTime, habit.offsetMinutes);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 30, height: 30,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(color: Colors.black12, shape: BoxShape.circle),
                            child: Text("${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          title: Text(habit.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                          trailing: Text(
                            habitTime.format(context),
                            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _applyPack(context, pack, startTime),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Áp dụng lộ trình này ngay! 🚀", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  TimeOfDay _calculateTime(TimeOfDay start, int offsetMinutes) {
    int totalMinutes = start.hour * 60 + start.minute + offsetMinutes;
    int hour = (totalMinutes ~/ 60) % 24;
    int minute = totalMinutes % 60;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _applyPack(BuildContext context, HabitPack pack, TimeOfDay startTime) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    final firestore = FirestoreService();
    final noti = NotificationService();
    try {
      for (var habit in pack.habits) {
        final reminderTime = _calculateTime(startTime, habit.offsetMinutes);
        final reminderString = "${reminderTime.hour}:${reminderTime.minute}";
        String newId = await firestore.addHabit(habit.title, "Gói: ${pack.name}", reminderTime: reminderString);
        await noti.scheduleDailyNotification(id: noti.createUniqueId(newId), title: "Đến giờ rồi: ${habit.title}", body: "Theo lộ trình ${pack.name} 💪", time: reminderTime);
      }
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã thêm gói '${pack.name}' thành công! 🎉")));
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      debugPrint("Lỗi thêm gói: $e");
    }
  }
}