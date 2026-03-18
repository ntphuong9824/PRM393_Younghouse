import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import 'admin/admin_dashboard_screen.dart';
import 'main_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _usePhoneLogin = false;
  bool _isOtpSent = false;
  String? _verificationId;
  int? _resendToken;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _routeByRole(User user) async {
    final profile = await _authService.getOrCreateUserProfile(user);
    final role = (profile['role'] as String?) ?? 'tenant';
    final fullName = (profile['full_name'] as String?)?.trim();

    if (!mounted) return;

    if (role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminDashboardScreen(landlordId: user.uid),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainScreen(
            userId: user.uid,
            userName: (fullName == null || fullName.isEmpty)
                ? (user.email ?? user.phoneNumber ?? 'Nguoi dung')
                : fullName,
          ),
        ),
      );
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui long nhap email va mat khau')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final UserCredential credential;
      if (email == AuthService.defaultAdminEmail) {
        credential = await _authService.signInOrBootstrapDefaultAdmin(
          email: email,
          password: password,
        );
      } else {
        credential = await _authService.signInWithEmailPassword(
          email: email,
          password: password,
        );
      }

      final user = credential.user;
      if (user == null) throw FirebaseAuthException(code: 'user-not-found');
      await _routeByRole(user);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mapAuthError(e))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dang nhap that bai: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui long nhap so dien thoai')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final request = await _authService.requestPhoneOtp(
        phone: phone,
        forceResendingToken: _resendToken,
      );
      if (!mounted) return;
      setState(() {
        _verificationId = request.verificationId;
        _resendToken = request.resendToken;
        _isOtpSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Da gui ma OTP')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mapPhoneAuthError(e))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gui OTP that bai: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtpAndLogin() async {
    final otp = _otpController.text.trim();
    if ((_verificationId ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui long gui ma OTP truoc')),
      );
      return;
    }
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ma OTP khong hop le')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential = await _authService.signInWithPhoneOtp(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      final user = credential.user;
      if (user == null) throw FirebaseAuthException(code: 'user-not-found');
      await _routeByRole(user);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mapPhoneAuthError(e))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dang nhap bang OTP that bai: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapPhoneAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'So dien thoai khong hop le';
      case 'invalid-verification-code':
        return 'Ma OTP khong dung';
      case 'session-expired':
        return 'OTP het han, vui long gui lai';
      case 'too-many-requests':
        return 'Ban thao tac qua nhieu, thu lai sau';
      case 'operation-not-allowed':
        return 'Phone Auth chua duoc bat trong Firebase';
      default:
        return e.message ?? 'Dang nhap bang so dien thoai that bai';
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Email khong hop le';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Thong tin dang nhap khong dung';
      case 'too-many-requests':
        return 'Thu lai sau it phut';
      case 'operation-not-allowed':
        return 'Email/Password chua duoc bat trong Firebase Auth';
      default:
        return e.message ?? 'Dang nhap that bai';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with Logo and Brand
            Container(
              height: 300,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(80),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/yhLogo.png',
                    height: 100,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.home_work,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "ĐĂNG NHẬP",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _usePhoneLogin = false;
                                    _isOtpSent = false;
                                    _otpController.clear();
                                  });
                                },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _usePhoneLogin
                                ? Colors.white
                                : AppColors.primary.withValues(alpha: 0.08),
                            side: BorderSide(
                              color: _usePhoneLogin
                                  ? Colors.grey.shade300
                                  : AppColors.primary,
                            ),
                          ),
                          child: const Text('Email'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _usePhoneLogin = true;
                                  });
                                },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _usePhoneLogin
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : Colors.white,
                            side: BorderSide(
                              color: _usePhoneLogin
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: const Text('So dien thoai'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (!_usePhoneLogin) ...[
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email",
                        hintText: "Admin: admin@younghouse.app",
                        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Mật khẩu",
                        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "ĐĂNG NHẬP",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ] else ...[
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'So dien thoai',
                        hintText: 'VD: 0912345678 hoac +84912345678',
                        prefixIcon: const Icon(Icons.phone_android, color: AppColors.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isOtpSent) ...[
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Ma OTP',
                          prefixIcon: const Icon(Icons.sms_outlined, color: AppColors.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : (_isOtpSent ? _verifyOtpAndLogin : _sendOtp),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isOtpSent ? 'XAC THUC OTP' : 'GUI MA OTP',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    if (_isOtpSent)
                      TextButton(
                        onPressed: _isLoading ? null : _sendOtp,
                        child: const Text('Gui lai ma OTP'),
                      ),
                  ],
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                    child: const Text('Chua co tai khoan? Dang ky'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
