import 'dart:async';

import 'package:flutter/material.dart';
import 'package:barber_booking_app/shared/models/schedule_model.dart';
import 'package:barber_booking_app/features/auth/screens/login_screen.dart';
import 'package:barber_booking_app/shared/models/barber_model.dart';
import 'package:barber_booking_app/shared/models/booking_model.dart';
import 'package:barber_booking_app/shared/models/review_model.dart';
import 'package:barber_booking_app/shared/models/user_model.dart';
import 'package:barber_booking_app/shared/services/api_service.dart';
import 'package:barber_booking_app/shared/services/auth_session.dart';
import 'package:barber_booking_app/shared/services/mock_data_service.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen>
    with SingleTickerProviderStateMixin {
  final MockDataService _dataService = MockDataService();
  final AuthSession _session = AuthSession();
  final ApiService _api = ApiService();
  late TabController _tabController;

  // Weekly timetable: selected date (defaults to today)
  late DateTime _selectedDate;
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
    _selectedDate = DateTime.now();
    _loadDashboard();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadDashboard(showLoading: false);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
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
      final data = await _api.getStaffDashboard(staffId);
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
    final staffId = _dashboard?.user.id;
    if (staffId == null) return;
    try {
      await _api.completeBooking(staffId, bookingId);
      await _loadDashboard(showLoading: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
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
                const Icon(Icons.cloud_off_rounded, color: Colors.grey, size: 48),
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
                  _buildTimetableTab(selectedDayBookings, barberBookings, staffId),
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
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [_gold, _goldLight, _gold],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 38,
                          backgroundColor: _cardDark2,
                          backgroundImage: user.avatarUrl != null
                              ? NetworkImage(user.avatarUrl!)
                              : null,
                          child: user.avatarUrl == null
                              ? const Icon(Icons.person, color: _gold, size: 36)
                              : null,
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
                            Text(
                              barberObj.specialty,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.15),
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
                border: Border.all(color: statusDotColor.withOpacity(0.5)),
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
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
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
          final isToday = day.year == now.year &&
              day.month == now.month &&
              day.day == now.day;
          final isSelected = day.year == _selectedDate.year &&
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
                color: isSelected ? null : (isToday ? _gold.withOpacity(0.12) : _cardDark2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? _gold
                      : (isToday ? _gold.withOpacity(0.5) : Colors.white10),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _gold.withOpacity(0.35),
                          blurRadius: 10,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayLabels[i],
                    style: TextStyle(
                      color: isSelected ? Colors.black : (isToday ? _gold : Colors.grey),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      color: isSelected ? Colors.black : (isToday ? _gold : _white),
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
                      alignment: Alignment.center,
                      child: Text(
                        '$dayBookingCount',
                        style: TextStyle(
                          color: isSelected ? Colors.black87 : Colors.black,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
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
    final allSlots = _dashboard?.timeSlots ?? const [
      '08:00', '09:00', '10:00', '11:00',
      '13:00', '14:00', '15:00', '16:00',
      '17:00', '18:00', '19:00', '20:00',
    ];
    final now = DateTime.now();
    final isSelectedToday = _selectedDate.year == now.year &&
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
                colors: [_gold.withOpacity(0.15), _gold.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _gold.withOpacity(0.3)),
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
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
        const SizedBox(height: 12),
        // ── Time slots list
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: allSlots.map((slot) {
              BookingModel? booking;
              for (final item in selectedDayBookings) {
                if (item is BookingModel && item.startTime == slot) {
                  booking = item;
                  break;
                }
              }
              return _buildTimeSlotRow(slot, booking);
            }).toList(),
          ),
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
                              color: _gold.withOpacity(0.5),
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
        color: const Color(0xFF4CAF50).withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.15)),
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
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.4)),
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
                  color: statusColor.withOpacity(0.2),
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
  Widget _buildPortfolioTab(List<String> images) {
    final displayImages = images.take(4).toList();
    final hasMore = images.length > 4;

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
              if (hasMore || images.isNotEmpty)
                GestureDetector(
                  onTap: () => _showAllPortfolio(images),
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
            '${images.length} ảnh portfolio',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (displayImages.isEmpty)
            _buildEmptyState(
              icon: Icons.photo_library_outlined,
              message: 'Chưa có ảnh portfolio nào',
            )
          else
            _buildPortfolioGrid(displayImages, images, hasMore),
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
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          displayImages[0],
          height: 280,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildImageError(280),
        ),
      );
    }

    return Column(
      children: [
        _buildPortfolioImageTile(displayImages[0], height: 200),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildPortfolioImageTile(displayImages[1], height: 130),
            ),
            const SizedBox(width: 8),
            if (displayImages.length >= 3)
              Expanded(
                child: Stack(
                  children: [
                    _buildPortfolioImageTile(displayImages[2], height: 130),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildImageError(height),
      ),
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
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    images[i],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildImageError(160),
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
          colors: [_gold.withOpacity(0.12), _gold.withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gold.withOpacity(0.3)),
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
              CircleAvatar(
                radius: 20,
                backgroundColor: _cardDark2,
                backgroundImage: review.customerAvatar != null
                    ? NetworkImage(review.customerAvatar!)
                    : null,
                child: review.customerAvatar == null
                    ? const Icon(
                        Icons.person_rounded,
                        color: Colors.grey,
                        size: 20,
                      )
                    : null,
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
              color: Colors.white.withOpacity(0.04),
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
          Icon(icon, color: Colors.grey.withOpacity(0.4), size: 52),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
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
}
