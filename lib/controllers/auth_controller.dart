import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../views/screens/home_screen.dart'; // Giả sử đã có trang chủ

class AuthController {
  final AuthService _service = AuthService();

  // Hàm xử lý logic Đăng nhập từ UI
  Future<void> handleLogin(BuildContext context, String email, String password) async {
    // Hiển thị loading
    showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));

    String? error = await _service.loginUser(email: email, password: password);

    // Tắt loading
    Navigator.pop(context);

    if (error == null) {
      // Thành công -> Chuyển sang Home
      Navigator.pushReplacementNamed(context, '/home');
      // Hoặc: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
    } else {
      // Thất bại -> Hiện lỗi
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error, style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
    }
  }

  // Hàm xử lý logic Đăng ký
  Future<void> handleRegister(BuildContext context, String name, String email, String password) async {
    showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));

    String? error = await _service.registerUser(email: email, password: password, name: name);

    Navigator.pop(context);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đăng ký thành công! Hãy đăng nhập.")));
      Navigator.pop(context); // Quay về trang Login
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
    }
  }
}