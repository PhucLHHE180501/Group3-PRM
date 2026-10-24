import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// SĐT trên màn login → email đã tạo trong Firebase Auth.
  static const Map<String, String> phoneToEmail = {
    '0900000002': 'quocbarber@gmail.com',
    '0987654321': 'nguyenvanan@gmail.com',
    '0900000000': 'mai.letan@barber.com',
  };

  Future<UserModel> login(String phone, String password) async {
    final email = _emailForLogin(phone);
    if (email == null) {
      throw Exception(
        'Số điện thoại chưa được gán email Firebase. '
        'Dùng 0900000002, 0987654321 hoặc 0900000000.',
      );
    }

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user?.uid;
      if (uid == null) {
        throw Exception('Đăng nhập thất bại.');
      }

      final user = await _loadOrCreateUser(
        uid: uid,
        phone: phone.trim(),
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

  /// 1) users/{uid}  2) document cũ theo email/SĐT  3) tự tạo profile demo.
  Future<UserModel> _loadOrCreateUser({
    required String uid,
    required String phone,
    required String email,
  }) async {
    final users = _db.collection('users');

    final byUid = await users.doc(uid).get();
    if (byUid.exists && byUid.data() != null) {
      return UserModel.fromFirestore(uid, byUid.data()!);
    }

    QuerySnapshot<Map<String, dynamic>> found = await users
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (found.docs.isEmpty) {
      found = await users.where('phone', isEqualTo: phone).limit(1).get();
    }

    if (found.docs.isNotEmpty) {
      final data = Map<String, dynamic>.from(found.docs.first.data());
      data['email'] = data['email'] ?? email;
      data['phone'] = data['phone'] ?? phone;
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
    switch (phone) {
      case '0900000002':
        return {
          'id': 101,
          'role': 'staff',
          'fullName': 'Trần Văn Quốc (Quốc Barber)',
          'phone': phone,
          'email': email,
          'avatarUrl':
              'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=400',
          'gender': 'Nam',
          'isActive': true,
        };
      case '0900000000':
        return {
          'id': 201,
          'role': 'receptionist',
          'fullName': 'Lê Thị Mai (Lễ Tân)',
          'phone': phone,
          'email': email,
          'avatarUrl':
              'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400',
          'gender': 'Nữ',
          'isActive': true,
        };
      case '0987654321':
      default:
        return {
          'id': 1,
          'role': 'customer',
          'fullName': 'Nguyễn Văn An',
          'phone': phone,
          'email': email,
          'avatarUrl':
              'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400',
          'gender': 'Nam',
          'isActive': true,
        };
    }
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
      case 'invalid-email':
        return 'Email hoặc mật khẩu không đúng. Kiểm tra email trên Auth khớp bảng phoneToEmail.';
      case 'user-disabled':
        return 'Tài khoản đã bị khóa.';
      case 'too-many-requests':
        return 'Thử quá nhiều lần, đợi vài phút.';
      case 'network-request-failed':
        return 'Không có mạng. Kiểm tra Wi‑Fi / 4G.';
      default:
        return e.message ?? 'Đăng nhập Firebase thất bại (${e.code}).';
    }
  }
}
