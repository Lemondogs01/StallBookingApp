import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _shopController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await context.read<AuthController>().register(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      shopName: _shopController.text.trim(),
      realName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );
    if (success && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            tooltip: 'Back to sign in',
                            icon: const Icon(Icons.arrow_back),
                          ),
                        ),
                        const Text(
                          'Create your vendor account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _field(_shopController, 'Shop name', Icons.storefront),
                        _field(
                          _nameController,
                          'Full name',
                          Icons.badge_outlined,
                        ),
                        _field(
                          _phoneController,
                          'Phone number',
                          Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        _field(
                          _usernameController,
                          'Username',
                          Icons.person_outline,
                        ),
                        _field(
                          _passwordController,
                          'Password',
                          Icons.lock_outline,
                          obscureText: true,
                          helperText: 'Use 8 to 128 characters.',
                        ),
                        if (auth.errorMessage != null) ...[
                          const SizedBox(height: 10),
                          ErrorBanner(auth.errorMessage!),
                        ],
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: auth.isLoading ? null : _register,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            backgroundColor: AppTheme.green,
                          ),
                          child: auth.isLoading
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Create account'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    bool obscureText = false,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLength: identical(controller, _passwordController) ? 128 : null,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          prefixIcon: Icon(icon),
        ),
        validator: (value) {
          final input = value?.trim() ?? '';
          if (input.isEmpty) return 'Enter your $label.';
          if (identical(controller, _passwordController) &&
              (value?.length ?? 0) < 8) {
            return 'Use at least 8 characters.';
          }
          if (identical(controller, _usernameController) && input.length > 50) {
            return 'Usernames can contain up to 50 characters.';
          }
          if (identical(controller, _phoneController)) {
            final digits = input.replaceAll(RegExp(r'\D'), '');
            if (digits.length < 8 || digits.length > 15) {
              return 'Enter a phone number with 8 to 15 digits.';
            }
          }
          if ((identical(controller, _shopController) ||
                  identical(controller, _nameController)) &&
              input.length > 100) {
            return 'Use no more than 100 characters.';
          }
          return null;
        },
      ),
    );
  }
}
