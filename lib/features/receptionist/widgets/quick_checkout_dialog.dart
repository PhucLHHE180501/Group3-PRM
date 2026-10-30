import 'package:flutter/material.dart';
import 'package:barber_booking_app/shared/models/booking_model.dart';
import 'package:barber_booking_app/shared/services/firebase_service.dart';

class QuickCheckoutDialog extends StatefulWidget {
  final BookingModel booking;

  const QuickCheckoutDialog({
    super.key,
    required this.booking,
  });

  @override
  State<QuickCheckoutDialog> createState() => _QuickCheckoutDialogState();
}

class _QuickCheckoutDialogState extends State<QuickCheckoutDialog> {
  final FirebaseService _dataService = FirebaseService();
  String _paymentMethod = 'cash'; // 'cash' or 'bank_transfer'

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} d';
  }

  void _handleConfirmPayment() {
    _dataService.markPaymentPaid(widget.booking.id, _paymentMethod);
    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Ðã thu ${_formatPrice(widget.booking.totalPrice)} (${_paymentMethod == "cash" ? "Tiền mặt" : "Chuyển khoản QR"}) thành công!',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.point_of_sale, color: Color(0xFFD4AF37)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Thanh Toán & Hóa Đơn',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: Colors.white12),
            const SizedBox(height: 8),

            // Customer & Barber info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Khách: ${widget.booking.customerName ?? "Khách #${widget.booking.customerId}"}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Mã: #${widget.booking.id}',
                  style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12),
                ),
              ],
            ),
            Text(
              'Thợ cắt: ${widget.booking.staffName}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),

            // Services breakdown
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  for (final service in widget.booking.services)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(service.name, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ),
                          Text(_formatPrice(service.price), style: const TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                  const Divider(color: Colors.white24, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TỔNG CỘNG:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(
                        _formatPrice(widget.booking.totalPrice),
                        style: const TextStyle(
                          color: Color(0xFFD4AF37),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              'Phương thức thanh toán:',
              style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),

            // Radio options
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _paymentMethod = 'cash'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: _paymentMethod == 'cash'
                            ? const Color(0xFFD4AF37).withOpacity(0.15)
                            : const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _paymentMethod == 'cash' ? const Color(0xFFD4AF37) : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.money,
                            color: _paymentMethod == 'cash' ? const Color(0xFFD4AF37) : Colors.white54,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tiền mặt',
                            style: TextStyle(
                              color: _paymentMethod == 'cash' ? Colors.white : Colors.white70,
                              fontWeight: _paymentMethod == 'cash' ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _paymentMethod = 'bank_transfer'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: _paymentMethod == 'bank_transfer'
                            ? const Color(0xFFD4AF37).withOpacity(0.15)
                            : const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _paymentMethod == 'bank_transfer' ? const Color(0xFFD4AF37) : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.qr_code,
                            color: _paymentMethod == 'bank_transfer' ? const Color(0xFFD4AF37) : Colors.white54,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Chuyển khoản QR',
                            style: TextStyle(
                              color: _paymentMethod == 'bank_transfer' ? Colors.white : Colors.white70,
                              fontWeight: _paymentMethod == 'bank_transfer' ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng', style: TextStyle(color: Colors.white54)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('Xác Nhận Ðã Thu Tiền', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _handleConfirmPayment,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
