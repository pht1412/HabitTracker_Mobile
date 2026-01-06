import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔥 Cần cho AuthGate

import 'firebase_options.dart';
import 'providers/theme_provider.dart';

// Import các màn hình
import 'views/screens/auth/login_screen.dart';
import 'views/screens/auth/register_screen.dart';
import 'views/screens/home_screen.dart';
import 'views/screens/admin_screen.dart'; // 🔥 Import màn hình Admin mới
import 'services/notification_service.dart';
import 'services/gemini_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('vi', null);
  await NotificationService().init();
  GeminiService().init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HabitTracker+',
      theme: themeProvider.currentTheme,
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/admin': (context) => const AdminScreen(), // 🔥 Route cho Admin
      },
    );
  }
}

// 🔥 AUTH GATE MỚI: PHÂN QUYỀN USER / ADMIN
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Chưa kết nối xong
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 2. Có người đăng nhập -> Kiểm tra Role trong Firestore
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
            builder: (context, userSnapshot) {
              // Đang tải role -> Hiện màn hình chờ
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.green)));
              }

              if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                final role = userData['role'] ?? 'user';

                // 🔥 ĐIỀU HƯỚNG QUYỀN LỰC
                if (role == 'admin') {
                  return const AdminScreen();
                } else {
                  return const HomeScreen();
                }
              }

              // Fallback: Nếu lỗi đọc data hoặc ko có role, cứ cho vào Home thường
              return const HomeScreen();
            },
          );
        }

        // 3. Chưa đăng nhập -> Về Login
        return const LoginScreen();
      },
    );
  }
}