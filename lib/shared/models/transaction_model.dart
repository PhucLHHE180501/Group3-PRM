class TransactionModel {
  final int id;
  final int bookingId;
  final int customerId;
  final double amount;
  final double discount;
  final String method; // 'cash', 'card', 'bank_transfer', 'e_wallet'
  final String status; // 'unpaid', 'paid', 'refunded'
  final DateTime? paidAt;
  final DateTime createdAt;
  final String serviceSummary;

  TransactionModel({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.amount,
    this.discount = 0,
    required this.method,
    required this.status,
    this.paidAt,
    required this.createdAt,
    required this.serviceSummary,
  });
}
