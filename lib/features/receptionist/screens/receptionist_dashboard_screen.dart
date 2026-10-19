import 'package:flutter/material.dart';

import 'package:barber_booking_app/features/auth/screens/login_screen.dart';
import 'package:barber_booking_app/shared/services/mock_data_service.dart';

class ReceptionistDashboardScreen extends StatefulWidget {
  const ReceptionistDashboardScreen({super.key});

  @override
  State<ReceptionistDashboardScreen> createState() => _ReceptionistDashboardScreenState();
}

class _ReceptionistDashboardScreenState extends State<ReceptionistDashboardScreen> {
  final MockDataService _dataService = MockDataService();
  String _selectedFilter = 'all';

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
        return 'Đang cắt';
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
    final allBookings = _dataService.bookings;

    final filteredBookings = _selectedFilter == 'all'
        ? allBookings
        : allBookings.where((b) => b.status == _selectedFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng Điều Khiển Lễ Tân'),
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
      body: Column(
        children: [
          // Receptionist Banner
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1E1E1E),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Lê Thị Mai (Lễ Tân)',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Text(
                        'Role: Receptionist / Lễ Tân Salon',
                        style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Filters Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('Tất cả', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Đã xác nhận', 'confirmed'),
                const SizedBox(width: 8),
                _buildFilterChip('Đã Check-in', 'checked_in'),
                const SizedBox(width: 8),
                _buildFilterChip('Đang cắt', 'in_progress'),
                const SizedBox(width: 8),
                _buildFilterChip('Hoàn thành', 'completed'),
              ],
            ),
          ),

          // Bookings List
          Expanded(
            child: filteredBookings.isEmpty
                ? const Center(
                    child: Text('Không có lịch hẹn nào.', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredBookings.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final booking = filteredBookings[index];
                      final statusColor = _getStatusColor(booking.status);

                      // Check payment status from transactions
                      final txIdx = _dataService.transactions.indexWhere((t) => t.bookingId == booking.id);
                      final isPaid = txIdx != -1 && _dataService.transactions[txIdx].status == 'paid';

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
                                Text(
                                  'Mã: #${booking.id} • ${booking.startTime}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
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
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Barber: ${booking.staffName}',
                              style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Dịch vụ: ${booking.services.map((s) => s.name).join(', ')}',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tổng tiền: ${_formatPrice(booking.totalPrice)}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isPaid ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isPaid ? 'ĐÃ THU TIỀN' : 'CHƯA THU TIỀN',
                                    style: TextStyle(
                                      color: isPaid ? Colors.greenAccent : Colors.redAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              ],
                            ),
                            const Divider(color: Colors.white10, height: 20),

                            // Receptionist Actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (booking.status == 'confirmed')
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.qr_code_scanner, size: 16, color: Colors.black),
                                    label: const Text('Check-in Khách'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
                                    onPressed: () {
                                      _dataService.checkInBooking(booking.id);
                                    },
                                  ),
                                const SizedBox(width: 8),
                                if (!isPaid)
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.attach_money, size: 16, color: Colors.black),
                                    label: const Text('Thu Tiền'),
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
                                    onPressed: () {
                                      _dataService.markPaymentPaid(booking.id, 'cash');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Xác nhận đã thu ${_formatPrice(booking.totalPrice)} tiền mặt!'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFFD4AF37),
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      backgroundColor: const Color(0xFF1E1E1E),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
          });
        }
      },
    );
  }
}
