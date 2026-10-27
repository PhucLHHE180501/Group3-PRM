import 'package:flutter/material.dart';

import 'package:barber_booking_app/shared/models/barber_model.dart';
import 'package:barber_booking_app/shared/models/service_model.dart';
import 'package:barber_booking_app/shared/services/firebase_service.dart';
import '../profile/edit_profile_screen.dart';

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
  final FirebaseService _dataService = FirebaseService();

  late DateTime _selectedDate;
  late String _selectedTimeSlot;
  BarberModel? _selectedBarber;
  bool _autoAssignBarber = true; // True = Salon tự chọn thợ rảnh ngẫu nhiên
  final List<ServiceModel> _selectedServices = [];
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dataService.addListener(_onDataChanged);

    _selectedDate = DateTime.now();
    _selectedTimeSlot = _dataService.allTimeSlots.first; // Default '08:00' or '09:00'

    // Default select first service
    if (_dataService.services.isNotEmpty) {
      _selectedServices.add(_dataService.services.first);
    }

    // Silently pre-fill form from customer's last booking
    _loadLastCustomerPreferences();

    // If customer arrived from Barber Detail screen (overrides barber)
    if (widget.initialBarber != null) {
      _selectedBarber = widget.initialBarber;
      _autoAssignBarber = false;
    }
  }

  void _loadLastCustomerPreferences() {
    final user = _dataService.currentUser;
    if (user == null) return;

    final last = _dataService.getLastBookingForCustomer(user.id);
    if (last == null) return;

    // 1. Pre-fill time slot from last booking if valid
    if (_dataService.allTimeSlots.contains(last.startTime)) {
      _selectedTimeSlot = last.startTime;
    }

    // 2. Pre-fill services from last booking
    if (last.services.isNotEmpty) {
      _selectedServices.clear();
      for (final s in last.services) {
        final matchService = _dataService.services.firstWhere(
          (item) => item.id == s.id || item.name == s.name,
          orElse: () => s,
        );
        if (!_selectedServices.any((item) => item.id == matchService.id)) {
          _selectedServices.add(matchService);
        }
      }
    }

    // 3. Pre-fill barber choice from last booking if customer didn't pass initialBarber
    if (widget.initialBarber == null) {
      try {
        final prevBarber = _dataService.barbers.firstWhere((b) => b.userId == last.staffId);
        _selectedBarber = prevBarber;
        _autoAssignBarber = false;
      } catch (_) {
        _autoAssignBarber = true;
      }
    }
  }

  void _onDataChanged() {
    if (!mounted) return;
    setState(() {
      if (_selectedServices.isEmpty && _dataService.services.isNotEmpty) {
        _selectedServices.add(_dataService.services.first);
      }
    });
  }

  @override
  void dispose() {
    _dataService.removeListener(_onDataChanged);
    _noteController.dispose();
    super.dispose();
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ';
  }

  double get totalPrice {
    return _selectedServices.fold<double>(0, (sum, item) => sum + item.price);
  }

  int get totalDurationMin {
    return _selectedServices.fold<int>(0, (sum, item) => sum + item.durationMin);
  }

  int get requiredSlotsCount {
    final count = (totalDurationMin / 60.0).ceil();
    return count < 1 ? 1 : count;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _checkAndAdjustTimeSlot() {
    final currentReq = _dataService.getRequiredSlots(_selectedTimeSlot, requiredSlotsCount);
    final currentAvail = currentReq != null
        ? _dataService.getAvailableBarbers(_selectedDate, _selectedTimeSlot, requiredSlotsCount: requiredSlotsCount)
        : <BarberModel>[];

    if (currentAvail.isEmpty) {
      for (final slot in _dataService.allTimeSlots) {
        final req = _dataService.getRequiredSlots(slot, requiredSlotsCount);
        if (req != null) {
          final avail = _dataService.getAvailableBarbers(_selectedDate, slot, requiredSlotsCount: requiredSlotsCount);
          if (avail.isNotEmpty) {
            _selectedTimeSlot = slot;
            break;
          }
        }
      }
    }
  }

  void _confirmBooking() {
    // 1. Verify Customer Profile info (Must have Name & Phone)
    final user = _dataService.currentUser;
    if (user == null || !user.hasRequiredProfileInfo) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFD4AF37), size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text('Yêu Cầu Thông Tin', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: const Text(
            'Để salon tiện liên hệ xác nhận lịch hẹn, bạn vui lòng bổ sung Họ tên & Số điện thoại trong hồ sơ trước khi đặt lịch nhé!',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                );
              },
              child: const Text('Cập Nhật Ngay', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 dịch vụ!')),
      );
      return;
    }

    final reqSlots = _dataService.getRequiredSlots(_selectedTimeSlot, requiredSlotsCount);
    if (reqSlots == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Khung giờ $_selectedTimeSlot không đủ $requiredSlotsCount khung giờ liên tiếp ($totalDurationMin phút) trong ngày!',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Get list of free barbers for the chosen date, time slot & required consecutive slots
    final availableBarbers = _dataService.getAvailableBarbers(
      _selectedDate,
      _selectedTimeSlot,
      requiredSlotsCount: requiredSlotsCount,
    );

    if (availableBarbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            requiredSlotsCount > 1
                ? 'Không có thợ nào rảnh đủ $requiredSlotsCount khung giờ liên tiếp vào lúc $_selectedTimeSlot. Vui lòng chọn khung giờ khác!'
                : 'Tất cả thợ đều đã kín lịch vào lúc $_selectedTimeSlot. Vui lòng chọn khung giờ khác!',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Determine final assigned barber
    BarberModel finalBarber;
    if (_autoAssignBarber || _selectedBarber == null) {
      finalBarber = availableBarbers.first;
    } else {
      // Check if selected barber is still free at this slot
      final isStillFree = availableBarbers.any((b) => b.userId == _selectedBarber!.userId);
      if (isStillFree) {
        finalBarber = _selectedBarber!;
      } else {
        finalBarber = availableBarbers.first;
      }
    }

    final booking = _dataService.createBooking(
      barber: finalBarber,
      selectedServices: _selectedServices,
      date: _selectedDate,
      timeSlot: _selectedTimeSlot,
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
            Text('Barber phục vụ: ${booking.staffName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text('Ngày đặt: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: const TextStyle(color: Colors.white)),
            Text(
              requiredSlotsCount > 1
                  ? 'Khung giờ: ${booking.startTime} - ${booking.endTime} ($requiredSlotsCount slot liên tiếp)'
                  : 'Khung giờ: ${booking.startTime} - ${booking.endTime}',
              style: const TextStyle(color: Colors.white),
            ),
            Text('Dịch vụ: ${_selectedServices.map((s) => s.name).join(", ")}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            Text('Tổng tiền: ${_formatPrice(booking.totalPrice)}', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Back to previous screen
            },
            child: const Text('Hoàn Tất', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = _dataService.services;
    final timeSlots = _dataService.allTimeSlots;

    // Filter ONLY barbers who are FREE at selected date & time
    final availableBarbers = _dataService.getAvailableBarbers(
      _selectedDate,
      _selectedTimeSlot,
      requiredSlotsCount: requiredSlotsCount,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt Lịch Cắt Tóc'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // STEP 1: SELECT SERVICES
            const Text(
              '1. Chọn Dịch Vụ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD4AF37),
              ),
            ),
            if (_selectedServices.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_filled, color: Color(0xFFD4AF37), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        requiredSlotsCount > 1
                            ? 'Tổng thời gian: $totalDurationMin phút ➔ Cần $requiredSlotsCount khung giờ liên tiếp'
                            : 'Tổng thời gian: $totalDurationMin phút (1 khung giờ)',
                        style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
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
                      _checkAndAdjustTimeSlot();
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // STEP 2: SELECT DATE & TIME SLOT
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '2. Chọn Ngày & Khung Giờ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4AF37),
                  ),
                ),
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Quick Date Buttons Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: _isSameDay(_selectedDate, DateTime.now())
                            ? const Color(0xFFD4AF37)
                            : Colors.white24,
                      ),
                      foregroundColor: _isSameDay(_selectedDate, DateTime.now())
                          ? const Color(0xFFD4AF37)
                          : Colors.white70,
                    ),
                    icon: const Icon(Icons.today, size: 16),
                    label: const Text('Hôm nay', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      setState(() {
                        _selectedDate = DateTime.now();
                        _checkAndAdjustTimeSlot();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: _isSameDay(_selectedDate, DateTime.now().add(const Duration(days: 1)))
                            ? const Color(0xFFD4AF37)
                            : Colors.white24,
                      ),
                      foregroundColor: _isSameDay(_selectedDate, DateTime.now().add(const Duration(days: 1)))
                          ? const Color(0xFFD4AF37)
                          : Colors.white70,
                    ),
                    icon: const Icon(Icons.event, size: 16),
                    label: const Text('Ngày mai', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      setState(() {
                        _selectedDate = DateTime.now().add(const Duration(days: 1));
                        _checkAndAdjustTimeSlot();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit_calendar, color: Color(0xFFD4AF37)),
                  tooltip: 'Chọn ngày khác',
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
                        _checkAndAdjustTimeSlot();
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Time Slots Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.2,
              ),
              itemCount: timeSlots.length,
              itemBuilder: (context, index) {
                final slot = timeSlots[index];
                final isSelected = _selectedTimeSlot == slot;

                final reqSlots = _dataService.getRequiredSlots(slot, requiredSlotsCount);
                final isEnoughSlotsLeft = reqSlots != null;
                final availableBarbersForSlot = isEnoughSlotsLeft
                    ? _dataService.getAvailableBarbers(_selectedDate, slot, requiredSlotsCount: requiredSlotsCount)
                    : <BarberModel>[];
                final isSlotAvailable = availableBarbersForSlot.isNotEmpty;

                return GestureDetector(
                  onTap: () {
                    if (!isEnoughSlotsLeft) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Khung giờ $slot không đủ $requiredSlotsCount khung giờ liên tiếp ($totalDurationMin phút) trong ngày!',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    if (!isSlotAvailable) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            requiredSlotsCount > 1
                                ? 'Tất cả thợ đều bận trong $requiredSlotsCount khung giờ liên tiếp từ $slot!'
                                : 'Tất cả thợ đều đã có khách vào lúc $slot!',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    setState(() {
                      _selectedTimeSlot = slot;
                    });
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFD4AF37)
                          : isSlotAvailable
                              ? const Color(0xFF1E1E1E)
                              : const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFD4AF37)
                            : isSlotAvailable
                                ? Colors.white12
                                : Colors.red.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      slot,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.black
                            : isSlotAvailable
                                ? Colors.white
                                : Colors.white30,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        decoration: !isSlotAvailable ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // STEP 3: SELECT BARBER AVAILABLE AT SELECTED DATE & TIME
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '3. Chọn Thợ Barber Phục Vụ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4AF37),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.greenAccent),
                  ),
                  child: Text(
                    '${availableBarbers.length} thợ rảnh',
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              requiredSlotsCount > 1
                  ? 'Danh sách thợ RẢNH $requiredSlotsCount slot liên tiếp từ $_selectedTimeSlot ngày ${_selectedDate.day}/${_selectedDate.month}:'
                  : 'Danh sách thợ RẢNH lúc $_selectedTimeSlot ngày ${_selectedDate.day}/${_selectedDate.month}:',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),

            if (availableBarbers.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.event_busy, color: Colors.redAccent, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      requiredSlotsCount > 1
                          ? 'Rất tiếc! Không có thợ nào rảnh đủ $requiredSlotsCount khung giờ liên tiếp từ $_selectedTimeSlot.'
                          : 'Rất tiếc! Tất cả thợ đều đã có khách vào lúc $_selectedTimeSlot.',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Vui lòng chọn khung giờ khác ở Bước 2 để tiếp tục!',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else ...[
              // Option 1: Auto Assign Barber
              InkWell(
                onTap: () {
                  setState(() {
                    _autoAssignBarber = true;
                    _selectedBarber = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _autoAssignBarber ? const Color(0xFFD4AF37).withOpacity(0.15) : const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _autoAssignBarber ? const Color(0xFFD4AF37) : Colors.white10,
                      width: _autoAssignBarber ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _autoAssignBarber ? const Color(0xFFD4AF37) : const Color(0xFF2A2A2A),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.shuffle,
                          color: _autoAssignBarber ? Colors.black : Colors.white70,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Salon tự xếp thợ (Rảnh ngẫu nhiên)',
                              style: TextStyle(
                                color: _autoAssignBarber ? const Color(0xFFD4AF37) : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const Text(
                              'Hệ thống tự động phân công thợ rảnh phục vụ bạn nhanh nhất',
                              style: TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      if (_autoAssignBarber)
                        const Icon(Icons.check_circle, color: Color(0xFFD4AF37), size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Option 2: Choose Specific Free Barber
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: availableBarbers.length,
                  itemBuilder: (context, index) {
                    final barber = availableBarbers[index];
                    final isSelected = !_autoAssignBarber && _selectedBarber?.userId == barber.userId;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _autoAssignBarber = false;
                          _selectedBarber = barber;
                        });
                      },
                      child: Container(
                        width: 130,
                        margin: const EdgeInsets.only(right: 10),
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
                              child: barber.avatarUrl == null ? const Icon(Icons.person, size: 20) : null,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              barber.fullName.split('(').first.trim(),
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
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                requiredSlotsCount > 1
                                    ? 'Rảnh $requiredSlotsCount slot từ $_selectedTimeSlot'
                                    : 'Rảnh lúc $_selectedTimeSlot',
                                style: const TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 24),

            // STEP 4: NOTE
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: _confirmBooking,
                  child: const Text('XÁC NHẬN ĐẶT LỊCH', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
