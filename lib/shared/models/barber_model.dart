class BarberPortfolioCollection {
  final String id;
  final String title;
  final String? description;
  final String? coverUrl;
  final List<String> images;

  const BarberPortfolioCollection({
    required this.id,
    required this.title,
    this.description,
    this.coverUrl,
    this.images = const [],
  });

  String get effectiveCoverUrl {
    if (coverUrl != null && coverUrl!.isNotEmpty) return coverUrl!;
    if (images.isNotEmpty) return images.first;
    return '';
  }

  int get imageCount => images.length;

  factory BarberPortfolioCollection.fromJson(Map<String, dynamic> json) {
    return BarberPortfolioCollection(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Bộ sưu tập',
      description: json['description'] as String?,
      coverUrl: json['coverUrl'] as String?,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (description != null) 'description': description,
      if (coverUrl != null) 'coverUrl': coverUrl,
      'images': images,
    };
  }

  BarberPortfolioCollection copyWith({
    String? id,
    String? title,
    String? description,
    String? coverUrl,
    List<String>? images,
  }) {
    return BarberPortfolioCollection(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      images: images ?? this.images,
    );
  }
}

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
  final List<BarberPortfolioCollection> collections; // Danh sách các bộ sưu tập ảnh

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
    this.portfolioImages = const [],
    this.collections = const [],
  });

  factory BarberModel.fromJson(Map<String, dynamic> json) {
    final rawCollections = (json['collections'] as List<dynamic>?)
            ?.map((e) =>
                BarberPortfolioCollection.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    final rawPortfolioImages = (json['portfolioImages'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];

    // Tự động fallback gom ảnh vào collection mặc định nếu chưa có collections
    final effectiveCollections = rawCollections.isNotEmpty
        ? rawCollections
        : (rawPortfolioImages.isNotEmpty
            ? [
                BarberPortfolioCollection(
                  id: 'col_default_${json['userId']}',
                  title: 'Tác phẩm tiêu biểu',
                  description: 'Bộ sưu tập các mẫu tóc đẹp đã thực hiện',
                  images: rawPortfolioImages,
                )
              ]
            : const <BarberPortfolioCollection>[]);

    final effectiveImages = rawPortfolioImages.isNotEmpty
        ? rawPortfolioImages
        : effectiveCollections.expand((c) => c.images).toList();

    return BarberModel(
      userId: (json['userId'] as num).toInt(),
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String? ?? '',
      specialty: json['specialty'] as String? ?? '',
      yearsExperience: (json['yearsExperience'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'available',
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      portfolioImages: effectiveImages,
      collections: effectiveCollections,
    );
  }

  BarberModel copyWith({
    String? status,
    List<String>? portfolioImages,
    List<BarberPortfolioCollection>? collections,
  }) {
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
      portfolioImages: portfolioImages ?? this.portfolioImages,
      collections: collections ?? this.collections,
    );
  }
}
