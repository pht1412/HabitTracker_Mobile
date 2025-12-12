import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Cần thêm cái này để check trạng thái
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

// Import các màn hình
import 'views/screens/auth/login_screen.dart';
import 'views/screens/auth/register_screen.dart';
import 'views/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. THÊM DÒNG NÀY: Nạp dữ liệu định dạng ngày tháng (cho Tiếng Việt & Tiếng Anh)
  await initializeDateFormatting();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HabitTracker+',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),

      // THAY ĐỔI QUAN TRỌNG Ở ĐÂY:
      // Thay vì dùng initialRoute, ta dùng thuộc tính 'home' để đặt Trạm gác
      home: const AuthGate(),

      // Vẫn giữ routes để chuyển trang thủ công khi cần
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

// --- TRẠM GÁC (AUTH GATE) ---
// Tự động điều hướng dựa trên trạng thái đăng nhập
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Lắng nghe luồng sự kiện đăng nhập/đăng xuất từ Firebase
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Trường hợp đang kiểm tra (Load app)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Nếu ĐÃ CÓ dữ liệu User (Đã đăng nhập) -> Vào thẳng Home
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // 3. Nếu KHÔNG CÓ dữ liệu (Chưa đăng nhập/Đã logout) -> Về Login
        return const LoginScreen();
      },
    );
  }
}