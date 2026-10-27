import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/barber_model.dart';
import '../models/booking_model.dart';
import '../models/review_model.dart';
import '../models/schedule_model.dart';
import '../models/service_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import 'auth_session.dart';
import 'firebase_auth_service.dart';

// ---------------------------------------------------------------------------
// StaffDashboardData — giữ nguyên cấu trúc để các màn hình không đổi nhiều
// ---------------------------------------------------------------------------
class StaffDashboardData {
  final UserModel user;
  final BarberModel barber;
  final List<BookingModel> bookings;
  final List<ReviewModel> reviews;
  final List<StaffScheduleModel> schedules;
  final List<String> timeSlots;

  StaffDashboardData({
    required this.user,
    required this.barber,
    required this.bookings,
    required this.reviews,
    required this.schedules,
    required this.timeSlots,
  });
}

// ---------------------------------------------------------------------------
// FirebaseService — singleton, thay thế MockDataService + ApiService
// ---------------------------------------------------------------------------
class FirebaseService extends ChangeNotifier {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthSession _session = AuthSession();

  final List<String> allTimeSlots = const [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '13:00',
    '12:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',

  ];

  bool _started = false;
  Future<void>? _startFuture;
  List<BarberModel> barbers = [];
  List<ServiceModel> services = [];
  List<BookingModel> bookings = [];
  List<TransactionModel> transactions = [];
  List<ReviewModel> reviews = [];

  UserModel? get currentUser => _session.currentUser;
  set currentUser(UserModel? user) => _session.setUser(user);

  /// Gọi 1 lần sau login: seed demo nếu trống + lắng nghe Firestore.
  Future<void> start() {
    _startFuture ??= _startInternal();
    return _startFuture!;
  }

  Future<void> _startInternal() async {
    try {
      await ensureSeedData();
      await _loadOnce();
    } catch (e) {
      _startFuture = null;
      rethrow;
    }
    _started = true;
    _barbers.snapshots().listen((snap) {
      barbers = snap.docs.map(_barberFromDoc).toList();
      notifyListeners();
    });
    _services.snapshots().listen((snap) {
      services = snap.docs.map((d) {
        final j = d.data();
        return ServiceModel(
          id: (j['id'] as num?)?.toInt() ?? 0,
          name: j['name'] as String? ?? '',
          description: j['description'] as String? ?? '',
          price: (j['price'] as num?)?.toDouble() ?? 0,
          durationMin: (j['durationMin'] as num?)?.toInt() ?? 0,
          imageUrl: j['imageUrl'] as String? ?? '',
          isActive: j['isActive'] as bool? ?? true,
        );
      }).toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      notifyListeners();
    });
    _bookings.snapshots().listen((snap) {
      bookings = snap.docs.map(_bookingFromDoc).toList();
      notifyListeners();
    });
    _transactions.snapshots().listen((snap) {
      transactions = snap.docs.map(_txFromDoc).toList();
      notifyListeners();
    });
    _reviews.snapshots().listen((snap) {
      reviews = snap.docs.map(_reviewFromDoc).toList();
      notifyListeners();
    });
  }

  Future<void> _loadOnce() async {
    final barberSnap = await _barbers.get();
    barbers = barberSnap.docs.map(_barberFromDoc).toList();
    services = await fetchServices()
      ..sort((a, b) => a.id.compareTo(b.id));
    final bookingSnap = await _bookings.get();
    bookings = bookingSnap.docs.map(_bookingFromDoc).toList();
    final txSnap = await _transactions.get();
    transactions = txSnap.docs.map(_txFromDoc).toList();
    final reviewSnap = await _reviews.get();
    reviews = reviewSnap.docs.map(_reviewFromDoc).toList();
    notifyListeners();
  }

  Future<void> ensureSeedData() async {
    final existingServices = await _services.limit(1).get();
    if (existingServices.docs.isEmpty) {
      final demo = [
        {
          'id': 1,
          'name': 'Cắt tóc nam',
          'description': 'Cắt tóc tạo kiểu cơ bản',
          'price': 120000,
          'durationMin': 45,
          'imageUrl':
              'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=600',
          'isActive': true,
        },
        {
          'id': 2,
          'name': 'Fade / Undercut',
          'description': 'Cắt fade hiện đại',
          'price': 150000,
          'durationMin': 60,
          'imageUrl':
              'https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=600',
          'isActive': true,
        },
        {
          'id': 3,
          'name': 'Gội + tạo kiểu',
          'description': 'Gội đầu và sấy tạo kiểu',
          'price': 80000,
          'durationMin': 30,
          'imageUrl':
              'https://images.unsplash.com/photo-1621605815971-fbc98d665033?w=600',
          'isActive': true,
        },
        {
          'id': 4,
          'name': 'Cạo râu',
          'description': 'Cạo râu truyền thống',
          'price': 70000,
          'durationMin': 25,
          'imageUrl':
              'https://images.unsplash.com/photo-1599351431202-1e0f0137899a?w=600',
          'isActive': true,
        },
      ];
      for (final s in demo) {
        await _services.add(s);
      }
    }

    final existingBarbers = await _barbers.limit(1).get();
    if (existingBarbers.docs.isEmpty) {
      await _barbers.add({
        'userId': 101,
        'fullName': 'Trần Văn Quốc (Quốc Barber)',
        'phone': '0900000002',
        'avatarUrl':
            'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=400',
        'bio': 'Chuyên Fade, Undercut với hơn 6 năm kinh nghiệm.',
        'specialty': 'Fade, Undercut, Modern Pompadour',
        'yearsExperience': 6,
        'status': 'available',
        'avgRating': 4.9,
        'reviewCount': 0,
        'portfolioImages': [
          'https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=600',
          'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=600',
        ],
      });
      await _barbers.add({
        'userId': 102,
        'fullName': 'Lê Hoàng Nam (Nam Barber)',
        'phone': '0922334455',
        'avatarUrl':
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
        'bio': 'Phong cách cổ điển Classic & Side Part.',
        'specialty': 'Classic Cut, Side Part',
        'yearsExperience': 4,
        'status': 'available',
        'avgRating': 4.8,
        'reviewCount': 0,
        'portfolioImages': [
          'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=600',
        ],
      });
      await _barbers.add({
        'userId': 103,
        'fullName': 'Phạm Minh Đức (Đức Barber)',
        'phone': '0933445566',
        'avatarUrl':
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
        'bio': 'Uốn texture, nhuộm màu thời trang.',
        'specialty': 'Uốn Texture, Nhuộm, Mullet',
        'yearsExperience': 5,
        'status': 'available',
        'avgRating': 4.7,
        'reviewCount': 0,
        'portfolioImages': [
          'https://images.unsplash.com/photo-1567894340315-735d7c361db0?w=600',
        ],
      });
    }

    final existingSchedules = await _schedules.limit(1).get();
    if (existingSchedules.docs.isEmpty) {
      final today = DateTime.now();
      for (var i = 0; i < 7; i++) {
        final day = DateTime(today.year, today.month, today.day + i);
        final isSunday = day.weekday == DateTime.sunday;
        await _schedules.add({
          'id': int.parse(
            '${day.year}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}101',
          ),
          'staffId': 101,
          'workDate': Timestamp.fromDate(day),
          'startTime': '08:00',
          'endTime': '18:00',
          'isDayOff': isSunday,
          'note': isSunday ? 'Nghỉ chủ nhật' : null,
        });
      }
    }
  }

  // ── Shorthand collections ─────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _barbers =>
      _db.collection('barbers');
  CollectionReference<Map<String, dynamic>> get _services =>
      _db.collection('services');
  CollectionReference<Map<String, dynamic>> get _bookings =>
      _db.collection('bookings');
  CollectionReference<Map<String, dynamic>> get _transactions =>
      _db.collection('transactions');
  CollectionReference<Map<String, dynamic>> get _reviews =>
      _db.collection('reviews');
  CollectionReference<Map<String, dynamic>> get _schedules =>
      _db.collection('schedules');

  // =========================================================================
  // BARBERS
  // =========================================================================

  /// Stream toàn bộ danh sách barber (real-time)
  Stream<List<BarberModel>> barbersStream() {
    return _barbers.snapshots().map(
      (snap) => snap.docs.map((d) => _barberFromDoc(d)).toList(),
    );
  }

  Future<List<BarberModel>> getBarbers() async {
    final snap = await _barbers.get();
    return snap.docs.map((d) => _barberFromDoc(d)).toList();
  }

  Future<BarberModel?> getBarberByUserId(int userId) async {
    final snap = await _barbers
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return _barberFromDoc(snap.docs.first);
  }

  Future<void> updateBarberStatus(int userId, String newStatus) async {
    final snap = await _barbers
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      await snap.docs.first.reference.update({'status': newStatus});
    }
  }

  BarberModel _barberFromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final j = d.data()!;
    return BarberModel(
      userId: (j['userId'] as num).toInt(),
      fullName: j['fullName'] as String? ?? '',
      phone: j['phone'] as String? ?? '',
      avatarUrl: j['avatarUrl'] as String?,
      bio: j['bio'] as String? ?? '',
      specialty: j['specialty'] as String? ?? '',
      yearsExperience: (j['yearsExperience'] as num?)?.toInt() ?? 0,
      status: j['status'] as String? ?? 'available',
      avgRating: (j['avgRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (j['reviewCount'] as num?)?.toInt() ?? 0,
      portfolioImages:
          (j['portfolioImages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  // =========================================================================
  // SERVICES
  // =========================================================================

  Future<List<ServiceModel>> fetchServices() async {
    final snap = await _services.get();
    return snap.docs.map((d) {
      final j = d.data();
      return ServiceModel(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: j['name'] as String? ?? '',
        description: j['description'] as String? ?? '',
        price: (j['price'] as num?)?.toDouble() ?? 0,
        durationMin: (j['durationMin'] as num?)?.toInt() ?? 0,
        imageUrl: j['imageUrl'] as String? ?? '',
        isActive: j['isActive'] as bool? ?? true,
      );
    }).toList();
  }

  // =========================================================================
  // BOOKINGS
  // =========================================================================

  /// Stream bookings của một barber (dùng cho staff dashboard)
  Stream<List<BookingModel>> barberBookingsStream(int staffId) {
    return _bookings
        .where('staffId', isEqualTo: staffId)
        .orderBy('bookingDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => _bookingFromDoc(d)).toList());
  }

  /// Stream bookings của customer hiện tại
  Stream<List<BookingModel>> customerBookingsStream(int customerId) {
    return _bookings
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => _bookingFromDoc(d)).toList());
  }

  /// Tất cả bookings cho receptionist (real-time)
  Stream<List<BookingModel>> allBookingsStream() {
    return _bookings
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => _bookingFromDoc(d)).toList());
  }

  List<BookingModel> getBookingsForDate(DateTime date) {
    return bookings.where((b) {
      return b.bookingDate.year == date.year &&
          b.bookingDate.month == date.month &&
          b.bookingDate.day == date.day;
    }).toList();
  }

  Future<void> updateBookingStatusById(int bookingId, String newStatus) async {
    final snap = await _bookings
        .where('id', isEqualTo: bookingId)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      await snap.docs.first.reference.update({'status': newStatus});
      // Auto-update barber status
      if (newStatus == 'in_progress') {
        final booking = _bookingFromDoc(snap.docs.first);
        await updateBarberStatus(booking.staffId, 'busy');
      } else if (newStatus == 'completed' || newStatus == 'cancelled') {
        final booking = _bookingFromDoc(snap.docs.first);
        // Check nếu không còn booking in_progress nào khác của barber này
        final remaining = await _bookings
            .where('staffId', isEqualTo: booking.staffId)
            .where('status', isEqualTo: 'in_progress')
            .get();
        if (remaining.docs.isEmpty) {
          await updateBarberStatus(booking.staffId, 'available');
        }
      }
    }
  }

  BookingModel createBooking({
    required BarberModel barber,
    required List<ServiceModel> selectedServices,
    required DateTime date,
    required String timeSlot,
    String? note,
    bool isWalkIn = false,
    String? customerName,
    String? customerPhone,
    bool immediateStart = false,
  }) {
    final user = _session.currentUser;
    final totalPrice = selectedServices.fold<double>(
      0,
      (sum, s) => sum + s.price,
    );
    final totalMin = selectedServices.fold<int>(
      0,
      (sum, s) => sum + s.durationMin,
    );
    final slotsCount = (totalMin / 60.0).ceil() < 1 ? 1 : (totalMin / 60.0).ceil();
    final endTimeSlot = calculateEndTime(timeSlot, slotsCount);

    final status = immediateStart ? 'in_progress' : 'confirmed';
    final autoId = DateTime.now().millisecondsSinceEpoch;
    final now = DateTime.now();

    final booking = BookingModel(
      id: autoId,
      customerId: isWalkIn ? 0 : (user?.id ?? 0),
      customerUid: isWalkIn ? '' : (user?.uid ?? ''),
      customerName: isWalkIn
          ? (customerName ?? 'Khách Vãng Lai')
          : (user?.fullName ?? ''),
      customerPhone: isWalkIn ? customerPhone : user?.phone,
      isWalkIn: isWalkIn,
      staffId: barber.userId,
      staffName: barber.fullName,
      staffAvatar: barber.avatarUrl,
      bookingDate: date,
      startTime: timeSlot,
      endTime: endTimeSlot,
      status: status,
      totalPrice: totalPrice,
      services: selectedServices,
      note: note,
      createdAt: now,
    );

    _bookings.add({
      'id': autoId,
      'customerId': booking.customerId,
      'customerUid': booking.customerUid,
      'customerName': booking.customerName,
      'customerPhone': booking.customerPhone,
      'isWalkIn': isWalkIn,
      'staffId': barber.userId,
      'staffName': barber.fullName,
      'staffAvatar': barber.avatarUrl,
      'bookingDate': Timestamp.fromDate(date),
      'startTime': timeSlot,
      'endTime': endTimeSlot,
      'status': status,
      'totalPrice': totalPrice,
      'services': selectedServices
          .map(
            (s) => {
              'id': s.id,
              'name': s.name,
              'description': s.description,
              'price': s.price,
              'durationMin': s.durationMin,
              'imageUrl': s.imageUrl,
              'isActive': s.isActive,
            },
          )
          .toList(),
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _transactions.add({
      'id': autoId + 1,
      'bookingId': autoId,
      'customerId': booking.customerId,
      'customerUid': booking.customerUid,
      'customerName': booking.customerName,
      'customerPhone': booking.customerPhone,
      'amount': totalPrice,
      'discount': 0,
      'tipAmount': 0,
      'method': 'cash',
      'status': 'unpaid',
      'createdAt': FieldValue.serverTimestamp(),
      'serviceSummary': selectedServices.map((s) => s.name).join(', '),
      'staffName': barber.fullName,
      'staffAvatar': barber.avatarUrl,
      'bookingDate': Timestamp.fromDate(date),
      'timeSlot': timeSlot,
      'services': selectedServices.map((s) => s.toJson()).toList(),
    });

    if (immediateStart) {
      updateBarberStatus(barber.userId, 'busy');
    }

    return booking;
  }

  BookingModel createWalkInBooking({
    required String customerName,
    String? customerPhone,
    required BarberModel barber,
    required List<ServiceModel> selectedServices,
    required DateTime date,
    required String timeSlot,
    String? note,
    bool immediateStart = false,
  }) {
    return createBooking(
      barber: barber,
      selectedServices: selectedServices,
      date: date,
      timeSlot: timeSlot,
      note: note,
      isWalkIn: true,
      customerName: customerName,
      customerPhone: customerPhone,
      immediateStart: immediateStart,
    );
  }

  Future<void> reassignBookingBarber(
    int bookingId,
    BarberModel newBarber,
  ) async {
    final snap = await _bookings
        .where('id', isEqualTo: bookingId)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      await snap.docs.first.reference.update({
        'staffId': newBarber.userId,
        'staffName': newBarber.fullName,
        'staffAvatar': newBarber.avatarUrl,
      });
    }
  }

  Future<void> rescheduleBooking(
    int bookingId,
    DateTime newDate,
    String newTimeSlot,
  ) async {
    final snap = await _bookings
        .where('id', isEqualTo: bookingId)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      await snap.docs.first.reference.update({
        'bookingDate': Timestamp.fromDate(newDate),
        'startTime': newTimeSlot,
        'endTime': newTimeSlot,
      });
    }
  }

  Future<void> cancelBooking(int bookingId, {String? reason}) async {
    final snap = await _bookings
        .where('id', isEqualTo: bookingId)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      final doc = snap.docs.first;
      final old = _bookingFromDoc(doc);
      final noteWithReason = reason != null && reason.trim().isNotEmpty
          ? '${old.note != null && old.note!.isNotEmpty ? "${old.note} | " : ""}[Đã hủy: ${reason.trim()}]'
          : old.note;
      await doc.reference.update({
        'status': 'cancelled',
        'note': noteWithReason,
      });
      await updateBarberStatus(old.staffId, 'available');
    }
  }

  /// Lấy danh sách khung giờ mà 1 đơn đặt lịch b chiếm dụng
  List<String> getOccupiedSlotsForBooking(BookingModel b) {
    final totalMin = b.services.fold<int>(0, (sum, s) => sum + s.durationMin);
    var slotsCount = (totalMin / 60.0).ceil();
    if (slotsCount < 1) slotsCount = 1;

    final startIndex = allTimeSlots.indexOf(b.startTime);
    if (startIndex == -1) return [b.startTime];

    final result = <String>[];
    for (var i = 0; i < slotsCount && (startIndex + i) < allTimeSlots.length; i++) {
      result.add(allTimeSlots[startIndex + i]);
    }
    return result;
  }

  /// Lấy danh sách N khung giờ liên tiếp bắt đầu từ startSlot
  List<String>? getRequiredSlots(String startSlot, int requiredSlotsCount) {
    if (requiredSlotsCount <= 1) return [startSlot];
    final startIndex = allTimeSlots.indexOf(startSlot);
    if (startIndex == -1) return null;
    if (startIndex + requiredSlotsCount > allTimeSlots.length) {
      return null; // Không đủ khung giờ còn lại trong ngày
    }
    return allTimeSlots.sublist(startIndex, startIndex + requiredSlotsCount);
  }

  /// Tính giờ kết thúc (endTime) ví dụ '09:00' với 2 slot -> '11:00'
  String calculateEndTime(String startSlot, int requiredSlotsCount) {
    final req = getRequiredSlots(startSlot, requiredSlotsCount);
    final lastSlot = (req != null && req.isNotEmpty) ? req.last : startSlot;

    final parts = lastSlot.split(':');
    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]);
      final minute = parts[1];
      if (hour != null) {
        final endHour = (hour + 1).toString().padLeft(2, '0');
        return '$endHour:$minute';
      }
    }
    return lastSlot;
  }

  /// Kiểm tra 1 barber có rảnh toàn bộ requiredSlots vào ngày date không
  bool isBarberAvailable(int staffId, DateTime date, List<String> requiredSlots) {
    final activeBookings = bookings.where(
      (b) =>
          b.staffId == staffId &&
          b.status != 'cancelled' &&
          b.bookingDate.year == date.year &&
          b.bookingDate.month == date.month &&
          b.bookingDate.day == date.day,
    );

    final busySlots = <String>{};
    for (final b in activeBookings) {
      busySlots.addAll(getOccupiedSlotsForBooking(b));
    }

    return requiredSlots.every((slot) => !busySlots.contains(slot));
  }

  /// Lấy các khung giờ còn rảnh của 1 staff
  List<String> getAvailableTimeSlots(
    int staffId,
    DateTime date, {
    int requiredSlotsCount = 1,
  }) {
    return allTimeSlots.where((startSlot) {
      final requiredSlots = getRequiredSlots(startSlot, requiredSlotsCount);
      if (requiredSlots == null) return false;
      return isBarberAvailable(staffId, date, requiredSlots);
    }).toList();
  }

  /// Lấy danh sách thợ còn RẢNH vào ngày & khung giờ cụ thể (hỗ trợ N slots liên tiếp)
  List<BarberModel> getAvailableBarbers(
    DateTime date,
    String timeSlot, {
    int requiredSlotsCount = 1,
  }) {
    if (timeSlot.trim().isEmpty) return barbers;
    final requiredSlots = getRequiredSlots(timeSlot, requiredSlotsCount);
    if (requiredSlots == null) return [];

    return barbers.where((b) => isBarberAvailable(b.userId, date, requiredSlots)).toList();
  }

  /// Lấy đơn đặt lịch gần nhất của Khách hàng theo User UID
  BookingModel? getLastBookingForCustomer([int? customerId]) {
    final user = currentUser;
    final uid = user?.uid ?? '';

    final list = bookings.where((b) {
      if (b.status == 'cancelled') return false;
      if (uid.isNotEmpty && b.customerUid.isNotEmpty) {
        return b.customerUid == uid;
      }
      return false;
    }).toList();

    if (list.isEmpty) return null;
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.first;
  }

  List<BookingModel> getBarberBookings(int staffId) =>
      bookings.where((b) => b.staffId == staffId).toList();

  BookingModel? getBarberCurrentJob(int staffId) {
    try {
      return bookings.firstWhere(
        (b) => b.staffId == staffId && b.status == 'in_progress',
      );
    } catch (_) {
      return null;
    }
  }

  String getBarberDynamicStatus(int staffId) {
    if (getBarberCurrentJob(staffId) != null) return 'busy';
    try {
      return barbers.firstWhere((b) => b.userId == staffId).status;
    } catch (_) {
      return 'available';
    }
  }

  void checkInBooking(int bookingId) {
    updateBookingStatusById(bookingId, 'checked_in');
  }

  void updateBookingStatus(int bookingId, String newStatus) {
    updateBookingStatusById(bookingId, newStatus);
  }

  /// Lấy danh sách giao dịch của Khách hàng hiện tại dựa theo User UID
  List<TransactionModel> getCurrentUserTransactions() {
    final user = currentUser;
    if (user == null || user.uid.isEmpty) return [];

    final list = transactions
        .where((t) => t.customerUid == user.uid)
        .toList();

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  BookingModel? getBookingById(int bookingId) {
    try {
      return bookings.firstWhere((b) => b.id == bookingId);
    } catch (_) {
      return null;
    }
  }

  BookingModel _bookingFromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final j = d.data()!;
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.parse(v);
      return DateTime.now();
    }

    return BookingModel(
      id: (j['id'] as num?)?.toInt() ?? d.id.hashCode.abs(),
      customerId: (j['customerId'] as num?)?.toInt() ?? 0,
      customerUid: j['customerUid'] as String? ?? '',
      customerName: j['customerName'] as String?,
      customerPhone: j['customerPhone'] as String?,
      isWalkIn: j['isWalkIn'] as bool? ?? false,
      staffId: (j['staffId'] as num).toInt(),
      staffName: j['staffName'] as String? ?? '',
      staffAvatar: j['staffAvatar'] as String?,
      bookingDate: parseDate(j['bookingDate']),
      startTime: j['startTime'] as String? ?? '',
      endTime: j['endTime'] as String? ?? '',
      status: j['status'] as String? ?? 'pending',
      totalPrice: (j['totalPrice'] as num?)?.toDouble() ?? 0,
      services: (j['services'] as List<dynamic>? ?? [])
          .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      note: j['note'] as String?,
      createdAt: parseDate(j['createdAt']),
    );
  }

  // =========================================================================
  // TRANSACTIONS
  // =========================================================================

  Stream<List<TransactionModel>> customerTransactionsStream(String customerUid) {
    return _transactions
        .where('customerUid', isEqualTo: customerUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => _txFromDoc(d)).toList());
  }

  Stream<List<TransactionModel>> allTransactionsStream() {
    return _transactions
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => _txFromDoc(d)).toList());
  }

  Future<void> markPaymentPaid(int bookingId, String method) async {
    // Update transaction
    final txSnap = await _transactions
        .where('bookingId', isEqualTo: bookingId)
        .limit(1)
        .get();
    if (txSnap.docs.isNotEmpty) {
      await txSnap.docs.first.reference.update({
        'status': 'paid',
        'method': method,
        'paidAt': FieldValue.serverTimestamp(),
      });
    }
    // Auto-complete booking
    await updateBookingStatusById(bookingId, 'completed');
  }

  Future<void> addTipToTransaction(int txId, double tipAmount) async {
    final txSnap = await _transactions
        .where('id', isEqualTo: txId)
        .limit(1)
        .get();
    if (txSnap.docs.isNotEmpty) {
      await txSnap.docs.first.reference.update({
        'tipAmount': tipAmount,
      });
    } else {
      final idx = transactions.indexWhere((t) => t.id == txId);
      if (idx != -1) {
        transactions[idx] = transactions[idx].copyWith(tipAmount: tipAmount);
        notifyListeners();
      }
    }
  }

  TransactionModel _txFromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final j = d.data()!;
    DateTime? parseOptDate(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.parse(v);
      return null;
    }

    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.parse(v);
      return DateTime.now();
    }

    final parsedServices = (j['services'] as List<dynamic>?)
        ?.map((s) => ServiceModel.fromJson(s as Map<String, dynamic>))
        .toList();

    return TransactionModel(
      id: (j['id'] as num?)?.toInt() ?? d.id.hashCode.abs(),
      bookingId: (j['bookingId'] as num?)?.toInt() ?? 0,
      customerId: (j['customerId'] as num?)?.toInt() ?? 0,
      customerUid: j['customerUid'] as String? ?? '',
      customerName: j['customerName'] as String?,
      customerPhone: j['customerPhone'] as String?,
      amount: (j['amount'] as num?)?.toDouble() ?? 0,
      discount: (j['discount'] as num?)?.toDouble() ?? 0,
      tipAmount: (j['tipAmount'] as num?)?.toDouble() ?? 0,
      method: j['method'] as String? ?? 'cash',
      status: j['status'] as String? ?? 'unpaid',
      paidAt: parseOptDate(j['paidAt']),
      createdAt: parseDate(j['createdAt']),
      serviceSummary: j['serviceSummary'] as String? ?? '',
      staffName: j['staffName'] as String?,
      staffAvatar: j['staffAvatar'] as String?,
      bookingDate: parseOptDate(j['bookingDate']),
      timeSlot: j['timeSlot'] as String?,
      services: parsedServices,
    );
  }

  // =========================================================================
  // REVIEWS
  // =========================================================================

  Stream<List<ReviewModel>> barberReviewsStream(int staffId) {
    return _reviews
        .where('staffId', isEqualTo: staffId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => _reviewFromDoc(d)).toList());
  }

  List<ReviewModel> getReviewsForBarber(int staffId) {
    final list = reviews.where((r) => r.staffId == staffId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  bool hasUserReviewedBarber(int staffId) {
    final user = _session.currentUser;
    if (user == null) return false;
    return reviews.any(
      (r) => r.staffId == staffId && r.customerId == user.id,
    );
  }

  bool canUserReviewBarber(int staffId) => !hasUserReviewedBarber(staffId);

  bool addReview({
    required int staffId,
    required int rating,
    required String comment,
    int? bookingId,
  }) {
    final user = _session.currentUser;
    if (user == null) return false;
    if (hasUserReviewedBarber(staffId)) return false;
    _addReviewAsync(
      staffId: staffId,
      rating: rating,
      comment: comment,
      bookingId: bookingId,
    );
    return true;
  }

  Future<void> _addReviewAsync({
    required int staffId,
    required int rating,
    required String comment,
    int? bookingId,
  }) async {
    final user = _session.currentUser;
    if (user == null) return;

    final autoId = DateTime.now().millisecondsSinceEpoch;
    await _reviews.add({
      'id': autoId,
      'bookingId': bookingId ?? autoId,
      'customerId': user.id,
      'customerName': user.fullName,
      'customerAvatar': user.avatarUrl,
      'staffId': staffId,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Tính lại avgRating cho barber
    final allReviews = await _reviews
        .where('staffId', isEqualTo: staffId)
        .get();
    if (allReviews.docs.isNotEmpty) {
      final totalRating = allReviews.docs.fold<int>(
        0,
        (sum, d) => sum + ((d.data()['rating'] as num?)?.toInt() ?? 0),
      );
      final newAvg = totalRating / allReviews.docs.length;
      final barberSnap = await _barbers
          .where('userId', isEqualTo: staffId)
          .limit(1)
          .get();
      if (barberSnap.docs.isNotEmpty) {
        await barberSnap.docs.first.reference.update({
          'avgRating': double.parse(newAvg.toStringAsFixed(1)),
          'reviewCount': allReviews.docs.length,
        });
      }
    }

    notifyListeners();
  }

  ReviewModel _reviewFromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final j = d.data()!;
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.parse(v);
      return DateTime.now();
    }

    return ReviewModel(
      id: (j['id'] as num?)?.toInt() ?? d.id.hashCode.abs(),
      bookingId: (j['bookingId'] as num?)?.toInt() ?? 0,
      customerId: (j['customerId'] as num?)?.toInt() ?? 0,
      customerName: j['customerName'] as String? ?? '',
      customerAvatar: j['customerAvatar'] as String?,
      staffId: (j['staffId'] as num).toInt(),
      rating: (j['rating'] as num).toInt(),
      comment: j['comment'] as String? ?? '',
      createdAt: parseDate(j['createdAt']),
    );
  }

  // =========================================================================
  // SCHEDULES (Lịch làm việc)
  // =========================================================================

  Future<List<StaffScheduleModel>> getSchedulesForStaff(int staffId) async {
    final snap = await _schedules.where('staffId', isEqualTo: staffId).get();
    return snap.docs.map((d) {
      final j = d.data();
      DateTime workDate;
      final raw = j['workDate'];
      if (raw is Timestamp) {
        workDate = raw.toDate();
      } else if (raw is String) {
        workDate = DateTime.parse(raw);
      } else {
        workDate = DateTime.now();
      }
      return StaffScheduleModel(
        id: (j['id'] as num?)?.toInt() ?? d.id.hashCode.abs(),
        staffId: (j['staffId'] as num?)?.toInt() ?? staffId,
        workDate: workDate,
        startTime: j['startTime'] as String? ?? '08:00',
        endTime: j['endTime'] as String? ?? '20:00',
        isDayOff: j['isDayOff'] as bool? ?? false,
        note: j['note'] as String?,
      );
    }).toList();
  }

  // =========================================================================
  // STAFF DASHBOARD — thay thế ApiService.getStaffDashboard()
  // =========================================================================

  Future<StaffDashboardData> getStaffDashboard(int staffId) async {
    final user = _session.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập.');

    final barber =
        await getBarberByUserId(staffId) ??
        BarberModel(
          userId: staffId,
          fullName: user.fullName,
          phone: user.phone,
          bio: '',
          specialty: '',
          yearsExperience: 0,
          status: 'available',
          avgRating: 0,
          reviewCount: 0,
          portfolioImages: const [],
        );

    final bookingSnap = await _bookings
        .where('staffId', isEqualTo: staffId)
        .get();
    final bookings = bookingSnap.docs.map((d) => _bookingFromDoc(d)).toList();
    final reviews = getReviewsForBarber(staffId);
    final schedules = await getSchedulesForStaff(staffId);

    return StaffDashboardData(
      user: user,
      barber: barber,
      bookings: bookings,
      reviews: reviews,
      schedules: schedules,
      timeSlots: allTimeSlots,
    );
  }

  // =========================================================================
  // USER PROFILE
  // =========================================================================

  Future<void> updateUserProfile({
    String? uid,
    required String fullName,
    required String phone,
    String? email,
    String? address,
    String? avatarUrl,
  }) async {
    final docId = uid ?? currentUser?.uid;
    if (docId == null || docId.isEmpty) return;
    await _users.doc(docId).update({
      'fullName': fullName,
      'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    });
    // Cập nhật lại session
    final user = _session.currentUser;
    if (user != null) {
      _session.setUser(
        user.copyWith(
          fullName: fullName,
          phone: phone,
          email: email ?? user.email,
          address: address ?? user.address,
          avatarUrl: avatarUrl ?? user.avatarUrl,
        ),
      );
    }
    notifyListeners();
  }

  // =========================================================================
  // LOGOUT
  // =========================================================================

  Future<void> logout() async {
    _session.logout();
    notifyListeners();
    await FirebaseAuthService().logout();
  }
}
