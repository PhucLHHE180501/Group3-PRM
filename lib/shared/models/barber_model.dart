class BarberModel {
  final int userId;
  final String fullName;
  final String phone;
  final String? avatarUrl;
  final String bio;
  final String specialty;
  final int yearsExperience;
  final String status; // 'available', 'busy', 'break', 'off'
  final double avgRating;
  final int reviewCount;
  final List<String> portfolioImages; // Các hình ảnh kiểu tóc barber đã đăng

  BarberModel({
    required this.userId,
    required this.fullName,
    required this.phone,
    this.avatarUrl,
    required this.bio,
    required this.specialty,
    required this.yearsExperience,
    required this.status,
    required this.avgRating,
    required this.reviewCount,
    required this.portfolioImages,
  });
}
