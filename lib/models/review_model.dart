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
}
