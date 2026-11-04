import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import 'login_view.dart';

class AdminHomeView extends StatelessWidget {
  const AdminHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginView()),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const ListTile(
              leading: Icon(
                Icons.admin_panel_settings,
                size: 48,
                color: Colors.redAccent,
              ),
              title: Text(
                'จัดการระบบ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              subtitle: Text('MFU Campus Market (Admin Only)'),
            ),
            const Divider(height: 32, thickness: 1.5),
            _buildAdminMenu(
              icon: Icons.event_note,
              title: 'จัดการงานกิจกรรม (Events)',
              color: Colors.teal,
              onTap: () {
                // TODO: นำทางไปหน้าสร้าง/ลบ Event
              },
            ),
            const SizedBox(height: 12),
            _buildAdminMenu(
              icon: Icons.verified_user,
              title: 'ตรวจสอบสลิปการโอนเงิน',
              color: Colors.orange,
              onTap: () {
                // TODO: นำทางไปหน้า Admin ตรวจสลิป
              },
            ),
            const SizedBox(height: 12),
            _buildAdminMenu(
              icon: Icons.store,
              title: 'จัดการแผนผังแผงร้านค้า',
              color: Colors.blueAccent,
              onTap: () {
                // TODO: นำทางไปหน้าจัดการผังร้านค้า
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminMenu({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
