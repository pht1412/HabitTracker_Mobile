import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Đăng ký + Tạo User Profile trên Firestore
  Future<String?> registerUser({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // 1. Tạo user trong Authentication
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Tạo profile trong Firestore (Collection 'users')
      UserModel newUser = UserModel(
        id: result.user!.uid,
        email: email,
        name: name,
        joinedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(result.user!.uid) // Dùng luôn UID làm Document ID
          .set(newUser.toJson());

      return null; // Null nghĩa là thành công
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return 'Email này đã được đăng ký!';
      if (e.code == 'weak-password') return 'Mật khẩu quá yếu (cần 6 ký tự trở lên).';
      return 'Lỗi đăng ký: ${e.message}';
    } catch (e) {
      return 'Lỗi không xác định: $e';
    }
  }

  // Đăng nhập
  Future<String?> loginUser({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Thành công
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'Không tìm thấy tài khoản này.';
      if (e.code == 'wrong-password') return 'Sai mật khẩu rồi!';
      return 'Lỗi đăng nhập: ${e.message}';
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    await _auth.signOut();
  }
}