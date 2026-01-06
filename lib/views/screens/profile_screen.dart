import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';
import '../../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final TextEditingController _nameController = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    setState(() => _isLoading = true);
    final userStream = _firestoreService.getUserStream();
    final user = await userStream.first;

    if (user != null) {
      _currentUser = user;
      _nameController.text = user.name;
    } else {
      _nameController.text = FirebaseAuth.instance.currentUser?.displayName ?? "";
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tên không được để trống")));
      return;
    }

    setState(() => _isLoading = true);

    String? newAvatarUrl;

    if (_selectedImage != null) {
      newAvatarUrl = await _cloudinaryService.uploadImage(_selectedImage!);
      if (newAvatarUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi upload ảnh!")));
        setState(() => _isLoading = false);
        return;
      }
    }

    await _firestoreService.updateUserProfile(
      name: _nameController.text.trim(),
      avatarUrl: newAvatarUrl,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cập nhật thành công! 🎉")));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (_selectedImage != null) {
      imageProvider = FileImage(_selectedImage!);
    } else if (_currentUser?.avatar != null && _currentUser!.avatar!.isNotEmpty) {
      imageProvider = NetworkImage(_currentUser!.avatar!);
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Hồ sơ cá nhân")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: imageProvider,
                    child: imageProvider == null
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        // Đổi màu nút Camera sang Xanh lá đậm
                        color: Color(0xFF43A047),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 40),

            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Tên hiển thị",
                prefixIcon: const Icon(Icons.badge, color: Color(0xFF2E7D32)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              enabled: false,
              controller: TextEditingController(text: FirebaseAuth.instance.currentUser?.email),
              decoration: InputDecoration(
                labelText: "Email",
                prefixIcon: const Icon(Icons.email, color: Color(0xFF2E7D32)),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Lưu thay đổi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}