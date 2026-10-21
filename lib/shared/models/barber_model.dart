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

  factory BarberModel.fromJson(Map<String, dynamic> json) {
    return BarberModel(
      userId: (json['userId'] as num).toInt(),
      fullName: json['fullName'] as String,
      phone: json['phone'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String? ?? '',
      specialty: json['specialty'] as String? ?? '',
      yearsExperience: (json['yearsExperience'] as num?)?.toInt() ?? 0,
      status: json['status'] as String,
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      portfolioImages: (json['portfolioImages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  BarberModel copyWith({String? status}) {
    return BarberModel(
      userId: userId,
      fullName: fullName,
      phone: phone,
      avatarUrl: avatarUrl,
      bio: bio,
      specialty: specialty,
      yearsExperience: yearsExperience,
      status: status ?? this.status,
      avgRating: avgRating,
      reviewCount: reviewCount,
      portfolioImages: portfolioImages,
    );
  }
}
