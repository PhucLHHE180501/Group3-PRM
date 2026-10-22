import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/barber_model.dart';
import '../models/service_model.dart';
import '../models/booking_model.dart';
import '../models/transaction_model.dart';
import '../models/review_model.dart';

class MockDataService extends ChangeNotifier {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal();

  // List of accounts for login (Phone & Passwords)
  final List<Map<String, dynamic>> _userAccounts = [
    {
      'user': UserModel(
        id: 1,
        role: 'customer',
        fullName: 'Nguyễn Văn An',
        phone: '0987654321',
        email: 'nguyenvanan@gmail.com',
        avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400',
        gender: 'Nam',
        dateOfBirth: '1998-05-15',
        address: '123 Nguyễn Trãi, Quận 1, TP. Hồ Chí Minh',
        isActive: true,
      ),
      'password': '123456',
    },
    {
      'user': UserModel(
        id: 101,
        role: 'staff',
        fullName: 'Trần Văn Quốc (Quốc Barber)',
        phone: '0912345678',
        email: 'quocbarber@gmail.com',
        avatarUrl: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=400',
        gender: 'Nam',
        dateOfBirth: '1995-08-20',
        address: '456 Lê Lợi, Quận 1, TP. Hồ Chí Minh',
        isActive: true,
      ),
      'password': '123456',
    },
    {
      'user': UserModel(
        id: 201,
        role: 'receptionist',
        fullName: 'Lê Thị Mai (Lễ Tân)',
        phone: '0900000000',
        email: 'mai.letan@barber.com',
        avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400',
        gender: 'Nữ',
        dateOfBirth: '2000-01-10',
        address: '789 Điện Biên Phủ, Quận 3, TP. Hồ Chí Minh',
        isActive: true,
      ),
      'password': '123456',
    },
  ];

  // Currently logged in user
  UserModel? currentUser;

  // Login function
  UserModel? login(String phone, String password) {
    for (var acc in _userAccounts) {
      final user = acc['user'] as UserModel;
      final pass = acc['password'] as String;
      if (user.phone == phone && pass == password) {
        currentUser = user;
        notifyListeners();
        return user;
      }
    }
    return null;
  }

  // Quick Login as specific Role for testing
  UserModel loginAsRole(String role) {
    final acc = _userAccounts.firstWhere(
      (a) => (a['user'] as UserModel).role == role,
      orElse: () => _userAccounts.first,
    );
    currentUser = acc['user'] as UserModel;
    notifyListeners();
    return currentUser!;
  }

  // Logout function
  void logout() {
    currentUser = null;
    notifyListeners();
  }

  // Barbers list
  List<BarberModel> barbers = [
    BarberModel(
      userId: 101,
      fullName: 'Trần Văn Quốc (Quốc Barber)',
      phone: '0912345678',
      avatarUrl: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=400',
      bio: 'Chuyên gia tạo kiểu tóc nam ngắn, Fade, Undercut với hơn 6 năm kinh nghiệm.',
      specialty: 'Fade, Undercut, Modern Pompadour',
      yearsExperience: 6,
      status: 'busy',
      avgRating: 4.9,
      reviewCount: 28,
      portfolioImages: [
        'https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=600',
        'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=600',
        'https://images.unsplash.com/photo-1599566150163-29194dcaad36?w=600',
        'https://images.unsplash.com/photo-1517832606589-7150a6d71b48?w=600',
      ],
    ),
    BarberModel(
      userId: 102,
      fullName: 'Lê Hoàng Nam (Nam Barber)',
      phone: '0922334455',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
      bio: 'Yêu thích phong cách cổ điển Classic & Side Part.',
      specialty: 'Classic Cut, Side Part, Cạo Râu Nghệ Thuật',
      yearsExperience: 4,
      status: 'available',
      avgRating: 4.8,
      reviewCount: 19,
      portfolioImages: [
        'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=600',
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600',
      ],
    ),
    BarberModel(
      userId: 103,
      fullName: 'Phạm Minh Đức (Đức Barber)',
      phone: '0933445566',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
      bio: 'Chuyên gia Uốn Texture, Nhuộm màu thời trang cá tính.',
      specialty: 'Uốn Texture, Nhuộm Tẩy, Mullet Modern',
      yearsExperience: 5,
      status: 'available',
      avgRating: 4.7,
      reviewCount: 15,
      portfolioImages: [
        'https://images.unsplash.com/photo-1567894340315-735d7c361db0?w=600',
        'https://images.unsplash.com/photo-1621605815971-fbc98d665033?w=600',
      ],
    ),
  ];

  // Services
  List<ServiceModel> services = [
    ServiceModel(
      id: 1,
      name: 'Cắt Tóc Nam Combo 7 Bước',
      description: 'Tư vấn kiểu tóc + Cắt xả + Gội đầu thư giãn + Sấy tạo kiểu + Vuốt sáp.',
      price: 120000,
      durationMin: 45,
      imageUrl: 'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=400',
    ),
    ServiceModel(
      id: 2,
      name: 'Uốn Tóc Thời Trang (Texture)',
      description: 'Uốn xoăn bồng bềnh tự nhiên, tạo độ dày cho tóc mỏng.',
      price: 350000,
      durationMin: 60,
      imageUrl: 'https://images.unsplash.com/photo-1567894340315-735d7c361db0?w=400',
    ),
    ServiceModel(
      id: 3,
      name: 'Nhuộm Tóc Cao Cấp',
      description: 'Nhuộm màu thời trang chuẩn tone, dưỡng tóc mềm mượt.',
      price: 300000,
      durationMin: 60,
      imageUrl: 'https://images.unsplash.com/photo-1621605815971-fbc98d665033?w=400',
    ),
    ServiceModel(
      id: 4,
      name: 'Cạo Râu & Khăn Nóng',
      description: 'Cạo râu tiệt trùng + Đắp khăn nóng + Dưỡng da.',
      price: 60000,
      durationMin: 20,
      imageUrl: 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=400',
    ),
  ];

  // Bookings list
  List<BookingModel> bookings = [
    BookingModel(
      id: 1001,
      customerId: 1,
      customerName: 'Nguyễn Văn An',
      customerPhone: '0987654321',
      isWalkIn: false,
      staffId: 101,
      staffName: 'Trần Văn Quốc (Quốc Barber)',
      staffAvatar: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=400',
      bookingDate: DateTime.now(),
      startTime: '09:00',
      endTime: '09:45',
      status: 'in_progress',
      totalPrice: 120000,
      services: [
        ServiceModel(
          id: 1,
          name: 'Cắt Tóc Nam Combo 7 Bước',
          description: '',
          price: 120000,
          durationMin: 45,
          imageUrl: '',
        )
      ],
      note: 'Cắt gáy cao gọn gàng',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    BookingModel(
      id: 1002,
      customerId: 2,
      customerName: 'Trần Hoàng Bảo',
      customerPhone: '0933221100',
      isWalkIn: false,
      staffId: 101,
      staffName: 'Trần Văn Quốc (Quốc Barber)',
      staffAvatar: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=400',
      bookingDate: DateTime.now(),
      startTime: '10:00',
      endTime: '11:00',
      status: 'confirmed',
      totalPrice: 350000,
      services: [
        ServiceModel(
          id: 2,
          name: 'Uốn Tóc Thời Trang (Texture)',
          description: '',
          price: 350000,
          durationMin: 60,
          imageUrl: '',
        )
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    BookingModel(
      id: 1003,
      customerId: 0,
      customerName: 'Anh Phúc (Khách Vãng Lai)',
      customerPhone: '0918889999',
      isWalkIn: true,
      staffId: 102,
      staffName: 'Lê Hoàng Nam (Nam Barber)',
      staffAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
      bookingDate: DateTime.now(),
      startTime: '14:00',
      endTime: '14:45',
      status: 'confirmed',
      totalPrice: 180000,
      services: [
        ServiceModel(
          id: 1,
          name: 'Cắt Tóc Nam Combo 7 Bước',
          description: '',
          price: 120000,
          durationMin: 45,
          imageUrl: '',
        ),
        ServiceModel(
          id: 4,
          name: 'Cạo Râu & Khăn Nóng',
          description: '',
          price: 60000,
          durationMin: 20,
          imageUrl: '',
        ),
      ],
      note: 'Khách đến quầy đăng ký trực tiếp',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
  ];

  // Transactions list
  List<TransactionModel> transactions = [
    TransactionModel(
      id: 5001,
      bookingId: 1001,
      customerId: 1,
      amount: 120000,
      discount: 0,
      method: 'cash',
      status: 'unpaid',
      createdAt: DateTime.now(),
      serviceSummary: 'Cắt Tóc Nam Combo 7 Bước',
    ),
    TransactionModel(
      id: 5002,
      bookingId: 1002,
      customerId: 2,
      amount: 350000,
      discount: 0,
      method: 'cash',
      status: 'unpaid',
      createdAt: DateTime.now(),
      serviceSummary: 'Uốn Tóc Thời Trang (Texture)',
    ),
    TransactionModel(
      id: 5003,
      bookingId: 1003,
      customerId: 0,
      amount: 180000,
      discount: 0,
      method: 'cash',
      status: 'unpaid',
      createdAt: DateTime.now(),
      serviceSummary: 'Cắt Tóc Nam Combo 7 Bước, Cạo Râu & Khăn Nóng',
    ),
  ];

  // Reviews list
  List<ReviewModel> reviews = [
    ReviewModel(
      id: 1,
      bookingId: 1001,
      customerId: 1,
      customerName: 'Nguyễn Văn An',
      customerAvatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400',
      staffId: 101,
      rating: 5,
      comment: 'Anh Quốc cắt tỉa rất kỹ, tư vấn nhiệt tình đúng kiểu mình thích! 5 sao!',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  final List<String> allTimeSlots = [
    '08:00', '09:00', '10:00', '11:00',
    '13:00', '14:00', '15:00', '16:00',
    '17:00', '18:00', '19:00', '20:00'
  ];

  // --- METHODS ---

  // Dynamic status of a barber taking current active bookings into account
  String getBarberDynamicStatus(int staffId) {
    final now = DateTime.now();
    final hasInProgress = bookings.any((b) =>
        b.staffId == staffId &&
        b.bookingDate.year == now.year &&
        b.bookingDate.month == now.month &&
        b.bookingDate.day == now.day &&
        b.status == 'in_progress');
    if (hasInProgress) return 'busy';

    final barber = barbers.firstWhere(
      (b) => b.userId == staffId,
      orElse: () => barbers.first,
    );
    return barber.status;
  }

  // Get active current booking being served by staff
  BookingModel? getBarberCurrentJob(int staffId) {
    final now = DateTime.now();
    return bookings.cast<BookingModel?>().firstWhere(
      (b) =>
          b != null &&
          b.staffId == staffId &&
          b.bookingDate.year == now.year &&
          b.bookingDate.month == now.month &&
          b.bookingDate.day == now.day &&
          (b.status == 'in_progress' || b.status == 'checked_in'),
      orElse: () => null,
    );
  }

  // Update barber working status ('available', 'busy', 'break', 'off')
  void updateBarberStatus(int staffId, String newStatus) {
    final index = barbers.indexWhere((b) => b.userId == staffId);
    if (index != -1) {
      final old = barbers[index];
      barbers[index] = BarberModel(
        userId: old.userId,
        fullName: old.fullName,
        phone: old.phone,
        avatarUrl: old.avatarUrl,
        bio: old.bio,
        specialty: old.specialty,
        yearsExperience: old.yearsExperience,
        status: newStatus,
        avgRating: old.avgRating,
        reviewCount: old.reviewCount,
        portfolioImages: old.portfolioImages,
      );
      notifyListeners();
    }
  }

  // Update booking status ('pending', 'confirmed', 'checked_in', 'in_progress', 'completed', 'cancelled')
  void updateBookingStatus(int bookingId, String newStatus) {
    final index = bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      final oldBooking = bookings[index];
      bookings[index] = oldBooking.copyWith(status: newStatus);

      // If completed or cancelled, release barber to available if no other in_progress
      if (newStatus == 'completed' || newStatus == 'cancelled') {
        final remainingBusy = bookings.any((b) =>
            b.id != bookingId &&
            b.staffId == oldBooking.staffId &&
            b.status == 'in_progress');
        if (!remainingBusy) {
          updateBarberStatus(oldBooking.staffId, 'available');
        }
      } else if (newStatus == 'in_progress') {
        updateBarberStatus(oldBooking.staffId, 'busy');
      }

      // If completed, update corresponding transaction to paid
      if (newStatus == 'completed') {
        final txIdx = transactions.indexWhere((t) => t.bookingId == bookingId);
        if (txIdx != -1) {
          final tx = transactions[txIdx];
          transactions[txIdx] = TransactionModel(
            id: tx.id,
            bookingId: tx.bookingId,
            customerId: tx.customerId,
            amount: tx.amount,
            discount: tx.discount,
            method: tx.method,
            status: 'paid',
            paidAt: DateTime.now(),
            createdAt: tx.createdAt,
            serviceSummary: tx.serviceSummary,
          );
        }
      }

      notifyListeners();
    }
  }

  // Check-in booking by Receptionist
  void checkInBooking(int bookingId) {
    updateBookingStatus(bookingId, 'checked_in');
  }

  // Mark payment as paid by Receptionist
  void markPaymentPaid(int bookingId, String method) {
    final txIdx = transactions.indexWhere((t) => t.bookingId == bookingId);
    if (txIdx != -1) {
      final tx = transactions[txIdx];
      transactions[txIdx] = TransactionModel(
        id: tx.id,
        bookingId: tx.bookingId,
        customerId: tx.customerId,
        amount: tx.amount,
        discount: tx.discount,
        method: method,
        status: 'paid',
        paidAt: DateTime.now(),
        createdAt: tx.createdAt,
        serviceSummary: tx.serviceSummary,
      );
      // Auto complete the booking if paid
      updateBookingStatus(bookingId, 'completed');
      notifyListeners();
    }
  }

  // Walk-in booking directly created at reception desk
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
    final totalPrice = selectedServices.fold<double>(0, (sum, item) => sum + item.price);
    final bookingId = 1000 + bookings.length + 1;
    final initialStatus = immediateStart ? 'in_progress' : 'confirmed';

    final newBooking = BookingModel(
      id: bookingId,
      customerId: 0,
      customerName: customerName,
      customerPhone: customerPhone,
      isWalkIn: true,
      staffId: barber.userId,
      staffName: barber.fullName,
      staffAvatar: barber.avatarUrl,
      bookingDate: date,
      startTime: timeSlot,
      endTime: timeSlot,
      status: initialStatus,
      totalPrice: totalPrice,
      services: selectedServices,
      note: note,
      createdAt: DateTime.now(),
    );

    bookings.insert(0, newBooking);

    final newTransaction = TransactionModel(
      id: 5000 + transactions.length + 1,
      bookingId: bookingId,
      customerId: 0,
      amount: totalPrice,
      discount: 0,
      method: 'cash',
      status: 'unpaid',
      createdAt: DateTime.now(),
      serviceSummary: selectedServices.map((s) => s.name).join(', '),
    );

    transactions.insert(0, newTransaction);

    if (immediateStart) {
      updateBarberStatus(barber.userId, 'busy');
    }

    notifyListeners();
    return newBooking;
  }

  // Reassign barber for an existing booking
  void reassignBookingBarber(int bookingId, BarberModel newBarber) {
    final index = bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      final old = bookings[index];
      bookings[index] = old.copyWith(
        staffId: newBarber.userId,
        staffName: newBarber.fullName,
        staffAvatar: newBarber.avatarUrl,
      );
      notifyListeners();
    }
  }

  // Reschedule booking date/time
  void rescheduleBooking(int bookingId, DateTime newDate, String newTimeSlot) {
    final index = bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      final old = bookings[index];
      bookings[index] = old.copyWith(
        bookingDate: newDate,
        startTime: newTimeSlot,
        endTime: newTimeSlot,
      );
      notifyListeners();
    }
  }

  // Cancel booking
  void cancelBooking(int bookingId, {String? reason}) {
    final index = bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      final old = bookings[index];
      final noteWithReason = reason != null && reason.trim().isNotEmpty
          ? '${old.note != null && old.note!.isNotEmpty ? "${old.note} | " : ""}[Đã hủy: ${reason.trim()}]'
          : old.note;
      bookings[index] = old.copyWith(
        status: 'cancelled',
        note: noteWithReason,
      );
      // Free barber status
      updateBarberStatus(old.staffId, 'available');
      notifyListeners();
    }
  }

  // Available slots logic for a barber on specific date
  List<String> getAvailableTimeSlots(int staffId, DateTime date) {
    final existingBookedSlots = bookings.where((b) {
      final isSameStaff = b.staffId == staffId;
      final isSameDate = b.bookingDate.year == date.year &&
          b.bookingDate.month == date.month &&
          b.bookingDate.day == date.day;
      final isNotCancelled = b.status != 'cancelled';
      return isSameStaff && isSameDate && isNotCancelled;
    }).map((b) => b.startTime).toSet();

    return allTimeSlots.where((slot) => !existingBookedSlots.contains(slot)).toList();
  }

  // Get all bookings on specific date (not cancelled)
  List<BookingModel> getBookingsForDate(DateTime date) {
    return bookings.where((b) {
      return b.bookingDate.year == date.year &&
          b.bookingDate.month == date.month &&
          b.bookingDate.day == date.day &&
          b.status != 'cancelled';
    }).toList();
  }

  bool canUserReviewBarber(int staffId) {
    if (currentUser == null) return false;
    final hasReviewed = reviews.any((r) => r.customerId == currentUser!.id && r.staffId == staffId);
    return !hasReviewed;
  }

  bool hasUserReviewedBarber(int staffId) {
    if (currentUser == null) return false;
    return reviews.any((r) => r.customerId == currentUser!.id && r.staffId == staffId);
  }

  bool addReview({
    required int staffId,
    required int rating,
    required String comment,
    int? bookingId,
  }) {
    if (currentUser == null || !canUserReviewBarber(staffId)) {
      return false;
    }

    final newReview = ReviewModel(
      id: DateTime.now().millisecondsSinceEpoch,
      bookingId: bookingId ?? (DateTime.now().millisecondsSinceEpoch % 10000),
      customerId: currentUser!.id,
      customerName: currentUser!.fullName,
      customerAvatar: currentUser!.avatarUrl,
      staffId: staffId,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );

    reviews.insert(0, newReview);

    final staffIndex = barbers.indexWhere((b) => b.userId == staffId);
    if (staffIndex != -1) {
      final staffReviews = reviews.where((r) => r.staffId == staffId).toList();
      final totalRating = staffReviews.fold<int>(0, (sum, item) => sum + item.rating);
      final newAvg = totalRating / staffReviews.length;

      final oldBarber = barbers[staffIndex];
      barbers[staffIndex] = BarberModel(
        userId: oldBarber.userId,
        fullName: oldBarber.fullName,
        phone: oldBarber.phone,
        avatarUrl: oldBarber.avatarUrl,
        bio: oldBarber.bio,
        specialty: oldBarber.specialty,
        yearsExperience: oldBarber.yearsExperience,
        status: oldBarber.status,
        avgRating: double.parse(newAvg.toStringAsFixed(1)),
        reviewCount: staffReviews.length,
        portfolioImages: oldBarber.portfolioImages,
      );
    }

    notifyListeners();
    return true;
  }

  void updateUserProfile({
    required String fullName,
    required String phone,
    String? email,
    String? address,
    String? avatarUrl,
  }) {
    if (currentUser == null) return;
    currentUser = currentUser!.copyWith(
      fullName: fullName,
      phone: phone,
      email: email,
      address: address,
      avatarUrl: avatarUrl,
    );
    notifyListeners();
  }

  BookingModel createBooking({
    required BarberModel barber,
    required List<ServiceModel> selectedServices,
    required DateTime date,
    required String timeSlot,
    String? note,
  }) {
    final totalPrice = selectedServices.fold<double>(0, (sum, item) => sum + item.price);
    final bookingId = 1000 + bookings.length + 1;

    final newBooking = BookingModel(
      id: bookingId,
      customerId: currentUser?.id ?? 1,
      customerName: currentUser?.fullName ?? 'Khách Đặt Online',
      customerPhone: currentUser?.phone,
      isWalkIn: false,
      staffId: barber.userId,
      staffName: barber.fullName,
      staffAvatar: barber.avatarUrl,
      bookingDate: date,
      startTime: timeSlot,
      endTime: timeSlot,
      status: 'confirmed',
      totalPrice: totalPrice,
      services: selectedServices,
      note: note,
      createdAt: DateTime.now(),
    );

    bookings.insert(0, newBooking);

    final newTransaction = TransactionModel(
      id: 5000 + transactions.length + 1,
      bookingId: bookingId,
      customerId: currentUser?.id ?? 1,
      amount: totalPrice,
      discount: 0,
      method: 'cash',
      status: 'unpaid',
      createdAt: DateTime.now(),
      serviceSummary: selectedServices.map((s) => s.name).join(', '),
    );

    transactions.insert(0, newTransaction);

    notifyListeners();
    return newBooking;
  }

  List<ReviewModel> getReviewsForBarber(int staffId) {
    return reviews.where((r) => r.staffId == staffId).toList();
  }

  List<TransactionModel> getCurrentUserTransactions() {
    if (currentUser == null) return [];
    return transactions.where((t) => t.customerId == currentUser!.id).toList();
  }

  // Get bookings assigned to specific barber staff
  List<BookingModel> getBarberBookings(int staffId) {
    return bookings.where((b) => b.staffId == staffId).toList();
  }
}
