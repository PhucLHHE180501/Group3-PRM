import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

/// Exception ném ra khi tài khoản chưa được xác thực qua liên kết email
class EmailNotVerifiedException implements Exception {
  final String email;
  final String message;

  EmailNotVerifiedException({
    required this.email,
    required this.message,
  });

  @override
  String toString() => message;
}

class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// SĐT demo → email tương ứng trong Firebase Auth (hỗ trợ backward compatibility)
  static const Map<String, String> phoneToEmail = {
    '0900000002': 'quocbarber@gmail.com',
    '0987654321': 'nguyenvanan@gmail.com',
    '0900000000': 'mai.letan@barber.com',
  };

  /// Danh sách tài khoản demo được miễn kiểm tra xác thực email
  static const Set<String> demoEmails = {
    'quocbarber@gmail.com',
    'nguyenvanan@gmail.com',
    'mai.letan@barber.com',
  };

  bool isDemoAccount(String email) {
    return demoEmails.contains(email.toLowerCase().trim());
  }

  /// Đăng nhập bằng Gmail / Email hoặc SĐT demo
  Future<UserModel> login(String emailOrPhone, String password) async {
    final email = _emailForLogin(emailOrPhone);
    if (email == null || email.isEmpty) {
      throw Exception('Vui lòng nhập địa chỉ Gmail hoặc Email hợp lệ.');
    }

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fbUser = cred.user;
      if (fbUser == null) {
        throw Exception('Đăng nhập thất bại.');
      }

      // Tải lại user để cập nhật trạng thái emailVerified mới nhất từ Firebase
      await fbUser.reload();
      final refreshedUser = _auth.currentUser ?? fbUser;

      // Nếu là tài khoản thực tế (không phải demo) và chưa bấm link xác nhận mail
      if (!refreshedUser.emailVerified && !isDemoAccount(email)) {
        await _auth.signOut();
        throw EmailNotVerifiedException(
          email: email,
          message:
              'Tài khoản chưa được kích hoạt. Chúng tôi đã gửi email xác thực đến $email.\n\n'
              'Vui lòng kiểm tra hộp thư (bao gồm cả thư mục Spam/Thư rác) và nhấn vào liên kết xác nhận trước khi đăng nhập.',
        );
      }

      final user = await _loadOrCreateUser(
        uid: refreshedUser.uid,
        phone: emailOrPhone.contains('@') ? '' : emailOrPhone.trim(),
        email: email,
      );
      if (!user.isActive) {
        await _auth.signOut();
        throw Exception('Tài khoản đã bị khóa.');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_authMessage(e));
    }
  }

  /// Đăng ký tài khoản khách hàng mới và gửi mail xác nhận tài khoản
  Future<void> registerCustomer({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String gender = 'Nam',
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPhone = phone.trim();
    final cleanName = fullName.trim();

    try {
      // 1. Tạo tài khoản trên Firebase Authentication
      final cred = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      final user = cred.user;
      if (user == null) {
        throw Exception('Không thể tạo tài khoản trên hệ thống.');
      }

      // 2. Cập nhật họ tên hiển thị trong Firebase Auth
      try {
        await user.updateDisplayName(cleanName);
      } catch (_) {}

      // 3. Gửi email xác nhận tài khoản (Email Verification)
      await user.sendEmailVerification();

      // 4. Lưu hồ sơ khách hàng vào Firestore collection `users`
      final newUserData = {
        'id': DateTime.now().millisecondsSinceEpoch % 1000000,
        'uid': user.uid,
        'role': 'customer',
        'fullName': cleanName,
        'phone': cleanPhone,
        'email': cleanEmail,
        'gender': gender,
        'avatarUrl':
            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await _db.collection('users').doc(user.uid).set(newUserData);

      // 5. Đăng xuất ngay để người dùng phải bấm link xác nhận trong email trước khi đăng nhập
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw Exception(_registerAuthMessage(e));
    }
  }

  /// Gửi lại email xác nhận tài khoản cho người dùng
  Future<void> resendVerificationEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user;
      if (user != null) {
        await user.sendEmailVerification();
      }
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw Exception(_authMessage(e));
    }
  }

  /// Gửi email đặt lại mật khẩu
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_authMessage(e));
    }
  }

  /// 1) users/{uid}  2) document cũ theo email/SĐT  3) tự tạo profile demo.
  Future<UserModel> _loadOrCreateUser({
    required String uid,
    required String phone,
    required String email,
  }) async {
    final users = _db.collection('users');

    final byUid = await users.doc(uid).get();
    if (byUid.exists && byUid.data() != null) {
      final data = Map<String, dynamic>.from(byUid.data()!);
      bool shouldUpdate = false;
      if ((data['email'] == null || data['email'].toString().isEmpty) &&
          email.isNotEmpty) {
        data['email'] = email;
        shouldUpdate = true;
      }
      if (shouldUpdate) {
        await users.doc(uid).set(data, SetOptions(merge: true));
      }
      return UserModel.fromFirestore(uid, data);
    }

    QuerySnapshot<Map<String, dynamic>> found = await users
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (found.docs.isEmpty && phone.isNotEmpty) {
      found = await users.where('phone', isEqualTo: phone).limit(1).get();
    }

    if (found.docs.isNotEmpty) {
      final data = Map<String, dynamic>.from(found.docs.first.data());
      data['email'] = data['email'] ?? email;
      if (phone.isNotEmpty) {
        data['phone'] = data['phone'] ?? phone;
      }
      await users.doc(uid).set(data, SetOptions(merge: true));
      if (found.docs.first.id != uid) {
        await found.docs.first.reference.delete();
      }
      return UserModel.fromFirestore(uid, data);
    }

    final created = _demoProfile(phone: phone, email: email);
    await users.doc(uid).set(created);
    return UserModel.fromFirestore(uid, created);
  }

  Map<String, dynamic> _demoProfile({
    required String phone,
    required String email,
  }) {
    final normalizedEmail = email.toLowerCase().trim();
    if (normalizedEmail == 'quocbarber@gmail.com' || phone == '0900000002') {
      return {
        'id': 101,
        'role': 'staff',
        'fullName': 'Trần Văn Quốc (Quốc Barber)',
        'phone': phone.isNotEmpty ? phone : '0900000002',
        'email': 'quocbarber@gmail.com',
        'avatarUrl':
            'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=400',
        'gender': 'Nam',
        'isActive': true,
      };
    }
    if (normalizedEmail == 'mai.letan@barber.com' || phone == '0900000000') {
      return {
        'id': 201,
        'role': 'receptionist',
        'fullName': 'Lê Thị Mai (Lễ Tân)',
        'phone': phone.isNotEmpty ? phone : '0900000000',
        'email': 'mai.letan@barber.com',
        'avatarUrl':
            'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400',
        'gender': 'Nữ',
        'isActive': true,
      };
    }
    return {
      'id': 1,
      'role': 'customer',
      'fullName': 'Nguyễn Văn An',
      'phone': phone.isNotEmpty ? phone : '0987654321',
      'email': email.isNotEmpty ? email : 'nguyenvanan@gmail.com',
      'avatarUrl':
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400',
      'gender': 'Nam',
      'isActive': true,
    };
  }

  Future<void> logout() => _auth.signOut();

  String? _emailForLogin(String input) {
    final trimmed = input.trim();
    if (trimmed.contains('@')) return trimmed;
    return phoneToEmail[trimmed];
  }

  String _authMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'invalid-credential':
      case 'wrong-password':
        return 'Email hoặc mật khẩu không chính xác.';
      case 'invalid-email':
        return 'Địa chỉ email không đúng định dạng.';
      case 'user-disabled':
        return 'Tài khoản đã bị khóa.';
      case 'too-many-requests':
        return 'Thử đăng nhập quá nhiều lần, vui lòng đợi vài phút rồi thử lại.';
      case 'network-request-failed':
        return 'Không có mạng. Vui lòng kiểm tra Wi‑Fi / 4G.';
      default:
        return e.message ?? 'Đăng nhập Firebase thất bại (${e.code}).';
    }
  }

  String _registerAuthMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Địa chỉ Gmail / Email này đã được sử dụng. Vui lòng đăng nhập hoặc dùng email khác.';
      case 'invalid-email':
        return 'Địa chỉ email không hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu quá ngắn hoặc quá yếu (yêu cầu tối thiểu 6 ký tự).';
      case 'operation-not-allowed':
        return 'Tính năng đăng ký bằng email chưa được bật trên Firebase Console.';
      case 'network-request-failed':
        return 'Không có mạng. Vui lòng kiểm tra Wi‑Fi / 4G.';
      case 'too-many-requests':
        return 'Thao tác quá thường xuyên, vui lòng thử lại sau ít phút.';
      default:
        return e.message ?? 'Đăng ký thất bại (${e.code}).';
    }
  }
}
