import 'service_model.dart';

class TransactionModel {
  final int id;
  final int bookingId;
  final int customerId;
  final double amount;
  final double discount;
  final double tipAmount;
  final String method; // 'cash', 'card', 'bank_transfer', 'e_wallet'
  final String status; // 'unpaid', 'paid', 'refunded'
  final DateTime? paidAt;
  final DateTime createdAt;
  final String serviceSummary;

  // Detailed fields
  final String? staffName;
  final String? staffAvatar;
  final DateTime? bookingDate;
  final String? timeSlot;
  final List<ServiceModel>? services;

  TransactionModel({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.amount,
    this.discount = 0,
    this.tipAmount = 0,
    required this.method,
    required this.status,
    this.paidAt,
    required this.createdAt,
    required this.serviceSummary,
    this.staffName,
    this.staffAvatar,
    this.bookingDate,
    this.timeSlot,
    this.services,
  });

  double get finalAmount => (amount - discount) + tipAmount;

  TransactionModel copyWith({
    int? id,
    int? bookingId,
    int? customerId,
    double? amount,
    double? discount,
    double? tipAmount,
    String? method,
    String? status,
    DateTime? paidAt,
    DateTime? createdAt,
    String? serviceSummary,
    String? staffName,
    String? staffAvatar,
    DateTime? bookingDate,
    String? timeSlot,
    List<ServiceModel>? services,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      customerId: customerId ?? this.customerId,
      amount: amount ?? this.amount,
      discount: discount ?? this.discount,
      tipAmount: tipAmount ?? this.tipAmount,
      method: method ?? this.method,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
      serviceSummary: serviceSummary ?? this.serviceSummary,
      staffName: staffName ?? this.staffName,
      staffAvatar: staffAvatar ?? this.staffAvatar,
      bookingDate: bookingDate ?? this.bookingDate,
      timeSlot: timeSlot ?? this.timeSlot,
      services: services ?? this.services,
    );
  }
}
