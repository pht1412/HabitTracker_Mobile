import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';

import '../../models/habit_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../services/home_widget_service.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import '../widgets/ai_coach_sheet.dart';
import 'habit_pack_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  // --- BIẾN QUẢN LÝ ---
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  late ConfettiController _confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  late Stream<List<HabitModel>> _habitsStream;
  late Stream<UserModel?> _userStream;

  @override
  void initState() {
    super.initState();
    NotificationService().requestPermissions();
    HomeWidgetService.initialize();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));

    _habitsStream = _firestoreService.getHabitsStream();
    _userStream = _firestoreService.getUserStream();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _handleCheckIn(HabitModel habit) async {
    final isDone = habit.isCompletedToday();
    if (!isDone) {
      try {
        await _audioPlayer.play(AssetSource('sounds/success.mp3'));
      } catch (e) {
        debugPrint("Lỗi âm thanh: $e");
      }
      _confettiController.play();
    }
    _firestoreService.toggleHabitCompletion(habit);
  }

  void _showHabitDialog({HabitModel? habit}) {
    _buildFullDialogCode(habit);
  }

  // --- HÀM DIALOG CHỈNH SỬA / THÊM MỚI ---
  void _buildFullDialogCode(HabitModel? habit) {
    final isEditing = habit != null;
    final textController = TextEditingController(text: isEditing ? habit.title : '');
    TimeOfDay? selectedTime;
    bool isReminderOn = false;

    if (isEditing && habit.reminderTime != null) {
      isReminderOn = true;
      try {
        final parts = habit.reminderTime!.split(':');
        selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (e) {
        isReminderOn = false;
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(isEditing ? Icons.edit_note : Icons.eco, color: Theme.of(context).primaryColor),
                const SizedBox(width: 10),
                Text(isEditing ? "Sửa thói quen" : "Thói quen mới"),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textController,
                  decoration: InputDecoration(
                    hintText: "Ví dụ: Đọc sách 30p...",
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 20),

                // Toggle Nhắc nhở
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isReminderOn ? const Color(0xFF66BB6A).withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isReminderOn ? const Color(0xFF66BB6A) : Colors.grey.shade300
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active, color: isReminderOn ? const Color(0xFF43A047) : Colors.grey),
                      const SizedBox(width: 8),
                      const Text("Nhắc nhở", style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Switch(
                        value: isReminderOn,
                        activeColor: const Color(0xFF43A047),
                        onChanged: (val) => setStateDialog(() {
                          isReminderOn = val;
                          if (val && selectedTime == null) selectedTime = const TimeOfDay(hour: 7, minute: 0);
                        }),
                      ),
                    ],
                  ),
                ),

                if (isReminderOn && selectedTime != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: selectedTime!);
                        if (picked != null) setStateDialog(() => selectedTime = picked);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "⏰ ${selectedTime!.format(context)}",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                          ),
                          const SizedBox(width: 5),
                          const Icon(Icons.edit, size: 14, color: Color(0xFF2E7D32)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  if (textController.text.isNotEmpty) {
                    String? reminderString;
                    if (isReminderOn && selectedTime != null) {
                      final hour = selectedTime!.hour.toString().padLeft(2, '0');
                      final minute = selectedTime!.minute.toString().padLeft(2, '0');
                      reminderString = "$hour:$minute";
                    }

                    if (isEditing) {
                      await _firestoreService.updateHabit(habit!.id, textController.text, reminderTime: reminderString);
                      final notiId = NotificationService().createUniqueId(habit.id);
                      await NotificationService().cancelNotification(notiId);

                      if (isReminderOn && selectedTime != null) {
                        await NotificationService().scheduleDailyNotification(
                            id: notiId,
                            title: "🔔 Nhắc nhở thói quen",
                            body: "Bạn đã quên '${textController.text}', hãy làm ngay đi trước khi quá muộn!",
                            time: selectedTime!
                        );
                      }
                    } else {
                      String newId = await _firestoreService.addHabit(textController.text, "Mô tả...", reminderTime: reminderString);
                      if (isReminderOn && selectedTime != null) {
                        await NotificationService().scheduleDailyNotification(
                            id: NotificationService().createUniqueId(newId),
                            title: "🔔 Nhắc nhở thói quen",
                            body: "Bạn đã quên '${textController.text}', hãy làm ngay đi trước khi quá muộn!",
                            time: selectedTime!
                        );
                      }
                    }
                    if (mounted) Navigator.pop(context);
                  }
                },
                child: Text(isEditing ? "Cập nhật" : "Lưu"),
              ),
            ],
          );
        });
      },
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      IconButton(
        icon: Icon(_isSearching ? Icons.search_off : Icons.search),
        onPressed: () => setState(() {
          _isSearching = !_isSearching;
          if (!_isSearching) {
            _searchQuery = "";
            _searchController.clear();
          }
        }),
      ),
      IconButton(
        icon: const Icon(Icons.auto_awesome, color: Colors.purple),
        onPressed: () async {
          final snapshot = await _firestoreService.getHabitsStream().first;
          if (context.mounted) {
            showModalBottomSheet(context: context, isScrollControlled: true,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                builder: (context) => AICoachSheet(habits: snapshot));
          }
        },
      ),
      IconButton(
        icon: const Icon(Icons.bar_chart),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen())),
      ),
      IconButton(
        icon: const Icon(Icons.settings),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
      ),
      IconButton(
        icon: const Icon(Icons.logout, color: Colors.redAccent),
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          if (mounted) Navigator.pushReplacementNamed(context, '/login');
        },
      ),
    ];
  }

  String _formatTimeDisplay(String time) {
    try {
      final parts = time.split(':');
      if (parts.length == 2) {
        final hour = parts[0].padLeft(2, '0');
        final minute = parts[1].padLeft(2, '0');
        return "$hour:$minute";
      }
      return time;
    } catch (e) {
      return time;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateString = DateFormat('EEEE, d MMMM', 'vi').format(now);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: StreamBuilder<List<HabitModel>>(
              stream: _habitsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allHabits = snapshot.data ?? [];
                WidgetsBinding.instance.addPostFrameCallback((_) => HomeWidgetService.updateWidget(allHabits));

                final displayHabits = _searchQuery.isEmpty
                    ? allHabits
                    : allHabits.where((habit) => habit.title.toLowerCase().contains(_searchQuery)).toList();

                final completedCount = allHabits.where((h) => h.isCompletedToday()).length;
                final totalCount = allHabits.length;
                final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, dateString, completedCount, totalCount, progress),

                    const SizedBox(height: 10),

                    if (_isSearching)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                          decoration: InputDecoration(
                            hintText: "Nhập tên thói quen...",
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(() {
                                _isSearching = false;
                                _searchQuery = "";
                                _searchController.clear();
                              }),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          autofocus: true,
                        ),
                      ),

                    Expanded(
                      child: displayHabits.isEmpty
                          ? _buildEmptyState(context)
                          : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: displayHabits.length,
                        itemBuilder: (context, index) {
                          final habit = displayHabits[index];
                          return _buildHabitCard(habit);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Color(0xFF66BB6A), Color(0xFF43A047), Colors.yellow, Colors.white],
              gravity: 0.2,
              numberOfParticles: 30,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(),
        icon: const Icon(Icons.add_task),
        label: const Text("Tạo Mới"),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  // 🔥 WIDGET HEADER ĐÃ CẬP NHẬT GRADIENT (TRÁI -> PHẢI)
  Widget _buildHeader(BuildContext context, String date, int completed, int total, double progress) {
    return StreamBuilder<UserModel?>(
      stream: _userStream,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final userName = user?.name ?? FirebaseAuth.instance.currentUser?.displayName ?? "Bạn";
        final String? avatarUrl = user?.avatar;
        final firstLetter = userName.isNotEmpty ? userName[0].toUpperCase() : "B";

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                          },
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: (avatarUrl == null || avatarUrl.isEmpty)
                                ? Text(firstLetter, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor))
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Xin chào,", style: TextStyle(fontSize: 14, color: Theme.of(context).hintColor)),
                              Text(
                                userName,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: _buildAppBarActions(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Text(
                "Hôm nay, nỗ lực nhé! 💪",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(date, style: TextStyle(fontSize: 14, color: Theme.of(context).hintColor)),

              const SizedBox(height: 20),

              // 🔥 CARD TIẾN ĐỘ - ĐÃ CHỈNH LẠI GRADIENT: TRÁI -> PHẢI VỚI STOPS RÕ RỆT
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF81C784), // Màu 1: Xanh lá mạ (Rất sáng) - Bên Trái
                      Color(0xFF2E7D32), // Màu 2: Xanh rừng già (Rất đậm) - Bên Phải
                    ],
                    // Điểm dừng: 0% -> 100%
                    stops: [0.0, 1.0],

                    begin: Alignment.centerLeft,  // Từ Trái
                    end: Alignment.centerRight,   // Sang Phải
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8)),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(
                      height: 85, width: 85,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white.withOpacity(0.25),
                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                            strokeWidth: 5,
                          ),
                          Text(
                            "${(progress * 100).toInt()}%",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: (progress >= 1.0) ?   8 : 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Tiến độ của bạn", style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 0.5)),
                          const SizedBox(height: 6),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(text: "$completed ", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                                TextSpan(text: "/ $total thói quen", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHabitCard(HabitModel habit) {
    final isDone = habit.isCompletedToday();
    final color = Color(habit.colorCode);
    return Dismissible(
      key: Key(habit.id),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.only(left: 20),
        alignment: Alignment.centerLeft, decoration: BoxDecoration(color: const Color(0xFF66BB6A), borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.edit, color: Colors.white, size: 30),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight, decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _showHabitDialog(habit: habit);
          return false;
        } else {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Xóa thói quen?"),
              content: Text("Bạn có chắc muốn xóa '${habit.title}' không?"),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Xóa", style: TextStyle(color: Colors.red))),
              ],
            ),
          );
          if (confirm == true) {
            if (habit.reminderTime != null) NotificationService().cancelNotification(NotificationService().createUniqueId(habit.id));
            _firestoreService.deleteHabit(habit.id);
            return true;
          }
          return false;
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          onTap: () => _handleCheckIn(habit),
          leading: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 50, width: 50,
            decoration: BoxDecoration(
              color: isDone ? color : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: isDone ? color : Colors.grey.shade300, width: 2),
            ),
            child: isDone ? const Icon(Icons.check, color: Colors.white, size: 30) : null,
          ),
          title: Text(habit.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, decoration: isDone ? TextDecoration.lineThrough : null, color: isDone ? Colors.grey : Theme.of(context).textTheme.bodyLarge?.color)),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (habit.description.isNotEmpty) Text(habit.description, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(children: [
              if (habit.currentStreak > 0) ...[const Icon(Icons.local_fire_department, size: 16, color: Colors.orange), Text(" ${habit.currentStreak} ngày", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange)), const SizedBox(width: 10)],
              if (habit.reminderTime != null) ...[
                const Icon(Icons.alarm, size: 16, color: Colors.blueGrey),
                Text(" ${_formatTimeDisplay(habit.reminderTime!)}", style: const TextStyle(fontSize: 12, color: Colors.blueGrey))
              ]
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.spa_outlined, size: 80, color: Colors.grey.withOpacity(0.3)),
      const SizedBox(height: 16),
      const Text("Ngày mới tươi đẹp!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
      const Text("Hãy bắt đầu tạo thói quen đầu tiên.", style: TextStyle(color: Colors.grey)),
    ]));
  }

  void _showAddOptions() {
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) {
      return Container(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text("Thêm thói quen", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 20),
        ListTile(leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.emoji_events, color: Colors.purple)), title: const Text("Khám phá Lộ trình Mẫu 🏆"), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const HabitPackScreen())); }),
        const SizedBox(height: 10),
        ListTile(leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.edit, color: Colors.blue)), title: const Text("Tự tạo thủ công ✏️"), onTap: () { Navigator.pop(context); _showHabitDialog(); }),
      ]));
    });
  }
}