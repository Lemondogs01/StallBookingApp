import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../config/theme/app_theme.dart';
import 'register_view.dart';
import '../vendor/vendor_dashboard_view.dart';
import '../admin/admin_dashboard_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอก Username และ Password')),
      );
      return;
    }

    final authController = Provider.of<AuthController>(context, listen: false);
    final success = await authController.login(username, password);

    if (!mounted) return;

    if (success) {
      final user = authController.user;

      // เช็คสิทธิ์และแยกหน้าตาม role
      if (user?.role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminDashboardView(),
          ), // นำทางไป Admin Dashboard
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const VendorDashboardView(),
          ), // นำทางไป Vendor View
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เข้าสู่ระบบไม่สำเร็จ กรุณาตรวจสอบข้อมูล'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: Stack(
        children: [
          // Background Circles
          Positioned(
            top: 150,
            left: -50,
            child: CircleAvatar(
              radius: 65,
              backgroundColor: AppTheme.darkGreen,
            ),
          ),
          Positioned(
            top: -20,
            right: -60,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: AppTheme.darkGreen,
            ),
          ),
          Positioned(
            bottom: -160,
            left: -30,
            right: -30,
            child: CircleAvatar(
              radius: 260,
              backgroundColor: AppTheme.darkGreen,
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 1. Logo Circle (โลโก้ วงกลมสีเขียวเข้ม)
                    Container(
                      width: 230,
                      height: 230,
                      decoration: BoxDecoration(
                        color: AppTheme.darkGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.storefront_outlined,
                            size: 80,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'MFUgrowtogether',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 2. Form Container (กล่องสีเขียวอ่อนใส่ Input)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGreen,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Column(
                        children: [
                          // Username / Email Field
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: TextField(
                              controller: _usernameController,
                              style: TextStyle(
                                color: AppTheme.darkGreen,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                hintText: 'username or email',
                                hintStyle: TextStyle(
                                  color: AppTheme.darkGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                                border: InputBorder.none,
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppTheme.darkGreen,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppTheme.darkGreen,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Password Field
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: TextField(
                              controller: _passwordController,
                              obscureText: true,
                              style: TextStyle(
                                color: AppTheme.darkGreen,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                hintText: 'password',
                                hintStyle: TextStyle(
                                  color: AppTheme.darkGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                                border: InputBorder.none,
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppTheme.darkGreen,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppTheme.darkGreen,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),

                    // 3. Login Button
                    SizedBox(
                      width: 180,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: authController.isLoading
                            ? null
                            : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.lightGreen,
                          elevation: 6,
                          shadowColor: Colors.black38,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: authController.isLoading
                            ? CircularProgressIndicator(
                                color: AppTheme.darkGreen,
                              )
                            : Text(
                                'Login',
                                style: TextStyle(
                                  color: AppTheme.darkGreen,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // "or" Divider
                    const Text(
                      'or',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Sign Up Link
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterView(),
                          ),
                        );
                      },
                      child: const Text(
                        "don't u have a account yet?",
                        style: TextStyle(
                          color: Colors.white,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
