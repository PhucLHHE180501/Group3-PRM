import 'service_model.dart';

class BookingModel {
  final int id;
  final int customerId;
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

  BookingModel copyWith({
    String? status,
  }) {
    return BookingModel(
      id: id,
      customerId: customerId,
      staffId: staffId,
      staffName: staffName,
      staffAvatar: staffAvatar,
      bookingDate: bookingDate,
      startTime: startTime,
      endTime: endTime,
      status: status ?? this.status,
      totalPrice: totalPrice,
      services: services,
      note: note,
      createdAt: createdAt,
    );
  }
}
