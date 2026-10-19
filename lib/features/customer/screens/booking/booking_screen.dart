import 'package:flutter/material.dart';

import 'package:barber_booking_app/shared/models/barber_model.dart';
import 'package:barber_booking_app/shared/models/service_model.dart';
import 'package:barber_booking_app/shared/services/mock_data_service.dart';

class BookingScreen extends StatefulWidget {
  final BarberModel? initialBarber;

  const BookingScreen({
    super.key,
    this.initialBarber,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final MockDataService _dataService = MockDataService();

  BarberModel? _selectedBarber;
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  final List<ServiceModel> _selectedServices = [];
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedBarber = widget.initialBarber ?? (_dataService.barbers.isNotEmpty ? _dataService.barbers.first : null);
    // Pre-select first service by default
    if (_dataService.services.isNotEmpty) {
      _selectedServices.add(_dataService.services.first);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ';
  }

  double get totalPrice {
    return _selectedServices.fold<double>(0, (sum, item) => sum + item.price);
  }

  void _confirmBooking() {
    if (_selectedBarber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn Barber cắt tóc!')),
      );
      return;
    }

    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 dịch vụ!')),
      );
      return;
    }

    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn khung giờ hẹn còn trống!')),
      );
      return;
    }

    final booking = _dataService.createBooking(
      barber: _selectedBarber!,
      selectedServices: _selectedServices,
      date: _selectedDate,
      timeSlot: _selectedTimeSlot!,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text('Đặt Lịch Thành Công!', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mã cuộc hẹn: #${booking.id}', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Barber: ${booking.staffName}', style: const TextStyle(color: Colors.white)),
            Text('Ngày đặt: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: const TextStyle(color: Colors.white)),
            Text('Khung giờ: ${booking.startTime}', style: const TextStyle(color: Colors.white)),
            Text('Tổng tiền: ${_formatPrice(booking.totalPrice)}', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Back to previous screen
            },
            child: const Text('Hoàn Tất'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final barbers = _dataService.barbers;
    final services = _dataService.services;

    // Get ONLY AVAILABLE time slots that are NOT booked by another customer
    final availableTimeSlots = _selectedBarber != null
        ? _dataService.getAvailableTimeSlots(_selectedBarber!.userId, _selectedDate)
        : <String>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt Lịch Cắt Tóc'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step 1: Choose Barber
            const Text(
              '1. Chọn Barber Cắt Tóc',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD4AF37),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: barbers.length,
                itemBuilder: (context, index) {
                  final barber = barbers[index];
                  final isSelected = _selectedBarber?.userId == barber.userId;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedBarber = barber;
                        _selectedTimeSlot = null; // reset slot when barber changes
                      });
                    },
                    child: Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFD4AF37) : Colors.white10,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundImage: barber.avatarUrl != null
                                ? NetworkImage(barber.avatarUrl!)
                                : null,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            barber.fullName,
                            style: TextStyle(
                              color: isSelected ? const Color(0xFFD4AF37) : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star, color: Color(0xFFD4AF37), size: 12),
                              const SizedBox(width: 2),
                              Text(
                                '${barber.avgRating}',
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Step 2: Choose Services
            const Text(
              '2. Chọn Dịch Vụ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD4AF37),
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: services.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final service = services[index];
                final isSelected = _selectedServices.any((s) => s.id == service.id);

                return CheckboxListTile(
                  value: isSelected,
                  activeColor: const Color(0xFFD4AF37),
                  checkColor: Colors.black,
                  tileColor: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFFD4AF37) : Colors.white10,
                    ),
                  ),
                  title: Text(
                    service.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    '${_formatPrice(service.price)} • ${service.durationMin} phút',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  onChanged: (bool? checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedServices.add(service);
                      } else {
                        _selectedServices.removeWhere((s) => s.id == service.id);
                      }
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // Step 3: Choose Date & Available Slot
            const Text(
              '3. Chọn Ngày & Khung Giờ Còn Trống',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD4AF37),
              ),
            ),
            const SizedBox(height: 8),
            // Date Picker Row
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFFD4AF37), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Ngày cắt: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                        _selectedTimeSlot = null; // reset slot
                      });
                    }
                  },
                  child: const Text('Đổi Ngày'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Available Time Slots Grid
            if (availableTimeSlots.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: const Text(
                  'Barber đã kín lịch tất cả các khung giờ ngày này. Vui lòng chọn ngày hoặc Barber khác!',
                  style: TextStyle(color: Colors.redAccent, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.2,
                ),
                itemCount: availableTimeSlots.length,
                itemBuilder: (context, index) {
                  final slot = availableTimeSlots[index];
                  final isSelected = _selectedTimeSlot == slot;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTimeSlot = slot;
                      });
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFD4AF37) : Colors.white12,
                        ),
                      ),
                      child: Text(
                        slot,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),

            // Step 4: Note
            const Text(
              'Ghi Chú Cho Barber (Tùy chọn)',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'VD: Cắt gọn gàng, sấy phồng nhẹ...',
              ),
            ),
            const SizedBox(height: 100), // Bottom padding
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tổng thanh toán:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  _formatPrice(totalPrice),
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _confirmBooking,
                  child: const Text('Xác Nhận Đặt Lịch'),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
