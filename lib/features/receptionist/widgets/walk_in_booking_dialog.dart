import 'package:flutter/material.dart';
import 'package:barber_booking_app/shared/models/barber_model.dart';
import 'package:barber_booking_app/shared/models/service_model.dart';
import 'package:barber_booking_app/shared/services/firebase_service.dart';

class WalkInBookingDialog extends StatefulWidget {
  final BarberModel? initialBarber;
  final DateTime? initialDate;
  final String? initialSlot;

  const WalkInBookingDialog({
    super.key,
    this.initialBarber,
    this.initialDate,
    this.initialSlot,
  });

  @override
  State<WalkInBookingDialog> createState() => _WalkInBookingDialogState();
}

class _WalkInBookingDialogState extends State<WalkInBookingDialog> {
  final FirebaseService _dataService = FirebaseService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  BarberModel? _selectedBarber;
  late DateTime _selectedDate;
  String? _selectedSlot;
  bool _immediateStart = true;
  final List<ServiceModel> _selectedServices = [];

  @override
  void initState() {
    super.initState();
    _selectedBarber = widget.initialBarber ??
        (_dataService.barbers.isNotEmpty ? _dataService.barbers.first : null);
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedSlot = widget.initialSlot ?? _dataService.allTimeSlots.first;

    // Default select first service
    if (_dataService.services.isNotEmpty) {
      _selectedServices.add(_dataService.services.first);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _totalPrice {
    return _selectedServices.fold<double>(0, (sum, s) => sum + s.price);
  }

  int get _totalDuration {
    return _selectedServices.fold<int>(0, (sum, s) => sum + s.durationMin);
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ';
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất 1 dịch vụ!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (_selectedBarber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn thợ cắt tóc!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final newBooking = _dataService.createWalkInBooking(
      customerName: _nameController.text.trim(),
      customerPhone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      barber: _selectedBarber!,
      selectedServices: List.from(_selectedServices),
      date: _selectedDate,
      timeSlot: _selectedSlot ?? '09:00',
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      immediateStart: _immediateStart,
    );

    Navigator.pop(context, newBooking);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _immediateStart
              ? 'Đã tạo lịch và xếp khách ${_nameController.text.trim()} vào ghế cắt ngay!'
              : 'Đã tạo lịch hẹn thành công cho ${_nameController.text.trim()}!',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final barbers = _dataService.barbers;
    final services = _dataService.services;
    final timeSlots = _dataService.allTimeSlots;

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person_add_alt_1, color: Color(0xFFD4AF37), size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Tiếp Nhận Khách Vãng Lai',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: Colors.white12, height: 16),

                // Content Form
                Expanded(
                  child: ListView(
                    children: [
                      // Section 1: Customer Information
                      const Text(
                        '1. Thông tin khách đến tiệm',
                        style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Họ tên khách *',
                          hintText: 'Ví dụ: Anh Hoàng, Anh Tuấn...',
                          prefixIcon: const Icon(Icons.badge, color: Colors.white70, size: 20),
                          filled: true,
                          fillColor: const Color(0xFF2A2A2A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? 'Vui lòng nhập tên khách' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _phoneController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Số điện thoại (tùy chọn)',
                          hintText: 'Ví dụ: 0912345678',
                          prefixIcon: const Icon(Icons.phone, color: Colors.white70, size: 20),
                          filled: true,
                          fillColor: const Color(0xFF2A2A2A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Section 2: Choose Services
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '2. Dịch vụ lựa chọn',
                            style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            '~${_totalDuration}p | ${_formatPrice(_totalPrice)}',
                            style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: services.map((s) {
                          final isSelected = _selectedServices.any((item) => item.id == s.id);
                          return FilterChip(
                            label: Text('${s.name} (${_formatPrice(s.price)})'),
                            selected: isSelected,
                            selectedColor: const Color(0xFFD4AF37),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            backgroundColor: const Color(0xFF2A2A2A),
                            checkmarkColor: Colors.black,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedServices.add(s);
                                } else {
                                  _selectedServices.removeWhere((item) => item.id == s.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Section 3: Select Barber
                      const Text(
                        '3. Gán thợ cắt tóc',
                        style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<BarberModel>(
                        value: _selectedBarber,
                        dropdownColor: const Color(0xFF2A2A2A),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF2A2A2A),
                          prefixIcon: const Icon(Icons.content_cut, color: Colors.white70, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isAvail ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isAvail ? 'Rảnh' : 'Đang bận',
                                    style: TextStyle(
                                      color: isAvail ? Colors.greenAccent : Colors.orangeAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedBarber = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Section 4: Time of Service
                      const Text(
                        '4. Thời gian cắt tóc',
                        style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Cắt ngay bây giờ (Khách đã có mặt)',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Hệ thống sẽ chuyển trạng thái thợ sang Đang phục vụ',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        value: _immediateStart,
                        activeColor: const Color(0xFFD4AF37),
                        onChanged: (val) {
                          setState(() {
                            _immediateStart = val;
                          });
                        },
                      ),

                      if (!_immediateStart) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedSlot,
                                dropdownColor: const Color(0xFF2A2A2A),
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Khung giờ hẹn',
                                  filled: true,
                                  fillColor: const Color(0xFF2A2A2A),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                items: timeSlots.map((slot) {
                                  return DropdownMenuItem<String>(
                                    value: slot,
                                    child: Text(slot),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedSlot = val;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 12),
                      // Section 5: Note
                      TextFormField(
                        controller: _noteController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Ghi chú kiểu tóc hoặc yêu cầu riêng',
                          hintText: 'Ví dụ: Cạo sát viền, không dùng tông đơ cạo trọc...',
                          prefixIcon: const Icon(Icons.note_alt, color: Colors.white70, size: 20),
                          filled: true,
                          fillColor: const Color(0xFF2A2A2A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 12),

                // Bottom Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tổng thanh toán:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text(
                          _formatPrice(_totalPrice),
                          style: const TextStyle(
                            color: Color(0xFFD4AF37),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Hủy bỏ', style: TextStyle(color: Colors.white54)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(
                            _immediateStart ? 'Xác Nhận & Vào Cắt' : 'Lưu Lịch Hẹn',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: _handleSubmit,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
