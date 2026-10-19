class UserModel {
  final int id;
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

  UserModel copyWith({
    int? id,
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
