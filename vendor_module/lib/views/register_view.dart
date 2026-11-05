import 'package:flutter/material.dart';
import 'package:mfu_market/controller/auth_controller.dart';
import 'package:mfu_market/theme.dart';
import 'package:mfu_market/utils.dart';
import 'package:mfu_market/views/vendor_home_view.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final authController = AuthController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  String? errorMessage;
  bool loading = false;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  String? usernameError() {
    final v = usernameController.text.trim();
    if (v.isEmpty) return null;
    if (v.length < 3) return 'Username needs at least 3 characters';
    if (v.contains(' ')) return 'No spaces allowed';
    return null;
  }

  String? passwordError() {
    final v = passwordController.text;
    if (v.isEmpty) return null;
    if (v.length < 6) return 'Password needs at least 6 characters';
    return null;
  }

  String? confirmError() {
    final v = confirmController.text;
    if (v.isEmpty) return null;
    if (v != passwordController.text) return 'Passwords do not match';
    return null;
  }

  String? validate() {
    final username = usernameController.text.trim();
    if (username.length < 3) return 'Username needs at least 3 characters.';
    if (username.contains(' ')) return 'Username cannot contain spaces.';
    if (passwordController.text.length < 6) {
      return 'Password needs at least 6 characters.';
    }
    if (passwordController.text != confirmController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  Future<void> register() async {
    final problem = validate();
    if (problem != null) {
      setState(() => errorMessage = problem);
      return;
    }
    setState(() {
      loading = true;
      errorMessage = null;
    });
    try {
      final user = await authController.register(
        usernameController.text,
        passwordController.text,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => VendorHomeView(user: user)),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = cleanError(e);
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('‹ Log in',
                          style: TextStyle(
                              fontSize: 18, color: AppColors.primary)),
                    ),
                    const SizedBox(height: 24),
                    const Text('Create account',
                        style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary)),
                    const SizedBox(height: 10),
                    const Text(
                        'Register as a vendor to book campus market stalls',
                        style: TextStyle(
                            fontSize: 18, color: AppColors.textMuted)),
                    const SizedBox(height: 32),
                    const Text('Username', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: usernameController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        helperText: 'At least 3 characters, no spaces',
                        errorText: usernameError(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Password', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        helperText: 'At least 6 characters',
                        errorText: passwordError(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Confirm password',
                        style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: confirmController,
                      obscureText: true,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => register(),
                      decoration: InputDecoration(
                        helperText: 'Type the same password again',
                        errorText: confirmError(),
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      style: primaryButtonStyle(),
                      onPressed: loading ? null : register,
                      child: loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            )
                          : const Text('Create account'),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Center(
                        child: Text(errorMessage!,
                            style: const TextStyle(color: AppColors.danger)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Container(height: 8, color: AppColors.primary),
        ],
      ),
    );
  }
}
