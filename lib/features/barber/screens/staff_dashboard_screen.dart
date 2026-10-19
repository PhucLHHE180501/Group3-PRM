import 'package:flutter/material.dart';

import 'package:barber_booking_app/features/auth/screens/login_screen.dart';
import 'package:barber_booking_app/shared/services/mock_data_service.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  final MockDataService _dataService = MockDataService();

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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'checked_in':
        return Colors.purpleAccent;
      case 'confirmed':
        return const Color(0xFFD4AF37);
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'checked_in':
        return 'Đã Check-in';
      case 'in_progress':
        return 'Đang cắt tóc';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _dataService.currentUser;
    final staffId = user?.id ?? 101;
    final barberBookings = _dataService.getBarberBookings(staffId);

    final barberObj = _dataService.barbers.firstWhere(
      (b) => b.userId == staffId,
      orElse: () => _dataService.barbers.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng Điều Khiển Barber'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () {
              _dataService.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? 'Trần Văn Quốc',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const Text(
                              'Role: Barber / Thợ Cắt Tóc',
                              style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '⭐ ${barberObj.avgRating} (${barberObj.reviewCount} đánh giá)',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Trạng thái làm việc:',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      DropdownButton<String>(
                        value: barberObj.status,
                        dropdownColor: const Color(0xFF2C2C2C),
                        style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'available', child: Text('🟢 Đang rảnh (Available)')),
                          DropdownMenuItem(value: 'busy', child: Text('🔴 Đang bận (Busy)')),
                          DropdownMenuItem(value: 'break', child: Text('🟡 Nghỉ giải lao (Break)')),
                          DropdownMenuItem(value: 'off', child: Text('⚪ Tan ca (Off)')),
                        ],
                        onChanged: (newStatus) {
                          if (newStatus != null) {
                            _dataService.updateBarberStatus(staffId, newStatus);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lịch Hẹn Cắt Tóc Hôm Nay',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${barberBookings.length} Lịch',
                    style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (barberBookings.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text('Chưa có lịch hẹn nào được phân công.', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: barberBookings.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final booking = barberBookings[index];
                  final statusColor = _getStatusColor(booking.status);

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.access_time, color: Color(0xFFD4AF37), size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  booking.startTime,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: statusColor),
                              ),
                              child: Text(
                                _getStatusText(booking.status),
                                style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Mã cuộc hẹn: #${booking.id}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dịch vụ: ${booking.services.map((s) => s.name).join(', ')}',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        if (booking.note != null && booking.note!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Ghi chú: ${booking.note}',
                            style: const TextStyle(color: Colors.amberAccent, fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          'Giá tiền: ${_formatPrice(booking.totalPrice)}',
                          style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
                        ),
                        const Divider(color: Colors.white10, height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (booking.status != 'in_progress' && booking.status != 'completed' && booking.status != 'cancelled')
                              OutlinedButton.icon(
                                icon: const Icon(Icons.play_arrow, size: 16),
                                label: const Text('Bắt Đầu Cắt'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  side: const BorderSide(color: Colors.blue),
                                ),
                                onPressed: () {
                                  _dataService.updateBookingStatus(booking.id, 'in_progress');
                                },
                              ),
                            const SizedBox(width: 8),
                            if (booking.status == 'in_progress')
                              ElevatedButton.icon(
                                icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.black),
                                label: const Text('Hoàn Thành'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                onPressed: () {
                                  _dataService.updateBookingStatus(booking.id, 'completed');
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
