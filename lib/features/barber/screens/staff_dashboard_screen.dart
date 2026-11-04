import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:barber_booking_app/shared/models/schedule_model.dart';
import 'package:barber_booking_app/features/auth/screens/login_screen.dart';
import 'package:barber_booking_app/shared/models/barber_model.dart';
import 'package:barber_booking_app/shared/models/booking_model.dart';
import 'package:barber_booking_app/shared/models/review_model.dart';
import 'package:barber_booking_app/shared/models/user_model.dart';
import 'package:barber_booking_app/shared/services/auth_session.dart';
import 'package:barber_booking_app/shared/services/firebase_service.dart';
import 'package:barber_booking_app/shared/widgets/app_network_image.dart';
import 'package:barber_booking_app/shared/widgets/full_screen_image_viewer.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseService _dataService = FirebaseService();
  final AuthSession _session = AuthSession();
  late TabController _tabController;

  // Weekly timetable: selected date (defaults to today)
  late DateTime _selectedDate;
  bool _hidePastSlots = true;
  Timer? _refreshTimer;
  bool _loading = true;
  String? _error;
  StaffDashboardData? _dashboard;

  // Color palette
  static const Color _bgDark = Color(0xFF0F0F0F);
  static const Color _cardDark = Color(0xFF1A1A1A);
  static const Color _cardDark2 = Color(0xFF222222);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _goldLight = Color(0xFFF0D060);
  static const Color _white = Colors.white;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _selectedDate = DateTime.now();
    _dataService.addListener(_onDataChanged);
    _loadDashboard();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadDashboard(showLoading: false);
    });
  }

  void _onDataChanged() {
    if (mounted) _loadDashboard(showLoading: false);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _dataService.removeListener(_onDataChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard({bool showLoading = true}) async {
    final staffId = _session.currentUser?.id ?? _dataService.currentUser?.id;
    if (staffId == null) {
      setState(() {
        _loading = false;
        _error = 'Chưa đăng nhập. Hãy đăng nhập tài khoản barber.';
      });
      return;
    }

    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final data = await _dataService.getStaffDashboard(staffId);
      if (!mounted) return;
      _session.setUser(data.user);
      setState(() {
        _dashboard = data;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_dashboard == null) _error = e.toString();
      });
    }
  }

  Future<void> _completeShift(int bookingId) async {
    if (_dashboard == null) return;
    try {
      await _dataService.updateBookingStatusById(bookingId, 'completed');
      await _loadDashboard(showLoading: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  List<StaffScheduleModel> _todaySchedules() {
    final now = DateTime.now();
    return (_dashboard?.schedules ?? []).where((s) {
      return s.workDate.year == now.year &&
          s.workDate.month == now.month &&
          s.workDate.day == now.day;
    }).toList();
  }

  String _shiftLabel() {
    final today = _todaySchedules();
    if (today.isEmpty) return 'Hôm nay không có ca làm việc';
    if (today.every((s) => s.isDayOff)) return 'Hôm nay nghỉ';
    final working = today.where((s) => !s.isDayOff).toList();
    return 'Ca hôm nay: ${working.map((s) => '${s.startTime}–${s.endTime}').join(', ')}';
  }

  String _workStatusText(String status) {
    switch (status) {
      case 'available':
        return 'Trong ca';
      case 'busy':
        return 'Đang phục vụ';
      case 'break':
        return 'Nghỉ giữa ca';
      default:
        return 'Ngoài ca';
    }
  }

  bool _canCompleteBooking(BookingModel booking) {
    if (booking.status == 'completed' ||
        booking.status == 'cancelled' ||
        booking.status == 'no_show') {
      return false;
    }
    if (booking.status == 'in_progress') return true;

    final now = DateTime.now();
    if (booking.bookingDate.year != now.year ||
        booking.bookingDate.month != now.month ||
        booking.bookingDate.day != now.day) {
      return false;
    }
    final start = _parseTime(booking.startTime);
    final startAt = DateTime(
      now.year,
      now.month,
      now.day,
      start.hour,
      start.minute,
    );
    return !now.isBefore(startAt);
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'in_progress':
        return const Color(0xFF2196F3);
      case 'checked_in':
        return const Color(0xFFAB47BC);
      case 'confirmed':
        return _gold;
      case 'cancelled':
        return const Color(0xFFEF5350);
      default:
        return const Color(0xFFFF9800);
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty_rounded;
      case 'confirmed':
        return Icons.check_circle_outline_rounded;
      case 'checked_in':
        return Icons.login_rounded;
      case 'in_progress':
        return Icons.content_cut_rounded;
      case 'completed':
        return Icons.done_all_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _bgDark,
        body: Center(child: CircularProgressIndicator(color: _gold)),
      );
    }

    if (_error != null || _dashboard == null) {
      return Scaffold(
        backgroundColor: _bgDark,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: _cardDark,
          title: const Text('Bảng Điều Khiển', style: TextStyle(color: _gold)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  color: Colors.grey,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  _error ?? 'Không có dữ liệu',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadDashboard,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final user = _dashboard!.user;
    final staffId = user.id;
    final barberBookings = _dashboard!.bookings;
    final barberObj = _dashboard!.barber;
    final myReviews = _dashboard!.reviews;

    // Stats always based on TODAY
    final now = DateTime.now();
    final todayBookings = barberBookings.where((b) {
      return b.bookingDate.year == now.year &&
          b.bookingDate.month == now.month &&
          b.bookingDate.day == now.day;
    }).toList();
    final completedCount = todayBookings
        .where((b) => b.status == 'completed')
        .length;
    final pendingCount = todayBookings
        .where((b) => b.status == 'pending' || b.status == 'confirmed')
        .length;

    // Bookings for the SELECTED day (used in timetable tab)
    final selectedDayBookings = barberBookings.where((b) {
      return b.bookingDate.year == _selectedDate.year &&
          b.bookingDate.month == _selectedDate.month &&
          b.bookingDate.day == _selectedDate.day;
    }).toList();

    return Scaffold(
      backgroundColor: _bgDark,
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              backgroundColor: _gold,
              onPressed: () => _showImageSourceDialog(staffId),
              icon: const Icon(Icons.add_a_photo_rounded, color: Colors.black),
              label: const Text(
                'Thêm Ảnh Portfolio',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(context, user, barberObj),
        ],
        body: Column(
          children: [
            _buildStatsRow(completedCount, pendingCount, myReviews, barberObj),
            Container(
              color: _cardDark,
              child: TabBar(
                controller: _tabController,
                indicatorColor: _gold,
                indicatorWeight: 3,
                labelColor: _gold,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'Lịch Làm Việc'),
                  Tab(text: 'Portfolio'),
                  Tab(text: 'Đánh Giá'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTimetableTab(
                    selectedDayBookings,
                    barberBookings,
                    staffId,
                  ),
                  _buildPortfolioTab(barberObj.portfolioImages),
                  _buildReviewsTab(myReviews, barberObj),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SLIVER APP BAR ───────────────────────────────────────────────────
  Widget _buildSliverAppBar(
    BuildContext context,
    UserModel user,
    BarberModel barberObj,
  ) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 280,
      pinned: true,
      backgroundColor: _cardDark,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A1200), Color(0xFF2C2000), Color(0xFF0F0F0F)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showChangeAvatarDialog(user.id, user.uid),
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [_gold, _goldLight, _gold],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: ClipOval(
                                child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                    ? AppNetworkImage(
                                        imageUrl: user.avatarUrl,
                                        width: 76,
                                        height: 76,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 76,
                                        height: 76,
                                        color: _cardDark2,
                                        child: const Icon(
                                          Icons.person,
                                          color: _gold,
                                          size: 36,
                                        ),
                                      ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: _gold,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _cardDark, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.black,
                                  size: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              style: const TextStyle(
                                color: _white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFD4AF37),
                                    Color(0xFFF0D060),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                '✂  Barber / Thợ Cắt Tóc',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                ...List.generate(5, (i) {
                                  return Icon(
                                    i < barberObj.avgRating.floor()
                                        ? Icons.star_rounded
                                        : (i < barberObj.avgRating
                                              ? Icons.star_half_rounded
                                              : Icons.star_outline_rounded),
                                    color: _gold,
                                    size: 16,
                                  );
                                }),
                                const SizedBox(width: 6),
                                Text(
                                  '${barberObj.avgRating} (${barberObj.reviewCount} đánh giá)',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () => _showEditProfileDialog(user, barberObj),
                              borderRadius: BorderRadius.circular(6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      barberObj.specialty.isNotEmpty
                                          ? barberObj.specialty
                                          : 'Thêm chuyên môn cắt tóc...',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.edit_outlined,
                                    color: _gold,
                                    size: 13,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildWorkStatusRow(barberObj),
                ],
              ),
            ),
          ),
        ),
      ),
      title: const Text(
        'Bảng Điều Khiển',
        style: TextStyle(
          color: _gold,
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Chỉnh sửa hồ sơ',
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: _gold,
              size: 20,
            ),
          ),
          onPressed: () => _showEditProfileDialog(user, barberObj),
        ),
        IconButton(
          tooltip: 'Đăng xuất',
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: Colors.red,
              size: 20,
            ),
          ),
          onPressed: () {
            _session.logout();
            _dataService.logout();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildWorkStatusRow(BarberModel barberObj) {
    Color statusDotColor;
    switch (barberObj.status) {
      case 'available':
        statusDotColor = const Color(0xFF4CAF50);
        break;
      case 'busy':
        statusDotColor = const Color(0xFFEF5350);
        break;
      case 'break':
        statusDotColor = const Color(0xFFFFC107);
        break;
      default:
        statusDotColor = Colors.grey;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Trạng thái:',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _cardDark2,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: statusDotColor.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusDotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _workStatusText(barberObj.status),
                    style: const TextStyle(
                      color: _white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _shiftLabel(),
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  // ─── STATS ROW ────────────────────────────────────────────────────────
  Widget _buildStatsRow(
    int completed,
    int pending,
    List<ReviewModel> reviews,
    barberObj,
  ) {
    return Container(
      color: _cardDark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildStatCard(
            icon: Icons.done_all_rounded,
            value: '$completed',
            label: 'Hoàn thành',
            color: const Color(0xFF4CAF50),
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            icon: Icons.schedule_rounded,
            value: '$pending',
            label: 'Chờ phục vụ',
            color: _gold,
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            icon: Icons.star_rounded,
            value: '${barberObj.avgRating}',
            label: 'Rating',
            color: const Color(0xFFFFC107),
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            icon: Icons.rate_review_rounded,
            value: '${reviews.length}',
            label: 'Đánh giá',
            color: const Color(0xFF9C27B0),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── TIMETABLE TAB ────────────────────────────────────────────────────

  /// Returns the Monday of the week that contains [date].
  DateTime _weekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  Widget _buildWeekStrip(List<dynamic> allBarberBookings) {
    final now = DateTime.now();
    final monday = _weekStart(now);
    const dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return SizedBox(
      height: 76,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 7,
        itemBuilder: (context, i) {
          final day = monday.add(Duration(days: i));
          final isToday =
              day.year == now.year &&
              day.month == now.month &&
              day.day == now.day;
          final isSelected =
              day.year == _selectedDate.year &&
              day.month == _selectedDate.month &&
              day.day == _selectedDate.day;

          // Count bookings for this day
          final dayBookingCount = allBarberBookings.where((b) {
            return b.bookingDate.year == day.year &&
                b.bookingDate.month == day.month &&
                b.bookingDate.day == day.day;
          }).length;

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 52,
              margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [_gold, _goldLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected
                    ? null
                    : (isToday ? _gold.withValues(alpha: 0.12) : _cardDark2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? _gold
                      : (isToday
                            ? _gold.withValues(alpha: 0.5)
                            : Colors.white10),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _gold.withValues(alpha: 0.35),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayLabels[i],
                    style: TextStyle(
                      color: isSelected
                          ? Colors.black
                          : (isToday ? _gold : Colors.grey),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.black
                          : (isToday ? _gold : _white),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Dot indicator for bookings
                  if (dayBookingCount > 0)
                    Container(
                      width: 18,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black45 : _gold,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    )
                  else
                    const SizedBox(height: 5),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimetableTab(
    List<dynamic> selectedDayBookings,
    List<dynamic> allBarberBookings,
    int staffId,
  ) {
    final allSlots =
        _dashboard?.timeSlots ??
        const [
          '08:00',
          '09:00',
          '10:00',
          '11:00',
          '13:00',
          '14:00',
          '15:00',
          '16:00',
          '17:00',
          '18:00',
          '19:00',
          '20:00',
        ];
    final now = DateTime.now();
    final isSelectedToday =
        _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;

    return Column(
      children: [
        // ── Week strip
        Container(
          color: _cardDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Icon(Icons.date_range_rounded, color: _gold, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Lịch Tuần Này',
                      style: TextStyle(
                        color: _gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _buildWeekStrip(allBarberBookings),
              const SizedBox(height: 4),
            ],
          ),
        ),
        // ── Day header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _gold.withValues(alpha: 0.15),
                  _gold.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _gold.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: _gold,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _formatDate(_selectedDate),
                          style: const TextStyle(
                            color: _gold,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (isSelectedToday) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _gold,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Hôm nay',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      selectedDayBookings.isEmpty
                          ? 'Không có lịch hẹn'
                          : '${selectedDayBookings.length} lịch hẹn',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                _buildLegend(),
              ],
            ),
          ),
        ),
        // ── Filter and Slot Counter Row
        Builder(
          builder: (context) {
            final bookedSlots = <MapEntry<String, BookingModel>>[];
            for (final slot in allSlots) {
              BookingModel? b;
              for (final item in selectedDayBookings) {
                if (item is BookingModel && item.startTime == slot) {
                  b = item;
                  break;
                }
              }
              if (b != null) {
                bookedSlots.add(MapEntry(slot, b));
              }
            }

            final pastCount = bookedSlots
                .where((entry) => _isSlotPast(entry.key, entry.value))
                .length;

            final visibleSlots = bookedSlots.where((entry) {
              if (_hidePastSlots && _isSlotPast(entry.key, entry.value)) {
                return false;
              }
              return true;
            }).toList();

            return Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lịch cắt (${visibleSlots.length})',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => _hidePastSlots = !_hidePastSlots),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _hidePastSlots
                                  ? _gold.withValues(alpha: 0.15)
                                  : _cardDark2,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _hidePastSlots ? _gold : Colors.white24,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _hidePastSlots
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  size: 14,
                                  color: _hidePastSlots ? _gold : Colors.white70,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _hidePastSlots
                                      ? 'Ẩn slot đã qua'
                                      : 'Hiện tất cả',
                                  style: TextStyle(
                                    color: _hidePastSlots ? _gold : Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (pastCount > 0 && _hidePastSlots) ...[
                                  const SizedBox(width: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _gold,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$pastCount',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: visibleSlots.isEmpty
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 16,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            pastCount > 0
                                                ? Icons.history_toggle_off_rounded
                                                : Icons.event_busy_rounded,
                                            color: pastCount > 0
                                                ? _gold
                                                : Colors.grey,
                                            size: 40,
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            pastCount > 0
                                                ? 'Đã qua tất cả $pastCount slot lịch hẹn'
                                                : 'Không có lịch hẹn nào',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                            ),
                                          ),
                                          if (pastCount > 0 && _hidePastSlots) ...[
                                            const SizedBox(height: 10),
                                            TextButton.icon(
                                              onPressed: () => setState(
                                                  () => _hidePastSlots = false),
                                              icon: const Icon(
                                                Icons.visibility_rounded,
                                                size: 16,
                                                color: _gold,
                                              ),
                                              label: Text(
                                                'Xem lại $pastCount slot đã qua',
                                                style: const TextStyle(
                                                  color: _gold,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: visibleSlots.length,
                            itemBuilder: (context, index) {
                              final entry = visibleSlots[index];
                              return _buildTimeSlotRow(entry.key, entry.value);
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegendDot(const Color(0xFF4CAF50), 'Rảnh'),
        const SizedBox(height: 4),
        _buildLegendDot(_gold, 'Đặt lịch'),
        const SizedBox(height: 4),
        _buildLegendDot(const Color(0xFF2196F3), 'Đang cắt'),
      ],
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  Widget _buildTimeSlotRow(String slot, dynamic booking) {
    final bool hasBooking = booking != null;
    final bool isCurrentHour = _isCurrentHourSlot(slot);

    Color slotColor;
    if (!hasBooking) {
      slotColor = const Color(0xFF4CAF50);
    } else if (booking.status == 'in_progress') {
      slotColor = const Color(0xFF2196F3);
    } else if (booking.status == 'completed') {
      slotColor = Colors.grey;
    } else {
      slotColor = _gold;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 52,
              child: Text(
                slot,
                style: TextStyle(
                  color: isCurrentHour ? _gold : Colors.grey,
                  fontWeight: isCurrentHour
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isCurrentHour ? _gold : slotColor,
                    shape: BoxShape.circle,
                    boxShadow: isCurrentHour
                        ? [
                            BoxShadow(
                              color: _gold.withValues(alpha: 0.5),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                ),
                Expanded(child: Container(width: 2, color: Colors.white10)),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: hasBooking
                  ? _buildBookingCard(booking, slotColor)
                  : _buildFreeSlotCard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeSlotCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
        ),
      ),
      child: const Text(
        'Trống – Có thể nhận lịch',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }

  Widget _buildBookingCard(dynamic booking, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  booking.services.isNotEmpty
                      ? booking.services.map((s) => s.name).join(', ')
                      : 'Dịch vụ',
                  style: const TextStyle(
                    color: _white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(booking.status),
                      color: statusColor,
                      size: 11,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getStatusText(booking.status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                color: Colors.grey,
                size: 13,
              ),
              const SizedBox(width: 4),
              Text(
                '${booking.startTime} – ${booking.endTime}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.monetization_on_outlined,
                color: _gold,
                size: 13,
              ),
              const SizedBox(width: 4),
              Text(
                _formatPrice(booking.totalPrice),
                style: const TextStyle(
                  color: _gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (booking.note != null && booking.note!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.sticky_note_2_rounded,
                  color: Colors.amberAccent,
                  size: 13,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    booking.note!,
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (_canCompleteBooking(booking as BookingModel)) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionButton(
                  label: 'Hoàn thành ca',
                  icon: Icons.check_rounded,
                  color: const Color(0xFF4CAF50),
                  onTap: () => _completeShift(booking.id),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── PORTFOLIO TAB ────────────────────────────────────────────────────
  void _openFullScreenImage(List<String> images, int index) {
    if (images.isEmpty) return;
    final staffId = _session.currentUser?.id ?? _dataService.currentUser?.id;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImageViewer(
          images: images,
          initialIndex: index,
          onDelete: staffId != null
              ? (url) async {
                  await _dataService.removePortfolioImage(staffId, url);
                  _loadDashboard(showLoading: false);
                }
              : null,
        ),
      ),
    );
  }

  Widget _buildPortfolioTab(List<String> images) {
    // Chỉ hiển thị ảnh tải từ Cloudinary
    final cloudinaryImages =
        images.where((url) => url.contains('cloudinary.com')).toList();
    final displayImages = cloudinaryImages.take(4).toList();
    final hasMore = cloudinaryImages.length > 4;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tác Phẩm Của Tôi',
                style: TextStyle(
                  color: _white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (hasMore || cloudinaryImages.isNotEmpty)
                GestureDetector(
                  onTap: () => _showAllPortfolio(cloudinaryImages),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_gold, _goldLight],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Xem tất cả',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${cloudinaryImages.length} ảnh portfolio (Cloudinary)',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (displayImages.isEmpty)
            _buildEmptyState(
              icon: Icons.photo_library_outlined,
              message:
                  'Chưa có ảnh portfolio nào từ Cloudinary.\nHãy bấm nút "+" bên dưới để tải ảnh tác phẩm lên!',
            )
          else
            _buildPortfolioGrid(displayImages, cloudinaryImages, hasMore),
        ],
      ),
    );
  }

  Widget _buildPortfolioGrid(
    List<String> displayImages,
    List<String> allImages,
    bool hasMore,
  ) {
    if (displayImages.length == 1) {
      return GestureDetector(
        onTap: () => _openFullScreenImage(allImages, 0),
        child: AppNetworkImage(
          imageUrl: displayImages[0],
          height: 280,
          width: double.infinity,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.circular(14),
        ),
      );
    }

    return Column(
      children: [
        GestureDetector(
          onTap: () => _openFullScreenImage(allImages, 0),
          child: _buildPortfolioImageTile(displayImages[0], height: 200),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _openFullScreenImage(allImages, 1),
                child: _buildPortfolioImageTile(displayImages[1], height: 130),
              ),
            ),
            const SizedBox(width: 8),
            if (displayImages.length >= 3)
              Expanded(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: () => _openFullScreenImage(allImages, 2),
                      child: _buildPortfolioImageTile(displayImages[2], height: 130),
                    ),
                    if (hasMore)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () => _showAllPortfolio(allImages),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.photo_library_rounded,
                                  color: _white,
                                  size: 28,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '+${allImages.length - 3} ảnh',
                                  style: const TextStyle(
                                    color: _white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPortfolioImageTile(String url, {double height = 160}) {
    return AppNetworkImage(
      imageUrl: url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(12),
    );
  }

  Widget _buildImageError(double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: _cardDark2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 32),
      ),
    );
  }

  void _showAllPortfolio(List<String> images) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.photo_library_rounded, color: _gold),
                  SizedBox(width: 10),
                  Text(
                    'Tất Cả Portfolio',
                    style: TextStyle(
                      color: _white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.85,
                ),
                itemCount: images.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _openFullScreenImage(images, i),
                  child: AppNetworkImage(
                    imageUrl: images[i],
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── REVIEWS TAB ──────────────────────────────────────────────────────
  Widget _buildReviewsTab(List<ReviewModel> reviews, barberObj) {
    final displayReviews = reviews.take(3).toList();
    final hasMore = reviews.length > 3;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRatingSummaryCard(barberObj, reviews),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Đánh Giá Gần Đây',
                style: TextStyle(
                  color: _white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (hasMore)
                GestureDetector(
                  onTap: () => _showAllReviews(reviews),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_gold, _goldLight],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Xem tất cả',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (reviews.isEmpty)
            _buildEmptyState(
              icon: Icons.rate_review_outlined,
              message: 'Chưa có đánh giá nào',
            )
          else
            ...displayReviews.map((r) => _buildReviewCard(r)),
        ],
      ),
    );
  }

  Widget _buildRatingSummaryCard(barberObj, List<ReviewModel> reviews) {
    final Map<int, int> dist = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in reviews) {
      dist[r.rating] = (dist[r.rating] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _gold.withValues(alpha: 0.12),
            _gold.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                '${barberObj.avgRating}',
                style: const TextStyle(
                  color: _gold,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < barberObj.avgRating.floor()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: _gold,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${barberObj.reviewCount} đánh giá',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = dist[star] ?? 0;
                final total = reviews.isEmpty ? 1 : reviews.length.toDouble();
                final ratio = count / total;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded, color: _gold, size: 11),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratio,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation(_gold),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: review.customerAvatar != null && review.customerAvatar!.isNotEmpty
                    ? AppNetworkImage(
                        imageUrl: review.customerAvatar,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 40,
                        height: 40,
                        color: _cardDark2,
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.customerName,
                      style: const TextStyle(
                        color: _white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      _formatRelativeDate(review.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: _gold,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.format_quote_rounded, color: _gold, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    review.comment,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAllReviews(List<ReviewModel> reviews) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: _gold),
                  const SizedBox(width: 10),
                  Text(
                    'Tất Cả Đánh Giá (${reviews.length})',
                    style: const TextStyle(
                      color: _white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: reviews.length,
                itemBuilder: (_, i) => _buildReviewCard(reviews[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────
  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(icon, color: Colors.grey.withValues(alpha: 0.4), size: 52),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  bool _isSlotPast(String slot, BookingModel? booking) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    if (selectedDay.isBefore(today)) return true;
    if (selectedDay.isAfter(today)) return false;

    // Hôm nay: nếu đang cắt (in_progress) thì không ẩn
    if (booking?.status == 'in_progress') return false;

    // Nếu đã hoàn thành thì coi là đã qua
    if (booking?.status == 'completed') return true;

    // So sánh theo giờ kết thúc (endTime) của lịch cắt
    final timeStr = (booking != null && booking.endTime.isNotEmpty)
        ? booking.endTime
        : slot;
    final t = _parseTime(timeStr);
    final slotTime = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    return now.isAfter(slotTime);
  }

  bool _isCurrentHourSlot(String slot) {
    final nowHour = DateTime.now().hour;
    final slotHour = int.tryParse(slot.split(':')[0]) ?? -1;
    return slotHour == nowHour;
  }

  String _formatDate(DateTime date) {
    const days = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    final dayName = days[date.weekday - 1];
    return '$dayName, ${date.day}/${date.month}/${date.year}';
  }

  String _formatRelativeDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Hôm nay';
    if (diff.inDays == 1) return 'Hôm qua';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showImageSourceDialog(int staffId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Thêm ảnh portfolio',
                style: TextStyle(
                  color: _white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: _cardDark2,
                  child: Icon(Icons.camera_alt_rounded, color: _gold),
                ),
                title: const Text(
                  'Chụp ảnh trực tiếp',
                  style: TextStyle(color: _white),
                ),
                subtitle: const Text(
                  'Sử dụng camera của thiết bị',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadImage(staffId, ImageSource.camera);
                },
              ),
              const Divider(color: Colors.white12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: _cardDark2,
                  child: Icon(Icons.photo_library_rounded, color: _gold),
                ),
                title: const Text(
                  'Tải ảnh lên từ máy',
                  style: TextStyle(color: _white),
                ),
                subtitle: const Text(
                  'Chọn ảnh có sẵn trong thư viện',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadImage(staffId, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _requestPermission(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        _showOpenSettingsDialog('Máy ảnh (Camera)');
        return false;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Cần cấp quyền truy cập Máy ảnh để chụp trực tiếp.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return false;
      }
    } else {
      var status = await Permission.photos.request();
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      if (status.isGranted || status.isLimited) {
        return true;
      } else if (status.isPermanentlyDenied) {
        _showOpenSettingsDialog('Thư viện ảnh');
        return false;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cần cấp quyền truy cập Thư viện ảnh để chọn ảnh.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return false;
      }
    }
  }

  void _showOpenSettingsDialog(String featureName) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardDark,
        title: Text(
          'Cần cấp quyền $featureName',
          style: const TextStyle(color: _gold),
        ),
        content: Text(
          'Quyền $featureName đã bị từ chối. Vui lòng mở cài đặt ứng dụng để cấp quyền.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Mở Cài Đặt'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage(int staffId, ImageSource source) async {
    final hasPermission = await _requestPermission(source);
    if (!hasPermission) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile == null || !mounted) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            const Center(child: CircularProgressIndicator(color: _gold)),
      );

      final downloadUrl = await _dataService.uploadPortfolioImage(
        staffId,
        pickedFile,
      );
      await _dataService.addPortfolioImage(staffId, downloadUrl);

      if (!mounted) return;
      Navigator.pop(context); // Pop loading dialog

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã thêm ảnh portfolio thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      _loadDashboard(showLoading: false);
    } catch (e) {
      if (!mounted) return;
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải ảnh lên: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ─── THAY ĐỔI AVATAR QUA CLOUDINARY ──────────────────────────────────
  void _showChangeAvatarDialog(int staffId, String uid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Thay Đổi Ảnh Đại Diện',
                style: TextStyle(
                  color: _white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Ảnh sẽ được tải lên và lưu trữ qua Cloudinary',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: _gold),
                ),
                title: const Text('Chụp ảnh mới', style: TextStyle(color: _white)),
                subtitle: const Text('Sử dụng máy ảnh', style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadAvatar(staffId, uid, ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: _gold),
                ),
                title: const Text('Chọn từ thư viện', style: TextStyle(color: _white)),
                subtitle: const Text('Tải ảnh từ bộ sưu tập', style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadAvatar(staffId, uid, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(int staffId, String uid, ImageSource source) async {
    final hasPermission = await _requestPermission(source);
    if (!hasPermission) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1000,
        maxHeight: 1000,
      );

      if (pickedFile == null || !mounted) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: _gold),
        ),
      );

      // Upload avatar to Cloudinary
      final downloadUrl = await _dataService.uploadAvatar(staffId, pickedFile);
      await _dataService.updateStaffAvatar(staffId, downloadUrl, uid: uid);

      if (!mounted) return;
      Navigator.pop(context); // pop loading

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật ảnh đại diện từ Cloudinary thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      _loadDashboard(showLoading: false);
    } catch (e) {
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải ảnh đại diện: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ─── CHỈNH SỬA HỒ SƠ BARBER ───────────────────────────────────────────
  void _showEditProfileDialog(UserModel user, BarberModel barber) {
    final nameCtrl = TextEditingController(text: user.fullName);
    final phoneCtrl = TextEditingController(text: user.phone);
    final emailCtrl = TextEditingController(text: user.email ?? '');
    final addressCtrl = TextEditingController(text: user.address ?? '');
    final specialtyCtrl = TextEditingController(text: barber.specialty);
    final bioCtrl = TextEditingController(text: barber.bio);
    final expCtrl = TextEditingController(
      text: barber.yearsExperience > 0 ? '${barber.yearsExperience}' : '3',
    );
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      backgroundColor: _cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (ctx, scrollController) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.edit_note_rounded, color: _gold),
                            SizedBox(width: 8),
                            Text(
                              'Chỉnh Sửa Hồ Sơ Thợ',
                              style: TextStyle(
                                color: _white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.grey),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white10),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar section
                            Center(
                              child: Stack(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [_gold, _goldLight],
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                          ? AppNetworkImage(
                                              imageUrl: user.avatarUrl,
                                              width: 86,
                                              height: 86,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              width: 86,
                                              height: 86,
                                              color: _cardDark2,
                                              child: const Icon(
                                                Icons.person,
                                                color: _gold,
                                                size: 40,
                                              ),
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        _showChangeAvatarDialog(user.id, user.uid);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(7),
                                        decoration: BoxDecoration(
                                          color: _gold,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: _cardDark, width: 2),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt_rounded,
                                          color: Colors.black,
                                          size: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Center(
                              child: TextButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _showChangeAvatarDialog(user.id, user.uid);
                                },
                                icon: const Icon(Icons.cloud_upload_rounded, color: _gold, size: 16),
                                label: const Text(
                                  'Đổi ảnh đại diện (Cloudinary)',
                                  style: TextStyle(color: _gold, fontSize: 13),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            _buildEditField(
                              label: 'Họ và Tên (*)',
                              controller: nameCtrl,
                              icon: Icons.person_outline_rounded,
                              validator: (v) =>
                                  v == null || v.trim().isEmpty ? 'Vui lòng nhập họ và tên' : null,
                            ),
                            const SizedBox(height: 14),

                            _buildEditField(
                              label: 'Số Điện Thoại (*)',
                              controller: phoneCtrl,
                              icon: Icons.phone_android_rounded,
                              keyboardType: TextInputType.phone,
                              validator: (v) =>
                                  v == null || v.trim().length < 9 ? 'Số điện thoại không hợp lệ' : null,
                            ),
                            const SizedBox(height: 14),

                            _buildEditField(
                              label: 'Email',
                              controller: emailCtrl,
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 14),

                            _buildEditField(
                              label: 'Địa Chỉ',
                              controller: addressCtrl,
                              icon: Icons.location_on_outlined,
                            ),
                            const SizedBox(height: 14),

                            _buildEditField(
                              label: 'Chuyên Môn Cắt Tóc',
                              controller: specialtyCtrl,
                              icon: Icons.content_cut_rounded,
                              hintText: 'VD: Fade Master, Uốn Hàn Quốc, Nhuộm tẩy...',
                            ),
                            const SizedBox(height: 14),

                            _buildEditField(
                              label: 'Số Năm Kinh Nghiệm',
                              controller: expCtrl,
                              icon: Icons.workspace_premium_outlined,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 14),

                            _buildEditField(
                              label: 'Giới Thiệu Bản Thân (Bio)',
                              controller: bioCtrl,
                              icon: Icons.badge_outlined,
                              maxLines: 3,
                              hintText: 'Giới thiệu ngắn về phong cách cắt và kinh nghiệm của bạn...',
                            ),
                            const SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _gold,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 2,
                                ),
                                onPressed: () async {
                                  if (!formKey.currentState!.validate()) return;
                                  Navigator.pop(ctx);

                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => const Center(
                                      child: CircularProgressIndicator(color: _gold),
                                    ),
                                  );

                                  try {
                                    final exp = int.tryParse(expCtrl.text.trim()) ?? barber.yearsExperience;
                                    await _dataService.updateStaffProfile(
                                      userId: user.id,
                                      uid: user.uid,
                                      fullName: nameCtrl.text.trim(),
                                      phone: phoneCtrl.text.trim(),
                                      email: emailCtrl.text.trim(),
                                      address: addressCtrl.text.trim(),
                                      specialty: specialtyCtrl.text.trim(),
                                      bio: bioCtrl.text.trim(),
                                      yearsExperience: exp,
                                    );

                                    if (!mounted) return;
                                    Navigator.pop(context); // pop loading

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Cập nhật hồ sơ thành công!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );

                                    _loadDashboard(showLoading: false);
                                  } catch (e) {
                                    if (!mounted) return;
                                    if (Navigator.canPop(context)) Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Lỗi cập nhật hồ sơ: $e'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                },
                                child: const Text(
                                  'LƯU THAY ĐỔI',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEditField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _gold,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
            filled: true,
            fillColor: _cardDark2,
            prefixIcon: Icon(icon, color: _gold, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _gold, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
