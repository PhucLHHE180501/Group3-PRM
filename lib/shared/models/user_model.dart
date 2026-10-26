class UserModel {
  final int id;
  final String uid;
  final String role; // 'customer', 'staff', 'receptionist'
  final String fullName;
  final String phone;
  final String? email;
  final String? avatarUrl;
  final String? gender;
  final String? dateOfBirth;
  final String? address;
  final bool isActive;

  UserModel({
    required this.id,
    this.uid = '',
    required this.role,
    required this.fullName,
    required this.phone,
    this.email,
    this.avatarUrl,
    this.gender,
    this.dateOfBirth,
    this.address,
    this.isActive = true,
  });

  /// Kiểm tra tài khoản đã đầy đủ Họ tên & Số điện thoại hay chưa
  bool get hasRequiredProfileInfo {
    return fullName.trim().isNotEmpty && phone.trim().isNotEmpty;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] as num).toInt(),
      uid: json['uid'] as String? ?? '',
      role: json['role'] as String,
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      gender: json['gender'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      address: json['address'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Document Firestore `users/{uid}` — không có field `id` số.
  /// Giữ id int cũ để màn mock/API chưa đổi sang String.
  factory UserModel.fromFirestore(String uid, Map<String, dynamic> json) {
    final role = json['role'] as String? ?? 'customer';
    return UserModel(
      id: (json['id'] as num?)?.toInt() ?? _legacyIdForRole(role),
      uid: uid,
      role: role,
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      gender: json['gender'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      address: json['address'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  static int _legacyIdForRole(String role) {
    switch (role) {
      case 'staff':
        return 101;
      case 'receptionist':
        return 201;
      case 'customer':
      default:
        return 1;
    }
  }

  UserModel copyWith({
    int? id,
    String? uid,
    String? role,
    String? fullName,
    String? phone,
    String? email,
    String? avatarUrl,
    String? gender,
    String? dateOfBirth,
    String? address,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
    );
  }
}
