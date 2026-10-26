import 'package:flutter/material.dart';

import '../../auth/screens/login_screen.dart';
import '../widgets/barber_status_card.dart';
import '../widgets/quick_checkout_dialog.dart';
import '../widgets/reassign_booking_dialog.dart';
import '../widgets/salon_schedule_grid.dart';
import '../widgets/walk_in_booking_dialog.dart';
import '../../../shared/models/barber_model.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/services/firebase_service.dart';

class ReceptionistDashboardScreen extends StatefulWidget {
  const ReceptionistDashboardScreen({super.key});

  @override
  State<ReceptionistDashboardScreen> createState() => _ReceptionistDashboardScreenState();
}

class _ReceptionistDashboardScreenState extends State<ReceptionistDashboardScreen> {
  final FirebaseService _dataService = FirebaseService();
  int _currentIndex = 0;

  String _selectedStatusFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dataService.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  // Open Walk-in dialog
  void _openWalkInDialog({BarberModel? barber, DateTime? date, String? slot}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WalkInBookingDialog(
        initialBarber: barber,
        initialDate: date,
        initialSlot: slot,
      ),
    );
  }

  // Open Reassign / Reschedule dialog
  void _openReassignDialog(BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => ReassignBookingDialog(booking: booking),
    );
  }

  // Open Quick Checkout dialog
  void _openCheckoutDialog(BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => QuickCheckoutDialog(booking: booking),
    );
  }

  // View individual barber schedule modal
  void _viewBarberSchedule(BarberModel barber) {
    final now = DateTime.now();
    final barberBookings = _dataService.getBarberBookings(barber.userId).where((b) {
      return b.bookingDate.year == now.year &&
          b.bookingDate.month == now.month &&
          b.bookingDate.day == now.day &&
          b.status != 'cancelled';
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: barber.avatarUrl != null ? NetworkImage(barber.avatarUrl!) : null,
                    child: barber.avatarUrl == null ? const Icon(Icons.person, size: 20) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          barber.fullName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Lịch làm việc hôm nay (${now.day}/${now.month})',
                          style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12),
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
              const Divider(color: Colors.white12, height: 20),
              if (barberBookings.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Thợ chưa có ca hẹn nào hôm nay.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: barberBookings.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final b = barberBookings[idx];
                      final color = _getStatusColor(b.status);
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: color.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${b.startTime} - ${b.customerName ?? "Khách #${b.customerId}"}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  b.services.map((s) => s.name).join(', '),
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getStatusText(b.status),
                                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _dataService.currentUser;
    final allBookings = _dataService.bookings;

    // Filter bookings by status & search
    final filteredBookings = allBookings.where((b) {
      final matchStatus = _selectedStatusFilter == 'all' || b.status == _selectedStatusFilter;
      final query = _searchQuery.toLowerCase().trim();
      final matchSearch = query.isEmpty ||
          b.id.toString().contains(query) ||
          (b.customerName != null && b.customerName!.toLowerCase().contains(query)) ||
          (b.customerPhone != null && b.customerPhone!.contains(query)) ||
          b.staffName.toLowerCase().contains(query);
      return matchStatus && matchSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF2A2A2A),
            child: (user?.avatarUrl != null && user!.avatarUrl!.trim().isNotEmpty)
                ? ClipOval(
                    child: Image.network(
                      user.avatarUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.storefront,
                        color: Color(0xFFD4AF37),
                        size: 20,
                      ),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFD4AF37),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.storefront,
                    color: Color(0xFFD4AF37),
                    size: 20,
                  ),
          ),
          title: Text(
            user?.fullName ?? 'Lê Thị Mai (Lễ Tân)',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: const Text(
            'Lễ Tân Điều Phối Salon',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 11,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: 'Làm mới dữ liệu',
            onPressed: () => setState(() {}),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Đăng xuất',
            onPressed: () {
              _dataService.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFD4AF37),
        foregroundColor: Colors.black,
        elevation: 6,
        icon: const Icon(Icons.person_add_alt_1, size: 20),
        label: const Text(
          'Tiếp Khách Vãng Lai',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        onPressed: () => _openWalkInDialog(),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // TAB 0: SALON SCHEDULE MATRIX
          SalonScheduleGrid(
            onBookSlot: (barber, date, slot) {
              _openWalkInDialog(barber: barber, date: date, slot: slot);
            },
            onBookingTap: (booking) {
              _showBookingDetailSheet(booking);
            },
          ),

          // TAB 1: BARBERS MONITOR
          _buildBarbersMonitorTab(),

          // TAB 2: BOOKINGS LIST & CASHIER
          _buildBookingsHubTab(filteredBookings),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white12, width: 0.8)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: const Color(0xFF1E1E1E),
          selectedItemColor: const Color(0xFFD4AF37),
          unselectedItemColor: Colors.white54,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_on),
              activeIcon: Icon(Icons.grid_on, color: Color(0xFFD4AF37)),
              label: 'Lưới Lịch Quán',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group),
              activeIcon: Icon(Icons.group, color: Color(0xFFD4AF37)),
              label: 'Trạng Thái Thợ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              activeIcon: Icon(Icons.list_alt, color: Color(0xFFD4AF37)),
              label: 'Đón Tiếp Đơn',
            ),
          ],
        ),
      ),
    );
  }

  // TAB 2: BARBERS MONITOR
  Widget _buildBarbersMonitorTab() {
    final barbers = _dataService.barbers;
    final availableCount = barbers.where((b) => _dataService.getBarberDynamicStatus(b.userId) == 'available').length;
    final busyCount = barbers.where((b) => _dataService.getBarberDynamicStatus(b.userId) == 'busy').length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats Overview Bar
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Tổng Số Thợ',
                value: '${barbers.length}',
                color: Colors.white,
                icon: Icons.people,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: 'Đang Rảnh',
                value: '$availableCount',
                color: Colors.greenAccent,
                icon: Icons.check_circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: 'Đang Cắt',
                value: '$busyCount',
                color: Colors.orangeAccent,
                icon: Icons.content_cut,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        const Text(
          'Giám sát thợ cắt tóc thời gian thực:',
          style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 10),

        // Barber Cards
        for (final barber in barbers) ...[
          BarberStatusCard(
            barber: barber,
            onQuickAssign: () => _openWalkInDialog(barber: barber),
            onViewSchedule: () => _viewBarberSchedule(barber),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
    );
  }

  // TAB 3: BOOKINGS LIST & CASHIER
  Widget _buildBookingsHubTab(List<BookingModel> bookings) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Tìm theo SĐT, Tên khách hoặc Mã booking...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37), size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white12),
              ),
            ),
            onChanged: (val) {
              setState(() => _searchQuery = val);
            },
          ),
        ),

        // Filter chips bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              const SizedBox(width: 8),
              _buildFilterChip('Đã hủy', 'cancelled'),
            ],
          ),
        ),

        // Bookings List
        Expanded(
          child: bookings.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, color: Colors.white24, size: 48),
                      SizedBox(height: 10),
                      Text('Không tìm thấy lịch hẹn phù hợp.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: bookings.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return _buildBookingCard(booking);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    final statusColor = _getStatusColor(booking.status);
    final txIdx = _dataService.transactions.indexWhere((t) => t.bookingId == booking.id);
    final isPaid = txIdx != -1 && _dataService.transactions[txIdx].status == 'paid';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '#${booking.id} • ${booking.startTime}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  if (booking.isWalkIn) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orangeAccent),
                      ),
                      child: const Text(
                        'Walk-in Tại Quầy',
                        style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
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
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Customer info
          Row(
            children: [
              const Icon(Icons.person, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                booking.customerName ?? 'Khách #${booking.customerId}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              if (booking.customerPhone != null) ...[
                const SizedBox(width: 10),
                Text(
                  '(${booking.customerPhone})',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),

          // Barber info
          Row(
            children: [
              const Icon(Icons.content_cut, color: Color(0xFFD4AF37), size: 15),
              const SizedBox(width: 6),
              Text(
                'Thợ: ${booking.staffName}',
                style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Services
          Text(
            'Dịch vụ: ${booking.services.map((s) => s.name).join(', ')}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          if (booking.note != null && booking.note!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Ghi chú: ${booking.note}',
              style: const TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 8),

          // Price & Paid Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng tiền: ${_formatPrice(booking.totalPrice)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 20),

          // Receptionist Actions Bar
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              // Reassign button (always available except cancelled/completed)
              if (booking.status != 'cancelled' && booking.status != 'completed')
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  icon: const Icon(Icons.sync_alt, size: 15),
                  label: const Text('Đổi thợ/giờ', style: TextStyle(fontSize: 12)),
                  onPressed: () => _openReassignDialog(booking),
                ),

              // Check-in button
              if (booking.status == 'confirmed')
                ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code_scanner, size: 16, color: Colors.black),
                  label: const Text('Check-in Khách'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purpleAccent,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    _dataService.checkInBooking(booking.id);
                  },
                ),

              // Start Haircut button
              if (booking.status == 'checked_in')
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow, size: 16, color: Colors.black),
                  label: const Text('Vào Ghế Cắt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    _dataService.updateBookingStatus(booking.id, 'in_progress');
                  },
                ),

              // Quick Checkout / Payment button
              if (!isPaid && booking.status != 'cancelled')
                ElevatedButton.icon(
                  icon: const Icon(Icons.attach_money, size: 16, color: Colors.black),
                  label: const Text('Thu Tiền & Đóng Đơn'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
                  onPressed: () => _openCheckoutDialog(booking),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Booking detail bottom sheet when clicked from matrix
  void _showBookingDetailSheet(BookingModel booking) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chi Tiết Đơn #${booking.id}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Colors.white12),
              const SizedBox(height: 8),
              _buildDetailRow('Khách hàng:', booking.customerName ?? 'Khách #${booking.customerId}'),
              if (booking.customerPhone != null)
                _buildDetailRow('Số điện thoại:', booking.customerPhone!),
              _buildDetailRow('Thợ phục vụ:', booking.staffName),
              _buildDetailRow('Khung giờ:', '${booking.startTime} - ${booking.endTime}'),
              _buildDetailRow('Trạng thái:', _getStatusText(booking.status)),
              _buildDetailRow('Dịch vụ:', booking.services.map((s) => s.name).join(', ')),
              _buildDetailRow('Tổng tiền:', _formatPrice(booking.totalPrice)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (booking.status != 'cancelled' && booking.status != 'completed') ...[
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _openReassignDialog(booking);
                      },
                      child: const Text('Đổi thợ/giờ', style: TextStyle(color: Colors.white70)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (booking.status == 'confirmed') ...[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
                      onPressed: () {
                        _dataService.checkInBooking(booking.id);
                        Navigator.pop(context);
                      },
                      child: const Text('Check-in Ngay', style: TextStyle(color: Colors.black)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
                    onPressed: () {
                      Navigator.pop(context);
                      _openCheckoutDialog(booking);
                    },
                    child: const Text('Thu Tiền', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatusFilter == value;
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
            _selectedStatusFilter = value;
          });
        }
      },
    );
  }
}
