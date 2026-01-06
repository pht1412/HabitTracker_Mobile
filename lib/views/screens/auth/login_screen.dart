import 'package:flutter/material.dart';
import '../../../controllers/auth_controller.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --- GIỮ NGUYÊN LOGIC CŨ ---
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _authController = AuthController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    // Lấy kích thước màn hình để căn chỉnh
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: size.height,
          decoration: const BoxDecoration(
            // 🔥 NỀN GRADIENT XANH MÁT MẮT
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE8F5E9), // Xanh rất nhạt
                Color(0xFFC8E6C9), // Xanh nhạt hơn
                Colors.white,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 🔥 LOGO APP (Thương hiệu)
                  Center(
                    child: Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      // Đảm bảo bạn đã có ảnh logo, nếu chưa có thì nó hiện icon giữ chỗ
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.spa, size: 60, color: Color(0xFF4CAF50)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "Chào mừng trở lại!",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32), // Xanh đậm
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Text(
                    "Tiếp tục hành trình tốt hơn mỗi ngày",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // 🔥 INPUT EMAIL (STYLE MỚI)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                      ],
                    ),
                    child: TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.email_outlined, color: Colors.green),
                        border: InputBorder.none, // Bỏ viền cứng
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      validator: (val) => val!.isEmpty ? "Vui lòng nhập email" : null,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🔥 INPUT PASSWORD (STYLE MỚI)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                      ],
                    ),
                    child: TextFormField(
                      controller: _passController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Mật khẩu",
                        prefixIcon: Icon(Icons.lock_outline, color: Colors.green),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      validator: (val) => val!.length < 6 ? "Mật khẩu phải trên 6 ký tự" : null,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 🔥 NÚT LOGIN (GRADIENT & SHADOW)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF66BB6A), Color(0xFF43A047)], // Xanh lá tươi
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _authController.handleLogin(
                            context,
                            _emailController.text.trim(),
                            _passController.text.trim(),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, // Để hiện màu Gradient
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                          "Đăng Nhập",
                          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🔥 NÚT CHUYỂN ĐĂNG KÝ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Chưa có tài khoản? ", style: TextStyle(color: Colors.grey)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                        },
                        child: const Text(
                          "Đăng ký ngay",
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}