class ReviewModel {
  final int id;
  final int bookingId;
  final int customerId;
  final String customerName;
  final String? customerAvatar;
  final int staffId;
  final int rating; // 1 to 5
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.customerName,
    this.customerAvatar,
    required this.staffId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: (json['id'] as num).toInt(),
      bookingId: (json['bookingId'] as num).toInt(),
      customerId: (json['customerId'] as num).toInt(),
      customerName: json['customerName'] as String? ?? '',
      customerAvatar: json['customerAvatar'] as String?,
      staffId: (json['staffId'] as num).toInt(),
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
