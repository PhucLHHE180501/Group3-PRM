import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_config.dart';
import '../models/barber_model.dart';
import '../models/booking_model.dart';
import '../models/review_model.dart';
import '../models/schedule_model.dart';
import '../models/user_model.dart';

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

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<UserModel> login(String phone, String password) async {
    final res = await _post('/api/auth/login', {
      'phone': phone,
      'password': password,
    });
    return UserModel.fromJson(res as Map<String, dynamic>);
  }

  Future<StaffDashboardData> getStaffDashboard(int barberId) async {
    final res = await _get('/api/staff/$barberId/dashboard');
    final map = res as Map<String, dynamic>;
    return StaffDashboardData(
      user: UserModel.fromJson(map['user'] as Map<String, dynamic>),
      barber: BarberModel.fromJson(map['barber'] as Map<String, dynamic>),
      bookings: (map['bookings'] as List<dynamic>)
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      reviews: (map['reviews'] as List<dynamic>)
          .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      schedules: (map['schedules'] as List<dynamic>? ?? [])
          .map((e) => StaffScheduleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      timeSlots: (map['timeSlots'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
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
          ],
    );
  }

  Future<void> completeBooking(int barberId, int bookingId) async {
    await _post('/api/staff/$barberId/bookings/$bookingId/complete', {});
  }

  Future<dynamic> _get(String path) async {
    try {
      final res = await http.get(_uri(path)).timeout(const Duration(seconds: 8));
      return _decode(res);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(_offlineMessage);
    }
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    try {
      final res = await http
          .post(
            _uri(path),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 8));
      return _decode(res);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(_offlineMessage);
    }
  }

  dynamic _decode(http.Response res) {
    final body = res.body.isEmpty ? {} : jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final message = body is Map && body['message'] != null
        ? body['message'].toString()
        : 'Không thể tải dữ liệu (mã ${res.statusCode}).';
    throw ApiException(message);
  }

  static const _offlineMessage =
      'Không kết nối được API. Hãy chạy backend: cd backend/BarberShopApi && dotnet run';
}
