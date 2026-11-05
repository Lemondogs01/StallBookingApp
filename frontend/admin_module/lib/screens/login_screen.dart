import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'admin/admin_shell.dart';

/// Mock login screen (Sprint 2). Sprint 3 connects it to the Authentication
/// controller (username/password -> JWT, role = admin).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _hide = true;
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _login() {
    if (_user.text.trim().isEmpty || _pass.text.isEmpty) {
      setState(() => _error = 'Enter your username and password');
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AdminShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned(top: -80, right: -70, child: _Blob(size: 200)),
          const Positioned(bottom: -110, left: -80, child: _Blob(size: 260)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 150,
                        height: 150,
                        decoration: const BoxDecoration(
                            color: AppColors.green, shape: BoxShape.circle),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.storefront_outlined,
                                size: 52, color: AppColors.cream),
                            SizedBox(height: 6),
                            Text('MFUgrowtogether',
                                style: TextStyle(
                                    color: AppColors.cream,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3E9DD),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Admin sign in',
                                style: text.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _user,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                hintText: 'username or email',
                                fillColor: AppColors.card,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _pass,
                              obscureText: _hide,
                              onSubmitted: (_) => _login(),
                              decoration: InputDecoration(
                                hintText: 'password',
                                fillColor: AppColors.card,
                                suffixIcon: IconButton(
                                  icon: Icon(_hide
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                  onPressed: () => setState(() => _hide = !_hide),
                                ),
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 10),
                              Text(_error!,
                                  style: text.bodySmall
                                      ?.copyWith(color: AppColors.danger)),
                            ],
                            const SizedBox(height: 18),
                            FilledButton(
                                onPressed: _login, child: const Text('Login')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Mock login: any username and password works',
                          style:
                              text.bodySmall?.copyWith(color: AppColors.muted)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration:
          const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
    );
  }
}
