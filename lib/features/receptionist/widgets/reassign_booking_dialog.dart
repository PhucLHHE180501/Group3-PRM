import 'package:flutter/material.dart';
import 'package:barber_booking_app/shared/models/barber_model.dart';
import 'package:barber_booking_app/shared/models/booking_model.dart';
import 'package:barber_booking_app/shared/services/mock_data_service.dart';

class ReassignBookingDialog extends StatefulWidget {
  final BookingModel booking;

  const ReassignBookingDialog({
    super.key,
    required this.booking,
  });

  @override
  State<ReassignBookingDialog> createState() => _ReassignBookingDialogState();
}

class _ReassignBookingDialogState extends State<ReassignBookingDialog> {
  final MockDataService _dataService = MockDataService();
  late BarberModel _selectedBarber;
  late String _selectedSlot;
  final TextEditingController _cancelReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedBarber = _dataService.barbers.firstWhere(
      (b) => b.userId == widget.booking.staffId,
      orElse: () => _dataService.barbers.first,
    );
    _selectedSlot = widget.booking.startTime;
  }

  @override
  void dispose() {
    _cancelReasonController.dispose();
    super.dispose();
  }

  void _handleSave() {
    bool hasChanged = false;

    // Check barber change
    if (_selectedBarber.userId != widget.booking.staffId) {
      _dataService.reassignBookingBarber(widget.booking.id, _selectedBarber);
      hasChanged = true;
    }

    // Check slot change
    if (_selectedSlot != widget.booking.startTime) {
      _dataService.rescheduleBooking(widget.booking.id, widget.booking.bookingDate, _selectedSlot);
      hasChanged = true;
    }

    Navigator.pop(context, true);

    if (hasChanged) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã cập nhật lịch #${widget.booking.id}: Thợ ${_selectedBarber.fullName}, Giờ $_selectedSlot'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _handleCancelBooking() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Xác nhận hủy lịch hẹn?', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đơn của: ${widget.booking.customerName ?? "Khách #${widget.booking.customerId}"}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cancelReasonController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Lý do hủy (tùy chọn)',
                hintText: 'Ví dụ: Khách bận đột xuất, không liên lạc được...',
                filled: true,
                fillColor: Color(0xFF2A2A2A),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Không', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx); // Close alert dialog
              Navigator.pop(context, true); // Close reassign dialog
              _dataService.cancelBooking(
                widget.booking.id,
                reason: _cancelReasonController.text.trim(),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã hủy lịch #${widget.booking.id}'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            child: const Text('Xác Nhận Hủy', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final barbers = _dataService.barbers;
    final timeSlots = _dataService.allTimeSlots;

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
                Row(
                  children: [
                    const Icon(Icons.sync_alt, color: Color(0xFFD4AF37)),
                    const SizedBox(width: 8),
                    Text(
                      'Điều Phối Lịch #${widget.booking.id}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: Colors.white12),
            const SizedBox(height: 8),

            Text(
              'Khách hàng: ${widget.booking.customerName ?? "Khách #${widget.booking.customerId}"}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            if (widget.booking.customerPhone != null)
              Text(
                'SĐT: ${widget.booking.customerPhone}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            Text(
              'Dịch vụ: ${widget.booking.services.map((s) => s.name).join(", ")}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 16),

            // Dropdown change barber
            const Text('Chuyển thợ cắt:', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<BarberModel>(
              value: _selectedBarber,
              dropdownColor: const Color(0xFF2A2A2A),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: barbers.map((b) {
                final status = _dataService.getBarberDynamicStatus(b.userId);
                final isAvail = status == 'available';
                return DropdownMenuItem<BarberModel>(
                  value: b,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: b.avatarUrl != null ? NetworkImage(b.avatarUrl!) : null,
                        child: b.avatarUrl == null ? const Icon(Icons.person, size: 14) : null,
                      ),
                      const SizedBox(width: 8),
                      Text(b.fullName),
                      const SizedBox(width: 8),
                      Text(
                        isAvail ? '(Rảnh)' : '(Đang bận)',
                        style: TextStyle(
                          color: isAvail ? Colors.greenAccent : Colors.orangeAccent,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedBarber = val);
              },
            ),
            const SizedBox(height: 14),

            // Dropdown change slot
            const Text('Đổi khung giờ:', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedSlot,
              dropdownColor: const Color(0xFF2A2A2A),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: timeSlots.map((slot) {
                return DropdownMenuItem<String>(
                  value: slot,
                  child: Text(slot),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedSlot = val);
              },
            ),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Hủy Lịch Hẹn'),
                  onPressed: _handleCancelBooking,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: _handleSave,
                  child: const Text('Lưu Thay Đổi', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
