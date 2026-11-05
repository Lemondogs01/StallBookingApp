import 'package:flutter/material.dart';
import 'package:mfu_market/controller/auth_controller.dart';
import 'package:mfu_market/theme.dart';
import 'package:mfu_market/utils.dart';
import 'package:mfu_market/views/admin_home_view.dart';
import 'package:mfu_market/views/register_view.dart';
import 'package:mfu_market/views/vendor_home_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final authController = AuthController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  String? errorMessage;
  bool loading = false;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => errorMessage = 'Please enter username and password.');
      return;
    }
    setState(() {
      loading = true;
      errorMessage = null;
    });
    try {
      final user = await authController.login(username, password);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => user.role == 'admin'
              ? AdminHomeView(user: user)
              : VendorHomeView(user: user),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = cleanError(e);
        loading = false;
      });
    }
  }

  Widget blob(double size) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
            color: AppColors.primary, shape: BoxShape.circle),
      );

  InputDecoration underlineField(String hint) {
    const line = UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary, width: 1.2));
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 15, color: AppColors.textMuted),
      filled: false,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      border: line,
      enabledBorder: line,
      focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(top: -70, right: -60, child: blob(210)),
          Positioned(top: 300, right: -70, child: blob(130)),
          Positioned(
            left: -60,
            right: -60,
            bottom: -150,
            height: 330,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(200),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 40, 32, 150),
              child: Column(
                children: [
                  Container(
                    width: 136,
                    height: 136,
                    decoration: const BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.storefront_outlined,
                            size: 48, color: Colors.white),
                        SizedBox(height: 6),
                        Text('MFUgrowtogether',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: usernameController,
                          decoration: underlineField('username or email'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          onSubmitted: (_) => login(),
                          decoration: underlineField('password'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    style: softButtonStyle(),
                    onPressed: loading ? null : login,
                    child: loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Text('Login'),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Text(errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.danger)),
                  ],
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('or',
                        style: TextStyle(fontSize: 14, color: Colors.white70)),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterView()),
                      ),
                      child: const Text("don't have account yet?",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white)),
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
