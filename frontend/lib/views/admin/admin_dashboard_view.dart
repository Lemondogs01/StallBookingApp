import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/admin_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../config/theme/app_theme.dart';
import 'admin_add_event_view.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataForCurrentTab(_currentIndex);
    });
  }

  // แยกการโหลดข้อมูลตามแท็บ เพื่อไม่ให้ API ยิงรัวๆ ตอนสลับหน้า
  Future<void> _loadDataForCurrentTab(int index) async {
    if (!mounted) return;
    final authCtrl = Provider.of<AuthController>(context, listen: false);
    final adminCtrl = Provider.of<AdminController>(context, listen: false);

    if (authCtrl.token == null) await authCtrl.loadTokenFromStorage();
    final token = authCtrl.token;

    if (index == 0 && token != null) {
      await adminCtrl.fetchAnalytics(token);
    } else if (index == 1) {
      await adminCtrl.fetchEvents();
    } else if (index == 2 && token != null) {
      await adminCtrl.fetchBookingRequests(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.darkGreen,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Provider.of<AuthController>(context, listen: false).logout();
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildAnalyticsTab(),
          _buildEventsTab(),
          _buildRequestsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _loadDataForCurrentTab(index);
        },
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.darkGreen,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_outlined),
            activeIcon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Requests',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminAddEventView(),
                  ),
                );
                if (result == true && mounted) {
                  Provider.of<AdminController>(
                    context,
                    listen: false,
                  ).fetchEvents();
                }
              },
              backgroundColor: AppTheme.darkGreen,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Event',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  // ================= 1. หน้า Analytics =================
  Widget _buildAnalyticsTab() {
    return Consumer<AdminController>(
      builder: (context, adminCtrl, child) {
        if (adminCtrl.isLoading && adminCtrl.analyticsData.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = adminCtrl.analyticsData;
        final totalRevenue = data['totalRevenue'] ?? 0;
        final totalBookings = data['totalBookings'] ?? 0;
        final totalEvents = data['totalEvents'] ?? 0;
        final activeVendors = data['activeVendors'] ?? 0;
        final pendingRequests = data['pendingRequests'] ?? 0;

        return RefreshIndicator(
          onRefresh: () async {
            final token = Provider.of<AuthController>(
              context,
              listen: false,
            ).token;
            if (token != null) await adminCtrl.fetchAnalytics(token);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.darkGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good ${_greeting()}, Admin',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Dashboard overview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Here is what is happening with your marketplace.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Key metrics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B4332),
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.25,
                  children: [
                    _buildStatCard(
                      title: 'Total Revenue',
                      value: '฿${_formatNumber(totalRevenue)}',
                      icon: Icons.account_balance_wallet,
                      iconColor: Colors.orange,
                    ),
                    _buildStatCard(
                      title: 'Total Bookings',
                      value: _formatNumber(totalBookings),
                      icon: Icons.store,
                      iconColor: Colors.blue,
                    ),
                    _buildStatCard(
                      title: 'Total Events',
                      value: _formatNumber(totalEvents),
                      icon: Icons.event,
                      iconColor: Colors.teal,
                    ),
                    _buildStatCard(
                      title: 'Active Vendors',
                      value: _formatNumber(activeVendors),
                      icon: Icons.people,
                      iconColor: Colors.purple,
                    ),
                    _buildStatCard(
                      title: 'Pending Req.',
                      value: _formatNumber(pendingRequests),
                      icon: Icons.assignment_late,
                      iconColor: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  String _formatNumber(dynamic value) {
    final number = num.tryParse(value.toString());
    if (number == null) return value.toString();
    if (number % 1 == 0) return number.toInt().toString();
    return number.toStringAsFixed(2);
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 2. หน้า Events Tab (มีปุ่มลบ) =================
  Widget _buildEventsTab() {
    return Consumer<AdminController>(
      builder: (context, adminCtrl, child) {
        if (adminCtrl.isLoading && adminCtrl.events.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (adminCtrl.events.isEmpty) {
          return const Center(child: Text('ยังไม่มีรายการ Event'));
        }

        return RefreshIndicator(
          onRefresh: () async => adminCtrl.fetchEvents(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: adminCtrl.events.length,
            itemBuilder: (context, index) {
              final event = adminCtrl.events[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child:
                        event['image_url'] != null &&
                            event['image_url'].toString().isNotEmpty
                        ? Image.network(
                            event['image_url'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.event,
                              color: AppTheme.darkGreen,
                              size: 40,
                            ),
                          )
                        : Icon(
                            Icons.event,
                            color: AppTheme.darkGreen,
                            size: 40,
                          ),
                  ),
                  title: Text(
                    event['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${event['location'] ?? ''} · ${event['stalls_left'] ?? 0} stalls left\n฿${event['price']}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _confirmDeleteEvent(
                      context,
                      event,
                    ), // เรียก Popup ยืนยันการลบ
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ================= 3. หน้า Requests Tab (มีปุ่มอนุมัติ/ปฏิเสธ) =================
  Widget _buildRequestsTab() {
    return Consumer<AdminController>(
      builder: (context, adminCtrl, child) {
        if (adminCtrl.isLoading && adminCtrl.bookingRequests.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (adminCtrl.bookingRequests.isEmpty) {
          return const Center(child: Text('ไม่มีคำขอจองในขณะนี้'));
        }

        return RefreshIndicator(
          onRefresh: () async {
            final token = Provider.of<AuthController>(
              context,
              listen: false,
            ).token;
            if (token != null) adminCtrl.fetchBookingRequests(token);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: adminCtrl.bookingRequests.length,
            itemBuilder: (context, index) {
              final req = adminCtrl.bookingRequests[index];
              final status = (req['status'] ?? 'pending')
                  .toString()
                  .toLowerCase();
              final bookingId = req['id'];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${req['vendor_name'] ?? 'Vendor'} (${req['event_name'] ?? 'Event'})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: status == 'approved'
                                  ? Colors.green.shade100
                                  : status == 'rejected'
                                  ? Colors.red.shade100
                                  : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: status == 'approved'
                                    ? Colors.green.shade800
                                    : status == 'rejected'
                                    ? Colors.red.shade800
                                    : Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Stall: ${req['stall_code'] ?? '-'} (${req['stall_zone'] ?? '-'})',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),

                      // ✅ แสดงปุ่ม Approve / Reject เฉพาะตอนที่สถานะเป็น pending
                      if (status == 'pending') ...[
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () =>
                                  _updateStatus(context, bookingId, 'rejected'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                              child: const Text('Reject'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () =>
                                  _updateStatus(context, bookingId, 'approved'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.darkGreen,
                              ),
                              child: const Text(
                                'Approve',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ================= Helper Functions =================

  // ฟังก์ชันแสดง Dialog ยืนยันก่อนลบ Event
  // ฟังก์ชันแสดง Dialog ยืนยันก่อนลบ Event
  void _confirmDeleteEvent(BuildContext context, dynamic event) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('คุณต้องการลบอีเวนต์ "${event['name']}" ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogCtx); // ปิด Dialog ก่อน

              final authCtrl = Provider.of<AuthController>(
                context,
                listen: false,
              );
              final adminCtrl = Provider.of<AdminController>(
                context,
                listen: false,
              );

              // 🟢 1. โหลด Token ให้แน่ใจว่าไม่เป็น null
              await authCtrl.loadTokenFromStorage();
              final token = authCtrl.token;

              if (token != null) {
                final success = await adminCtrl.deleteEvent(token, event['id']);

                // 🟢 2. ตรวจสอบ mounted ป้องกัน Context หลุด
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'ลบอีเวนต์สำเร็จ'
                          : 'เกิดข้อผิดพลาดในการลบ (เช็ค Backend/Token)',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              } else {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ไม่พบ Token กรุณาเข้าสู่ระบบใหม่'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ฟังก์ชันอัปเดตสถานะการจอง (Approve/Reject)
  Future<void> _updateStatus(
    BuildContext context,
    dynamic bookingId,
    String status,
  ) async {
    final authCtrl = Provider.of<AuthController>(context, listen: false);
    final adminCtrl = Provider.of<AdminController>(context, listen: false);

    // 🟢 1. โหลด Token ให้แน่ใจว่าไม่เป็น null
    await authCtrl.loadTokenFromStorage();
    final token = authCtrl.token;

    if (token != null) {
      final success = await adminCtrl.updateRequestStatus(
        token,
        bookingId,
        status,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'อัปเดตสถานะเป็น $status สำเร็จ'
                : 'เกิดข้อผิดพลาดในการอัปเดต (Status: 400/500)',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่พบ Token กรุณาเข้าสู่ระบบใหม่'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
