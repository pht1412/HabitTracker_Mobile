class UserModel {
  final String id;
  final String email;
  final String name;
  final DateTime joinedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.joinedAt,
  });

  // Chuyển từ Object -> Map (để bắn lên Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }

  // Chuyển từ Map -> Object (để app sử dụng)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? 'No Name',
      joinedAt: DateTime.parse(json['joinedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}