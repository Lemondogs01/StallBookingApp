import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/admin_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'admin_dashboard_screen.dart';
import 'user_management_screen.dart';

class AdminNavigationShell extends StatefulWidget {
  const AdminNavigationShell({super.key});

  @override
  State<AdminNavigationShell> createState() => _AdminNavigationShellState();
}

class _AdminNavigationShellState extends State<AdminNavigationShell> {
  int _selectedIndex = 0;

  Future<void> _chooseDate(DateTime initialDate) async {
    final today = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: today.add(const Duration(days: 365)),
    );
    if (date != null && mounted) {
      await context.read<AdminController>().setDate(date);
    }
  }

  Widget _destination({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final selected = _selectedIndex == index;
    final color = selected ? AppTheme.green : const Color(0xFF94A3A0);
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        child: SizedBox(
          height: 62,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 21, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminController>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.green,
        foregroundColor: Colors.white,
        toolbarHeight: 66,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: Color(0xFFB7F3D8),
                ),
                SizedBox(width: 4),
                Text(
                  'MFU CAMPUS MARKET',
                  style: TextStyle(
                    color: Color(0xFFD8F5E8),
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              _selectedIndex == 0
                  ? 'Admin Analytics & Dashboard'
                  : 'Manage Users',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          Container(
            alignment: Alignment.center,
            margin: const EdgeInsets.only(right: 2),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0x660F172A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'ADMIN',
              style: TextStyle(
                color: Color(0xFFD8F5E8),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => context.read<AuthController>().logout(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            height: 44,
            color: const Color(0xFF1E293B),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month,
                  size: 16,
                  color: Color(0xFF34D399),
                ),
                const SizedBox(width: 7),
                const Expanded(
                  child: Text(
                    'Select date to view',
                    style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 11),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _chooseDate(admin.selectedDate),
                  icon: const Icon(Icons.edit_calendar_outlined, size: 15),
                  label: Text(ApiService.formatApiDate(admin.selectedDate)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF334155),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [AdminDashboardScreen(), UserManagementScreen()],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8E5))),
          ),
          child: Row(
            children: [
              _destination(index: 0, icon: Icons.bar_chart, label: 'Dashboard'),
              _destination(
                index: 1,
                icon: Icons.manage_accounts_outlined,
                label: 'Manage Users',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
