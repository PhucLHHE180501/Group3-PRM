import 'package:flutter/material.dart';

import 'package:barber_booking_app/features/barber/screens/staff_dashboard_screen.dart';
import 'package:barber_booking_app/features/customer/screens/main_navigation_screen.dart';
import 'package:barber_booking_app/features/receptionist/screens/receptionist_dashboard_screen.dart';
import 'package:barber_booking_app/shared/models/user_model.dart';
import 'package:barber_booking_app/shared/services/api_service.dart';
import 'package:barber_booking_app/shared/services/auth_session.dart';
import 'package:barber_booking_app/shared/services/mock_data_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final MockDataService _dataService = MockDataService();
  final AuthSession _session = AuthSession();
  final ApiService _api = ApiService();
  final _phoneController = TextEditingController(text: '0900000002');
  final _passwordController = TextEditingController(text: '123456');
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToRoleScreen(UserModel user) {
    Widget targetScreen;
    switch (user.role) {
      case 'staff':
        targetScreen = const StaffDashboardScreen();
        break;
      case 'receptionist':
        targetScreen = const ReceptionistDashboardScreen();
        break;
      case 'customer':
      default:
        targetScreen = const MainNavigationScreen();
        break;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => targetScreen),
    );
  }

  Future<void> _handleLogin() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ Số điện thoại và Mật khẩu!')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final user = await _api.login(phone, password);
      _session.setUser(user);
      _dataService.currentUser = user;
      if (!mounted) return;
      _navigateToRoleScreen(user);
    } catch (e) {
      final user = _dataService.login(phone, password);
      if (!mounted) return;
      if (user != null) {
        _session.setUser(user);
        _navigateToRoleScreen(user);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleQuickRoleLogin(String role) async {
    if (role == 'staff') {
      _phoneController.text = '0900000002';
      _passwordController.text = '123456';
      await _handleLogin();
      return;
    }

    final user = _dataService.loginAsRole(role);
    _session.setUser(user);
    _navigateToRoleScreen(user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              // Logo / Brand Icon
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                      ),
                      child: const Icon(
                        Icons.content_cut_rounded,
                        color: Color(0xFFD4AF37),
                        size: 52,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'BARBER SHOP',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Đăng nhập theo quyền ứng dụng',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Phone Field
              const Text(
                'Số Điện Thoại',
                style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Nhập số điện thoại',
                  prefixIcon: Icon(Icons.phone_android, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),

              // Password Field
              const Text(
                'Mật Khẩu',
                style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nhập mật khẩu',
                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleLogin,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('ĐĂNG NHẬP'),
                ),
              ),
              const SizedBox(height: 40),

              // Quick Role Login Section
              Row(
                children: const [
                  Expanded(child: Divider(color: Colors.white24)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('ĐĂNG NHẬP NHANH THEO ROLE', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(child: Divider(color: Colors.white24)),
                ],
              ),
              const SizedBox(height: 16),

              // Role Buttons
              _buildRoleTile(
                icon: Icons.person,
                title: 'Khách Hàng (Customer)',
                subtitle: 'SĐT: 0987654321 • Pass: 123456',
                color: Colors.greenAccent,
                onTap: () => _handleQuickRoleLogin('customer'),
              ),
              const SizedBox(height: 10),
              _buildRoleTile(
                icon: Icons.content_cut,
                title: 'Thợ Cắt Tóc (Barber Staff)',
                    subtitle: 'SĐT: 0900000002 • Pass: 123456 (SQL Server)',
                color: const Color(0xFFD4AF37),
                onTap: () => _handleQuickRoleLogin('staff'),
              ),
              const SizedBox(height: 10),
              _buildRoleTile(
                icon: Icons.support_agent,
                title: 'Lễ Tân (Receptionist)',
                subtitle: 'SĐT: 0900000000 • Pass: 123456',
                color: Colors.blueAccent,
                onTap: () => _handleQuickRoleLogin('receptionist'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: color, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
