class UserModel {
  final String id;
  final String email;
  final String name;
  final String? avatar;
  final String role; // 'admin' hoặc 'user'
  final bool isPremium; // 🔥 Thêm cái này để Admin tính doanh thu
  final DateTime joinedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.avatar,
    this.role = 'user',
    this.isPremium = false, // Mặc định false
    required this.joinedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar': avatar,
      'role': role,
      'isPremium': isPremium, // 🔥 Lưu trạng thái VIP
      'joinedAt': joinedAt.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? 'No Name',
      avatar: json['avatar'],
      role: json['role'] ?? 'user',
      isPremium: json['isPremium'] ?? false, // 🔥 Đọc trạng thái VIP
      joinedAt: DateTime.parse(json['joinedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}