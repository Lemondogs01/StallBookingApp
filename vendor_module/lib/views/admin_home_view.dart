import 'package:flutter/material.dart';
import 'package:mfu_market/model/user_model.dart';
import 'package:mfu_market/theme.dart';
import 'package:mfu_market/views/login_view.dart';

class AdminHomeView extends StatelessWidget {
  final UserModel user;

  const AdminHomeView({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello ${user.username}',
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Admin screens are built in the Admin module.',
                style: TextStyle(color: AppColors.textMuted)),
            const Spacer(),
            ElevatedButton(
              style: primaryButtonStyle(),
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginView()),
                (route) => false,
              ),
              child: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }
}
