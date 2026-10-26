import 'package:flutter/material.dart';

import 'package:barber_booking_app/shared/models/booking_model.dart';
import 'package:barber_booking_app/shared/models/service_model.dart';
import 'package:barber_booking_app/shared/models/transaction_model.dart';
import 'package:barber_booking_app/shared/services/firebase_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final FirebaseService _dataService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _dataService.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _dataService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDayOnly(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _getMethodName(String method) {
    switch (method) {
      case 'cash':
        return 'Tiền mặt tại quầy';
      case 'card':
        return 'Thẻ ngân hàng';
      case 'bank_transfer':
        return 'Chuyển khoản QR';
      case 'e_wallet':
        return 'Ví điện tử';
      default:
        return method;
    }
  }

  IconData _getMethodIcon(String method) {
    switch (method) {
      case 'cash':
        return Icons.payments;
      case 'bank_transfer':
        return Icons.qr_code_2;
      case 'card':
        return Icons.credit_card;
      case 'e_wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color textColor;
    String label;

    switch (status) {
      case 'paid':
        bg = Colors.green.withOpacity(0.2);
        textColor = Colors.greenAccent;
        label = 'Đã thanh toán';
        break;
      case 'refunded':
        bg = Colors.orange.withOpacity(0.2);
        textColor = Colors.orangeAccent;
        label = 'Hoàn tiền';
        break;
      case 'unpaid':
      default:
        bg = Colors.red.withOpacity(0.2);
        textColor = Colors.redAccent;
        label = 'Chưa thanh toán';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showTransactionDetailSheet(TransactionModel tx) {
    // Attempt to lookup associated booking if available
    final BookingModel? associatedBooking = _dataService.getBookingById(tx.bookingId);

    final staffName = tx.staffName ?? associatedBooking?.staffName ?? 'Barber Salon';
    final staffAvatar = tx.staffAvatar ?? associatedBooking?.staffAvatar;
    final bookingDate = tx.bookingDate ?? associatedBooking?.bookingDate ?? tx.createdAt;
    final timeSlot = tx.timeSlot ?? (associatedBooking != null ? '${associatedBooking.startTime} - ${associatedBooking.endTime}' : 'Theo ca hẹn');
    final List<ServiceModel> services = tx.services ?? associatedBooking?.services ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chi Tiết Giao Dịch #${tx.id}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Mã đặt lịch: #${tx.bookingId}',
                              style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12),
                            ),
                          ],
                        ),
                        _buildStatusChip(tx.status),
                      ],
                    ),

                    const Divider(color: Colors.white12, height: 24),

                    // 1. Barber / Staff Info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: const Color(0xFFD4AF37),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundImage: staffAvatar != null && staffAvatar.isNotEmpty
                                  ? NetworkImage(staffAvatar)
                                  : null,
                              child: staffAvatar == null || staffAvatar.isEmpty
                                  ? const Icon(Icons.person, color: Colors.white, size: 24)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Thợ Phục Vụ Cắt Tóc',
                                  style: TextStyle(color: Colors.grey, fontSize: 11),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  staffName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.verified, color: Color(0xFFD4AF37), size: 20),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 2. Date & Time Info
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252525),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            icon: Icons.calendar_month,
                            label: 'Ngày dịch vụ',
                            value: _formatDayOnly(bookingDate),
                          ),
                          const SizedBox(height: 10),
                          _buildDetailRow(
                            icon: Icons.access_time,
                            label: 'Khung giờ cắt',
                            value: timeSlot,
                          ),
                          if (tx.paidAt != null) ...[
                            const SizedBox(height: 10),
                            _buildDetailRow(
                              icon: Icons.check_circle_outline,
                              label: 'Thời gian thanh toán',
                              value: _formatDate(tx.paidAt!),
                            ),
                          ],
                          const SizedBox(height: 10),
                          _buildDetailRow(
                            icon: _getMethodIcon(tx.method),
                            label: 'Phương thức',
                            value: _getMethodName(tx.method),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 3. Services Used List
                    const Text(
                      'Dịch vụ đã sử dụng:',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (services.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252525),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            for (final s in services)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    const Icon(Icons.content_cut, color: Color(0xFFD4AF37), size: 16),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s.name,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          Text(
                                            '${s.durationMin} phút',
                                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _formatPrice(s.price),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252525),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tx.serviceSummary.isNotEmpty ? tx.serviceSummary : 'Dịch vụ Salon Barber',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // 4. Payment Cost Breakdown
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)),
                      ),
                      child: Column(
                        children: [
                          _buildCostRow('Tạm tính (Tiền dịch vụ)', _formatPrice(tx.amount)),
                          if (tx.discount > 0) ...[
                            const SizedBox(height: 6),
                            _buildCostRow('Giảm giá / Ưu đãi', '- ${_formatPrice(tx.discount)}', isDiscount: true),
                          ],
                          const SizedBox(height: 6),
                          _buildCostRow('Tiền Tip cho thợ', '+ ${_formatPrice(tx.tipAmount)}', isTip: true),
                          const Divider(color: Colors.white24, height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TỔNG THANH TOÁN',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                _formatPrice(tx.finalAmount),
                                style: const TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 5. Interactive Tip section for customer
                    if (tx.status == 'paid') ...[
                      const Text(
                        'Thưởng tiền Tip động viên thợ cắt:',
                        style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [10000.0, 20000.0, 30000.0, 50000.0, 100000.0].map((tipVal) {
                          final isSelected = tx.tipAmount == tipVal;
                          return ChoiceChip(
                            label: Text('+ ${_formatPrice(tipVal)}'),
                            selected: isSelected,
                            selectedColor: const Color(0xFFD4AF37),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            backgroundColor: const Color(0xFF2A2A2A),
                            onSelected: (_) async {
                              await _dataService.addTipToTransaction(tx.id, tipVal);
                              setModalState(() {});
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Cảm ơn bạn đã tip ${_formatPrice(tipVal)} cho $staffName!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Close Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('ĐÓNG TẬP HÓA ĐƠN', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFD4AF37)),
        const SizedBox(width: 10),
        SizedBox(
          width: 140,
          child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildCostRow(String label, String value, {bool isDiscount = false, bool isTip = false}) {
    Color valColor = Colors.white70;
    if (isDiscount) valColor = Colors.greenAccent;
    if (isTip) valColor = const Color(0xFFD4AF37);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        Text(
          value,
          style: TextStyle(color: valColor, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactions = _dataService.getCurrentUserTransactions();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Sử Giao Dịch'),
      ),
      body: transactions.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có giao dịch nào',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = transactions[index];
                final staffName = item.staffName ?? 'Thợ cắt Barber';

                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showTransactionDetailSheet(item),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Mã GD: #${item.id}',
                                style: const TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              _buildStatusChip(item.status),
                            ],
                          ),
                          const Divider(color: Colors.white10, height: 20),
                          Text(
                            item.serviceSummary.isNotEmpty ? item.serviceSummary : 'Dịch vụ Barber',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.person, size: 16, color: Color(0xFFD4AF37)),
                              const SizedBox(width: 6),
                              Text(
                                'Thợ cắt: $staffName',
                                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(_getMethodIcon(item.method), size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                'Phương thức: ${_getMethodName(item.method)}',
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                'Thời gian: ${_formatDate(item.createdAt)}',
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Tổng tiền: ',
                                    style: TextStyle(color: Colors.white70, fontSize: 13),
                                  ),
                                  Text(
                                    _formatPrice(item.finalAmount),
                                    style: const TextStyle(
                                      color: Color(0xFFD4AF37),
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Row(
                                children: [
                                  Text(
                                    'Chi tiết',
                                    style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(width: 2),
                                  Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFFD4AF37)),
                                ],
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
