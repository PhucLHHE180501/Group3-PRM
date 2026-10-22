import 'service_model.dart';

class BookingModel {
  final int id;
  final int customerId;
  final String? customerName;
  final String? customerPhone;
  final bool isWalkIn;
  final int staffId;
  final String staffName;
  final String? staffAvatar;
  final DateTime bookingDate;
  final String startTime; // '09:00'
  final String endTime;   // '10:00'
  final String status;    // 'pending', 'confirmed', 'checked_in', 'in_progress', 'completed', 'cancelled'
  final double totalPrice;
  final List<ServiceModel> services;
  final String? note;
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.customerId,
    this.customerName,
    this.customerPhone,
    this.isWalkIn = false,
    required this.staffId,
    required this.staffName,
    this.staffAvatar,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.totalPrice,
    required this.services,
    this.note,
    required this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: (json['id'] as num).toInt(),
      customerId: (json['customerId'] as num).toInt(),
      customerName: json['customerName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      isWalkIn: (json['isWalkIn'] as bool?) ?? false,
      staffId: (json['staffId'] as num).toInt(),
      staffName: json['staffName'] as String? ?? '',
      staffAvatar: json['staffAvatar'] as String?,
      bookingDate: DateTime.parse(json['bookingDate'] as String),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      status: json['status'] as String,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      services: (json['services'] as List<dynamic>? ?? [])
          .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  BookingModel copyWith({
    int? customerId,
    String? customerName,
    String? customerPhone,
    bool? isWalkIn,
    int? staffId,
    String? staffName,
    String? staffAvatar,
    DateTime? bookingDate,
    String? startTime,
    String? endTime,
    String? status,
    double? totalPrice,
    List<ServiceModel>? services,
    String? note,
    DateTime? createdAt,
  }) {
    return BookingModel(
      id: id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      isWalkIn: isWalkIn ?? this.isWalkIn,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      staffAvatar: staffAvatar ?? this.staffAvatar,
      bookingDate: bookingDate ?? this.bookingDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      services: services ?? this.services,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
