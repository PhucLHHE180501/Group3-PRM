import 'package:flutter_test/flutter_test.dart';
import 'package:barber_booking_app/shared/models/barber_model.dart';
import 'package:barber_booking_app/shared/models/booking_model.dart';
import 'package:barber_booking_app/shared/models/service_model.dart';
import 'package:barber_booking_app/shared/services/firebase_service.dart';

void main() {
  group('FirebaseService Receptionist Realtime & Dynamic Status Tests', () {
    late FirebaseService service;

    setUp(() {
      service = FirebaseService();
    });

    test('allTimeSlots is properly ordered with 12:00 before 13:00', () {
      final slots = service.allTimeSlots;
      final idx12 = slots.indexOf('12:00');
      final idx13 = slots.indexOf('13:00');

      expect(idx12, isNot(-1));
      expect(idx13, isNot(-1));
      expect(idx12, lessThan(idx13));
    });

    test('getCurrentTimeSlot maps current hour correctly', () {
      final timeAt9 = DateTime(2026, 11, 4, 9, 35);
      expect(service.getCurrentTimeSlot(timeAt9), equals('09:00'));

      final timeAt14 = DateTime(2026, 11, 4, 14, 10);
      expect(service.getCurrentTimeSlot(timeAt14), equals('14:00'));

      final timeAtMidnight = DateTime(2026, 11, 4, 2, 0);
      expect(service.getCurrentTimeSlot(timeAtMidnight), isNull);
    });

    test('getBarberCurrentJob filters out yesterday in_progress booking and finds today', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final testBarber = BarberModel(
        userId: 101,
        fullName: 'Test Barber',
        phone: '0901234567',
        specialty: 'Fade',
        yearsExperience: 5,
        status: 'available',
        avgRating: 4.8,
        reviewCount: 10,
        portfolioImages: [],
      );

      service.barbers = [testBarber];

      // Booking yesterday left in_progress
      final oldBooking = BookingModel(
        id: 1,
        customerId: 1,
        staffId: 101,
        staffName: 'Test Barber',
        bookingDate: yesterday,
        startTime: '10:00',
        endTime: '11:00',
        status: 'in_progress',
        totalPrice: 100000,
        services: [
          ServiceModel(id: 1, name: 'Cut', description: '', price: 100000, durationMin: 45, imageUrl: '')
        ],
        createdAt: yesterday,
      );

      service.bookings = [oldBooking];

      // Yesterday's job should NOT make barber busy today
      expect(service.getBarberCurrentJob(101, now), isNull);
      expect(service.getBarberDynamicStatus(101), equals('available'));

      // Now add an active booking today for current time slot
      final currentHour = now.hour;
      final currentSlot = '${currentHour.toString().padLeft(2, '0')}:00';

      if (service.allTimeSlots.contains(currentSlot)) {
        final todayBooking = BookingModel(
          id: 2,
          customerId: 2,
          customerName: 'Today Guest',
          staffId: 101,
          staffName: 'Test Barber',
          bookingDate: now,
          startTime: currentSlot,
          endTime: currentSlot,
          status: 'confirmed',
          totalPrice: 150000,
          services: [
            ServiceModel(id: 1, name: 'Cut', description: '', price: 150000, durationMin: 45, imageUrl: '')
          ],
          createdAt: now,
        );

        service.bookings = [oldBooking, todayBooking];

        // Should map current slot today and mark busy!
        expect(service.getBarberCurrentJob(101, now), isNotNull);
        expect(service.getBarberCurrentJob(101, now)?.customerName, equals('Today Guest'));
        expect(service.getBarberDynamicStatus(101), equals('busy'));
      }
    });
  });
}
