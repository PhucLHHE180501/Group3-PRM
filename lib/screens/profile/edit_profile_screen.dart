import 'package:flutter/material.dart';
import '../../services/mock_data_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final MockDataService _dataService = MockDataService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _avatarUrlController;

  @override
  void initState() {
    super.initState();
    final user = _dataService.currentUser;
    if (user != null) {
      final u = user!;
      _nameController = TextEditingController(text: u.fullName);
      _phoneController = TextEditingController(text: u.phone);
      _emailController = TextEditingController(text: u.email ?? '');
      _addressController = TextEditingController(text: u.address ?? '');
      _avatarUrlController = TextEditingController(text: u.avatarUrl ?? '');
    } else {
      _nameController = TextEditingController();
      _phoneController = TextEditingController();
      _emailController = TextEditingController();
      _addressController = TextEditingController();
      _avatarUrlController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      _dataService.updateUserProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        avatarUrl: _avatarUrlController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật hồ sơ thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh Sửa Hồ Sơ'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hình Ảnh Đại Diện (URL)',
                style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _avatarUrlController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.image_outlined, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Họ và Tên (*)',
                style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline, color: Colors.grey),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập họ và tên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              const Text(
                'Số Điện Thoại (*)',
                style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.phone_android_outlined, color: Colors.grey),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập số điện thoại';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              const Text(
                'Email',
                style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.email_outlined, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Địa Chỉ',
                style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.location_on_outlined, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text('Lưu Thay Đổi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
