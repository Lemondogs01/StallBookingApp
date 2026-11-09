import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_navigation_shell.dart';
import '../vendor/vendor_navigation_shell.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (!auth.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.green)),
      );
    }
    if (auth.user == null) return const LoginScreen();
    return auth.user!.isAdmin
        ? const AdminNavigationShell()
        : const VendorNavigationShell();
  }
}
