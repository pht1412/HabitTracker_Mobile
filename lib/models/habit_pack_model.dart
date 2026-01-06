class PackHabit {
  final String title;
  final int offsetMinutes; // Thời gian thực hiện tính từ lúc bắt đầu (phút)

  PackHabit(this.title, this.offsetMinutes);
}

class HabitPack {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final bool isPremium; // 🔥 TRƯỜNG MỚI: Xác định gói VIP
  final List<PackHabit> habits;

  HabitPack({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    this.isPremium = false, // Mặc định là Free
    required this.habits,
  });

  // --- DỮ LIỆU MẪU (BAO GỒM CẢ FREE VÀ VIP) ---
  static List<HabitPack> getSamplePacks() {
    return [
      // === 3 GÓI MIỄN PHÍ (GIỮ NGUYÊN) ===
      HabitPack(
        id: 'pack_morning',
        name: 'Sáng sớm Năng lượng',
        description: 'Khởi động ngày mới tỉnh táo và hiệu quả.',
        emoji: '🌅',
        isPremium: false,
        habits: [
          PackHabit('Uống 1 ly nước ấm', 0),
          PackHabit('Dọn dẹp giường ngủ', 5),
          PackHabit('Thiền / Hít thở sâu', 15),
          PackHabit('Lập To-do list hôm nay', 30),
        ],
      ),
      HabitPack(
        id: 'pack_sleep',
        name: 'Vệ sinh Giấc ngủ',
        description: 'Thư giãn tâm trí để có giấc ngủ sâu.',
        emoji: '🌙',
        isPremium: false,
        habits: [
          PackHabit('Cất điện thoại (Digital Detox)', 0),
          PackHabit('Đọc sách 20 phút', 10),
          PackHabit('Viết nhật ký biết ơn', 30),
          PackHabit('Đi ngủ', 45),
        ],
      ),
      HabitPack(
        id: 'pack_health',
        name: 'Sống Khỏe mỗi ngày',
        description: 'Những thói quen nhỏ giúp cơ thể dẻo dai.',
        emoji: '💪',
        isPremium: false,
        habits: [
          PackHabit('Ăn sáng đầy đủ', 0),
          PackHabit('Đi bộ 15 phút', 60),
          PackHabit('Ăn trái cây / Rau xanh', 120),
          PackHabit('Uống vitamin', 125),
        ],
      ),

      // === 🔥 3 GÓI VIP (MỚI THÊM VÀO) ===

      // 1. Gói CEO Routine
      HabitPack(
        id: 'pack_ceo',
        name: 'CEO Routine (Elon Musk)',
        description: 'Mô phỏng 2 giờ đầu ngày của các tỷ phú công nghệ.',
        emoji: '🚀',
        isPremium: true, // Đánh dấu VIP
        habits: [
          PackHabit('Dậy sớm & Không chạm điện thoại', 0),
          PackHabit('Tập thể dục cường độ cao', 15),
          PackHabit('Tắm nước lạnh (Cold Plunge)', 45),
          PackHabit('Deep Work (Việc khó nhất)', 60),
          PackHabit('Kiểm tra Email & Tin tức', 120),
        ],
      ),

      // 2. Gói 75 Hard
      HabitPack(
        id: 'pack_75hard',
        name: '75 Hard Challenge',
        description: 'Thử thách kỷ luật thép rèn luyện tinh thần.',
        emoji: '🔥',
        isPremium: true,
        habits: [
          PackHabit('Tập luyện 1 (Trong nhà)', 0),
          PackHabit('Chụp ảnh Body Check', 50),
          PackHabit('Đọc 10 trang sách (Non-fiction)', 60),
          PackHabit('Uống 1 lít nước (Lần 1)', 90),
          PackHabit('Tập luyện 2 (Ngoài trời)', 480), // 8 tiếng sau
        ],
      ),

      // 3. Gói Monk Mode
      HabitPack(
        id: 'pack_monk',
        name: 'Monk Mode (Tu sĩ)',
        description: '21 ngày cai nghiện Dopamine, tái tạo sự tập trung.',
        emoji: '🧘‍♂️',
        isPremium: true,
        habits: [
          PackHabit('Thiền định sâu (30p)', 0),
          PackHabit('Viết nhật ký suy tưởng', 35),
          PackHabit('Đi dạo không đem điện thoại', 60),
          PackHabit('Review: Không dùng MXH hôm nay', 720), // 12 tiếng sau (Cuối ngày)
        ],
      ),
    ];
  }
}