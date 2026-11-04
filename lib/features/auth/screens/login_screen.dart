import 'package:flutter/material.dart';

import 'package:barber_booking_app/features/auth/screens/register_screen.dart';
import 'package:barber_booking_app/features/barber/screens/staff_dashboard_screen.dart';
import 'package:barber_booking_app/features/customer/screens/main_navigation_screen.dart';
import 'package:barber_booking_app/features/receptionist/screens/receptionist_dashboard_screen.dart';
import 'package:barber_booking_app/shared/models/user_model.dart';
import 'package:barber_booking_app/shared/services/auth_session.dart';
import 'package:barber_booking_app/shared/services/firebase_auth_service.dart';
import 'package:barber_booking_app/shared/services/firebase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseService _dataService = FirebaseService();
  final AuthSession _session = AuthSession();
  final FirebaseAuthService _firebaseAuth = FirebaseAuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
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

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => targetScreen),
      (route) => false,
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ Email / Gmail và Mật khẩu!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final user = await _firebaseAuth.login(email, password);
      _session.setUser(user);
      _dataService.currentUser = user;
      await _dataService.start();
      if (!mounted) return;
      _navigateToRoleScreen(user);
    } on EmailNotVerifiedException catch (e) {
      if (!mounted) return;
      _showEmailNotVerifiedDialog(e.email, password);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showEmailNotVerifiedDialog(String email, String password) {
    showDialog(
      context: context,
      builder: (ctx) {
        bool isResending = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
              ),
              title: Row(
                children: const [
                  Icon(
                    Icons.mark_email_unread_rounded,
                    color: Color(0xFFD4AF37),
                    size: 28,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Chưa Xác Thực Email',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tài khoản với địa chỉ $email chưa được kích hoạt qua liên kết email.',
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Vui lòng mở Gmail (cả hộp thư đến lẫn thư mục Thư rác / Spam) và bấm vào liên kết để kích hoạt tài khoản.',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Nếu bạn chưa nhận được thư hoặc liên kết đã hết hạn, bấm nút bên dưới để gửi lại.',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isResending
                      ? null
                      : () async {
                          setDialogState(() => isResending = true);
                          try {
                            await _firebaseAuth.resendVerificationEmail(
                              email,
                              password,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Đã gửi lại email xác nhận đến $email. Vui lòng kiểm tra hộp thư!',
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (err) {
                            setDialogState(() => isResending = false);
                            if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    err.toString().replaceFirst(
                                      'Exception: ',
                                      '',
                                    ),
                                  ),
                                  backgroundColor: Colors.redAccent,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                  child: isResending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('GỬI LẠI EMAIL'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    showDialog(
      context: context,
      builder: (ctx) {
        bool isSending = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Quên Mật Khẩu',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nhập Gmail của bạn để nhận liên kết đặt lại mật khẩu:',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'vidu@gmail.com',
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Hủy',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final em = resetEmailController.text.trim();
                          if (em.isEmpty || !em.contains('@')) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('Vui lòng nhập email hợp lệ'),
                              ),
                            );
                            return;
                          }
                          setDialogState(() => isSending = true);
                          try {
                            await _firebaseAuth.sendPasswordReset(em);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Đã gửi liên kết đặt lại mật khẩu tới $em.',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSending = false);
                            if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e.toString().replaceFirst(
                                      'Exception: ',
                                      '',
                                    ),
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                  child: isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('GỬI YÊU CẦU'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openRegisterScreen() async {
    final registeredEmail = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
    if (registeredEmail != null && registeredEmail.isNotEmpty) {
      setState(() {
        _emailController.text = registeredEmail;
        _passwordController.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã tạo tài khoản cho $registeredEmail. Vui lòng kiểm tra Gmail xác nhận rồi đăng nhập.',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
              const SizedBox(height: 20),
              // Logo / Brand Icon
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD4AF37),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.content_cut_rounded,
                        color: Color(0xFFD4AF37),
                        size: 50,
                      ),
                    ),
                    const SizedBox(height: 14),
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
                      'Đăng nhập bằng Gmail / Email hệ thống',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Email / Gmail Field
              const Text(
                'Gmail / Email',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Nhập địa chỉ Gmail hoặc Email',
                  prefixIcon: Icon(Icons.email_outlined, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 18),

              // Password Field
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mật Khẩu',
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: _showForgotPasswordDialog,
                    child: const Text(
                      'Quên mật khẩu?',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nhập mật khẩu',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Colors.grey,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
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
              const SizedBox(height: 24),

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
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'ĐĂNG NHẬP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Registration Prompt
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Chưa có tài khoản? ',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: _openRegisterScreen,
                    child: const Text(
                      'Đăng ký ngay',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFFD4AF37),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
