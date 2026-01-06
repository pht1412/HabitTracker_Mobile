import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await _configureLocalTimeZone();

    // ✅ Đã khớp với ảnh bạn gửi: @mipmap/launcher_icon
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint("🔔 Notification clicked: ${details.payload}");
      },
    );

    // 🔥 FIX QUAN TRỌNG: ĐỔI ID CHANNEL ĐỂ RESET CẤU HÌNH TRÊN ANDROID
    // Android sẽ coi đây là channel mới và áp dụng Importance.max ngay lập tức
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'daily_habit_channel_v2', // Đổi tên ID (v1 -> v2)
      'Nhắc nhở thói quen',
      description: 'Nhắc nhở thực hiện thói quen mỗi ngày',
      importance: Importance.max, // Đảm bảo hiện Popup (Heads-up)
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
      await androidPlugin.requestNotificationsPermission();
    }

    debugPrint("✅ NotificationService Ready (Channel v2)");
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    try {
      final dynamic systemTimezone = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = systemTimezone.toString();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
      } catch (e) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    }
  }

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    try {
      final tz.TZDateTime scheduledDate = _nextInstanceOfTime(time);
      debugPrint("⏰ Đang đặt lịch ID $id lúc: $scheduledDate");

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_habit_channel_v2', // 🔥 Phải khớp với ID ở trên
            'Nhắc nhở thói quen',
            channelDescription: 'Nhắc nhở thực hiện thói quen mỗi ngày',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            fullScreenIntent: true, // Hỗ trợ hiện khi màn hình tắt
          ),
          iOS: DarwinNotificationDetails(),
        ),

        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,

        // Chế độ Inexact: An toàn cho Android 12+, không cần quyền Alarm
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,

        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint("✅ Đã gửi lệnh đặt lịch thành công (Inexact Mode)");

    } catch (e) {
      debugPrint("❌ LỖI ĐẶT LỊCH: $e");
      _scheduleFallback(id, title, body, time);
    }
  }

  void _scheduleFallback(int id, String title, String body, TimeOfDay time) {
    showInstantNotification(
      title: "Lỗi Hệ Thống",
      body: "Không thể đặt lịch. Vui lòng kiểm tra quyền thông báo.",
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    debugPrint("🗑️ Đã hủy lịch ID: $id");
  }

  Future<void> requestPermissions() async {
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    // Nếu giờ đã qua -> +1 ngày
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  int createUniqueId(String habitId) {
    return habitId.hashCode & 0x7fffffff;
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_habit_channel_v2', // 🔥 Khớp ID v2
      'Nhắc nhở thói quen',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    await flutterLocalNotificationsPlugin.show(0, title, body, details);
  }
}