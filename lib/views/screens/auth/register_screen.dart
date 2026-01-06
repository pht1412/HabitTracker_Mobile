import 'package:flutter/material.dart';
import '../../../controllers/auth_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // --- GIỮ NGUYÊN LOGIC CŨ ---
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _authController = AuthController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // Mở rộng body lên cả thanh trạng thái cho đẹp
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Trong suốt
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2E7D32)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        height: size.height,
        decoration: const BoxDecoration(
          // 🔥 NỀN GRADIENT TƯƠNG TỰ LOGIN
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Colors.white,
              Color(0xFFE8F5E9),
              Color(0xFFC8E6C9),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Text(
                  "Tạo tài khoản",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const Text(
                  "Bắt đầu xây dựng thói quen tốt ngay hôm nay",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),

                const SizedBox(height: 40),

                // 🔥 INPUT NAME
                _buildModernInput(
                  controller: _nameController,
                  label: "Tên hiển thị",
                  icon: Icons.person_outline,
                  validator: (val) => val!.isEmpty ? "Hãy nhập tên của bạn" : null,
                ),
                const SizedBox(height: 16),

                // 🔥 INPUT EMAIL
                _buildModernInput(
                  controller: _emailController,
                  label: "Email",
                  icon: Icons.email_outlined,
                  validator: (val) => val!.contains('@') ? null : "Email không hợp lệ",
                ),
                const SizedBox(height: 16),

                // 🔥 INPUT PASSWORD
                _buildModernInput(
                  controller: _passController,
                  label: "Mật khẩu",
                  icon: Icons.lock_outline,
                  isPassword: true,
                  validator: (val) => val!.length < 6 ? "Mật khẩu yếu quá (min 6)" : null,
                ),
                const SizedBox(height: 16),
                _buildModernInput(
                  controller: _confirmPassController,
                  label: "Xác nhận mật khẩu",
                  icon: Icons.lock_reset,
                  isPassword: true,
                  validator: (val) {
                    if (val!.isEmpty) return "Vui lòng xác nhận mật khẩu";
                    if (val != _passController.text) return "Mật khẩu không khớp";
                    return null;
                  },
                ),
                const SizedBox(height: 40),


                // 🔥 NÚT REGISTER (GRADIENT)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF43A047), Color(0xFF2E7D32)], // Xanh đậm hơn chút
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
                        _authController.handleRegister(
                          context,
                          _nameController.text.trim(),
                          _emailController.text.trim(),
                          _passController.text.trim(),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                        "Đăng Ký Ngay",
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget con giúp code gọn và tái sử dụng style
  Widget _buildModernInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.green),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }
}