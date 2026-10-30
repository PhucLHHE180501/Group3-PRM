import 'package:flutter/material.dart';
import 'package:barber_booking_app/shared/models/barber_model.dart';
import 'package:barber_booking_app/shared/models/booking_model.dart';
import 'package:barber_booking_app/shared/services/firebase_service.dart';

class SalonScheduleGrid extends StatefulWidget {
  final Function(BarberModel barber, DateTime date, String slot) onBookSlot;
  final Function(BookingModel booking) onBookingTap;

  const SalonScheduleGrid({
    super.key,
    required this.onBookSlot,
    required this.onBookingTap,
  });

  @override
  State<SalonScheduleGrid> createState() => _SalonScheduleGridState();
}

class _SalonScheduleGridState extends State<SalonScheduleGrid> {
  final FirebaseService _dataService = FirebaseService();
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'Hôm nay (${date.day}/${date.month})';
    if (_isSameDay(date, now.add(const Duration(days: 1)))) return 'Ngày mai (${date.day}/${date.month})';
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'in_progress':
        return Colors.blueAccent;
      case 'checked_in':
        return Colors.purpleAccent;
      case 'confirmed':
        return const Color(0xFFD4AF37);
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orangeAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final barbers = _dataService.barbers;
    final timeSlots = _dataService.allTimeSlots;
    final dateBookings = _dataService.getBookingsForDate(_selectedDate);

    // Calculate occupancy
    final totalPossibleSlots = barbers.length * timeSlots.length;
    final occupiedSlots = dateBookings.length;
    final occupancyPercent = totalPossibleSlots > 0
        ? (occupiedSlots / totalPossibleSlots * 100).toStringAsFixed(1)
        : '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Selector Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: const Color(0xFF1E1E1E),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: Color(0xFFD4AF37), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatDateHeader(_selectedDate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Quick date chips
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 16),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                  });
                },
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime.now();
                  });
                },
                child: const Text('Hôm nay', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 13)),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.add(const Duration(days: 1));
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit_calendar, color: Color(0xFFD4AF37), size: 20),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFFD4AF37),
                            onPrimary: Colors.black,
                            surface: Color(0xFF1E1E1E),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
              ),
            ],
          ),
        ),

        // Statistics / Occupancy bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFF141414),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                'Lịch đã xếp: $occupiedSlots / $totalPossibleSlots slot ($occupancyPercent%)',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Text(
                'Chạm ô để xếp khách hoặc xem chi tiết',
                style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        // Legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildLegendItem('Trống (Bấm để xếp)', Colors.white24),
              _buildLegendItem('Đã hẹn', const Color(0xFFD4AF37)),
              _buildLegendItem('Đã check-in', Colors.purpleAccent),
              _buildLegendItem('Đang cắt', Colors.blueAccent),
              _buildLegendItem('Xong', Colors.green),
            ],
          ),
        ),

        const Divider(color: Colors.white12, height: 1),

        // Schedule Grid Table
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Table(
                  defaultColumnWidth: const FixedColumnWidth(130),
                  columnWidths: const {
                    0: FixedColumnWidth(70), // Column for Time slot
                  },
                  border: TableBorder.all(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  children: [
                    // Table Header: Barbers
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFF252525)),
                      children: [
                        const TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                            child: Text(
                              'Giờ',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        for (final barber in barbers)
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage: barber.avatarUrl != null ? NetworkImage(barber.avatarUrl!) : null,
                                    child: barber.avatarUrl == null ? const Icon(Icons.person, size: 16) : null,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    barber.fullName.split('(').first.trim(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Table Body: Time Slots x Barbers
                    for (final slot in timeSlots)
                      TableRow(
                        decoration: const BoxDecoration(
                          color: Color(0xFF191919),
                        ),
                        children: [
                          // Time Cell
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.middle,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              color: const Color(0xFF202020),
                              child: Text(
                                slot,
                                style: const TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),

                          // Barber Slots
                          for (final barber in barbers) ...[
                            _buildSlotCell(
                              barber: barber,
                              slot: slot,
                              bookings: dateBookings,
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildSlotCell({
    required BarberModel barber,
    required String slot,
    required List<BookingModel> bookings,
  }) {
    // Find matching booking for this barber and time slot
    final match = bookings.cast<BookingModel?>().firstWhere(
      (b) => b != null && b.staffId == barber.userId && _dataService.getOccupiedSlotsForBooking(b).contains(slot),
      orElse: () => null,
    );

    if (match == null) {
      // Slot is Available!
      return TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: InkWell(
          onTap: () => widget.onBookSlot(barber, _selectedDate, slot),
          child: Container(
            height: 60,
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white12, style: BorderStyle.solid),
            ),
            child: const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.greenAccent, size: 14),
                  SizedBox(width: 2),
                  Text('Trống', style: TextStyle(color: Colors.greenAccent, fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Slot is Booked!
    final statusColor = _getStatusColor(match.status);

    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: InkWell(
        onTap: () => widget.onBookingTap(match),
        child: Container(
          height: 60,
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.18),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: statusColor, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      match.customerName ?? 'Khách #${match.customerId}',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (match.isWalkIn)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text('Tại quầy', style: TextStyle(color: Colors.orangeAccent, fontSize: 8)),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                match.services.isNotEmpty ? match.services.first.name : 'Dịch vụ',
                style: const TextStyle(color: Colors.white70, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
