import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:barber_booking_app/features/auth/screens/login_screen.dart';
import 'package:barber_booking_app/shared/models/user_model.dart';
import 'package:barber_booking_app/shared/services/firebase_service.dart';
import 'package:barber_booking_app/shared/widgets/app_network_image.dart';

class ReceptionistProfileScreen extends StatefulWidget {
  final VoidCallback? onBackToSchedule;

  const ReceptionistProfileScreen({
    super.key,
    this.onBackToSchedule,
  });

  @override
  State<ReceptionistProfileScreen> createState() => _ReceptionistProfileScreenState();
}

class _ReceptionistProfileScreenState extends State<ReceptionistProfileScreen> {
  final FirebaseService _dataService = FirebaseService();
  bool _isUploadingAvatar = false;

  static const Color _gold = Color(0xFFD4AF37);
  static const Color _cardBg = Color(0xFF1E1E1E);
  static const Color _cardBg2 = Color(0xFF252525);

  @override
  void initState() {
    super.initState();
    _dataService.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _dataService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
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
              content: Text('Cần cấp quyền truy cập Máy ảnh để chụp trực tiếp.'),
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
        backgroundColor: const Color(0xFF1E1E1E),
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

  void _showChangeAvatarDialog(UserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
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
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Chọn ảnh từ thư viện hoặc chụp ảnh mới',
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
                title: const Text('Chụp ảnh mới', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Sử dụng máy ảnh', style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadAvatar(user, ImageSource.camera);
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
                title: const Text('Chọn từ thư viện', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Tải ảnh từ bộ sưu tập', style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadAvatar(user, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(UserModel user, ImageSource source) async {
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

      setState(() => _isUploadingAvatar = true);

      final downloadUrl = await _dataService.uploadAvatar(user.id, pickedFile);

      await _dataService.updateUserProfile(
        fullName: user.fullName,
        phone: user.phone,
        email: user.email ?? 'mai.letan@barber.com',
        address: user.address,
        avatarUrl: downloadUrl,
      );

      if (!mounted) return;
      setState(() => _isUploadingAvatar = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật ảnh đại diện thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải ảnh đại diện: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showEditProfileBottomSheet(UserModel user) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: user.fullName);
    final phoneCtrl = TextEditingController(text: user.phone);
    final emailCtrl = TextEditingController(text: user.email ?? 'mai.letan@barber.com');
    final addressCtrl = TextEditingController(text: user.address ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.85,
                maxChildSize: 0.95,
                minChildSize: 0.5,
                expand: false,
                builder: (ctx, scrollController) {
                  return Column(
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
                                Icon(Icons.edit_note_rounded, color: _gold, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'Chỉnh Sửa Hồ Sơ Lễ Tân',
                                  style: TextStyle(
                                    color: Colors.white,
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
                                // Avatar in edit dialog
                                Center(
                                  child: Stack(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _gold,
                                        ),
                                        child: CircleAvatar(
                                          radius: 42,
                                          backgroundColor: _cardBg2,
                                          child: ClipOval(
                                            child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                                ? AppNetworkImage(
                                                    imageUrl: user.avatarUrl,
                                                    width: 84,
                                                    height: 84,
                                                    fit: BoxFit.cover,
                                                  )
                                                : const Icon(Icons.person, color: _gold, size: 40),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.pop(ctx);
                                            _showChangeAvatarDialog(user);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: _gold,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: _cardBg, width: 2),
                                            ),
                                            child: const Icon(
                                              Icons.camera_alt_rounded,
                                              color: Colors.black,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Center(
                                  child: TextButton.icon(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _showChangeAvatarDialog(user);
                                    },
                                    icon: const Icon(Icons.cloud_upload_rounded, color: _gold, size: 16),
                                    label: const Text(
                                      'Đổi ảnh đại diện',
                                      style: TextStyle(color: _gold, fontSize: 13),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                _buildInputField(
                                  label: 'Họ và Tên (*)',
                                  controller: nameCtrl,
                                  icon: Icons.person_outline_rounded,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Vui lòng nhập họ và tên';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),

                                _buildInputField(
                                  label: 'Số Điện Thoại (*)',
                                  controller: phoneCtrl,
                                  icon: Icons.phone_android_rounded,
                                  keyboardType: TextInputType.phone,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Vui lòng nhập số điện thoại';
                                    }
                                    final reg = RegExp(r'^0[3|5|7|8|9][0-9]{8}$');
                                    if (!reg.hasMatch(v.trim())) {
                                      return 'Số điện thoại 10 số không hợp lệ';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),

                                _buildInputField(
                                  label: 'Email (*)',
                                  controller: emailCtrl,
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Vui lòng nhập email';
                                    }
                                    if (!v.contains('@') || !v.contains('.')) {
                                      return 'Định dạng email không hợp lệ';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),

                                _buildInputField(
                                  label: 'Địa Chỉ Làm Việc',
                                  controller: addressCtrl,
                                  icon: Icons.location_on_outlined,
                                  maxLines: 2,
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
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: isSaving
                                        ? null
                                        : () async {
                                            if (!formKey.currentState!.validate()) return;
                                            setModalState(() => isSaving = true);

                                            try {
                                              await _dataService.updateUserProfile(
                                                fullName: nameCtrl.text.trim(),
                                                phone: phoneCtrl.text.trim(),
                                                email: emailCtrl.text.trim(),
                                                address: addressCtrl.text.trim(),
                                                avatarUrl: user.avatarUrl,
                                              );

                                              if (!ctx.mounted) return;
                                              Navigator.pop(ctx);

                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Cập nhật hồ sơ Lễ tân thành công!'),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            } catch (e) {
                                              setModalState(() => isSaving = false);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Lỗi cập nhật: $e'),
                                                  backgroundColor: Colors.redAccent,
                                                ),
                                              );
                                            }
                                          },
                                    child: isSaving
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                          )
                                        : const Text(
                                            'LƯU THAY ĐỔI',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
        prefixIcon: Icon(icon, color: _gold, size: 20),
        filled: true,
        fillColor: _cardBg2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _gold, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.redAccent, size: 22),
            SizedBox(width: 8),
            Text('Đăng Xuất', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi phiên làm việc Lễ tân?',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _dataService.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Đăng Xuất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _dataService.currentUser;
    final allBookings = _dataService.bookings;
    final barbers = _dataService.barbers;

    // Default receptionist user fallback
    final effectiveUser = user ??
        UserModel(
          id: 201,
          role: 'receptionist',
          fullName: 'Lê Thị Mai',
          phone: '0987654321',
          email: 'mai.letan@barber.com',
          address: 'Salon Chính - 123 Cầu Giấy, Hà Nội',
        );

    final String avatar = effectiveUser.avatarUrl ?? '';
    final String email = (effectiveUser.email != null && effectiveUser.email!.isNotEmpty)
        ? effectiveUser.email!
        : 'mai.letan@barber.com';

    // Daily quick stats for Receptionist
    final todayBookings = allBookings;
    final availableBarbersCount = barbers
        .where((b) => _dataService.getBarberDynamicStatus(b.userId) == 'available')
        .length;
    final completedBookingsCount = todayBookings.where((b) => b.status == 'completed').length;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Hồ Sơ Lễ Tân'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Đăng xuất',
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Avatar & Name Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isUploadingAvatar ? null : () => _showChangeAvatarDialog(effectiveUser),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: _gold,
                          child: CircleAvatar(
                            radius: 49,
                            backgroundColor: _cardBg2,
                            child: ClipOval(
                              child: avatar.isNotEmpty
                                  ? AppNetworkImage(
                                      imageUrl: avatar,
                                      width: 98,
                                      height: 98,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: _gold,
                                    ),
                            ),
                          ),
                        ),
                        if (_isUploadingAvatar)
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(color: _gold),
                              ),
                            ),
                          ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(
                              color: _gold,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    effectiveUser.fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _gold, width: 0.8),
                    ),
                    child: const Text(
                      'LỄ TÂN ĐIỀU PHỐI SALON',
                      style: TextStyle(
                        color: _gold,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Salon Stats Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.query_stats_rounded, color: _gold, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Tổng Quan Điều Phối',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          label: 'Tổng đơn',
                          value: '${todayBookings.length}',
                          color: _gold,
                          icon: Icons.receipt_long_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatItem(
                          label: 'Thợ sẵn sàng',
                          value: '$availableBarbersCount/${barbers.length}',
                          color: Colors.greenAccent,
                          icon: Icons.person_pin_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatItem(
                          label: 'Hoàn thành',
                          value: '$completedBookingsCount',
                          color: Colors.blueAccent,
                          icon: Icons.check_circle_outline_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Profile info cards
            _buildInfoCard(
              icon: Icons.badge_outlined,
              label: 'Họ và Tên',
              value: effectiveUser.fullName,
            ),
            const SizedBox(height: 10),
            _buildInfoCard(
              icon: Icons.phone_android_outlined,
              label: 'Số Điện Thoại',
              value: effectiveUser.phone,
            ),
            const SizedBox(height: 10),
            _buildInfoCard(
              icon: Icons.email_outlined,
              label: 'Email Làm Việc',
              value: email,
            ),
            const SizedBox(height: 10),
            _buildInfoCard(
              icon: Icons.location_on_outlined,
              label: 'Địa Chỉ Chi Nhánh',
              value: (effectiveUser.address != null && effectiveUser.address!.isNotEmpty)
                  ? effectiveUser.address!
                  : 'Salon Chính - 123 Cầu Giấy, Hà Nội',
            ),
            const SizedBox(height: 24),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.black,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text(
                  'CHỈNH SỬA HỒ SƠ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: () => _showEditProfileBottomSheet(effectiveUser),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text(
                  'ĐĂNG XUẤT',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: _confirmLogout,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: _cardBg2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _gold, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
