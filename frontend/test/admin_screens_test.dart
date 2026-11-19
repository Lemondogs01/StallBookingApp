import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_market_app/controllers/admin_controller.dart';
import 'package:mfu_market_app/services/api_service.dart';
import 'package:mfu_market_app/views/admin/admin_dashboard_screen.dart';
import 'package:mfu_market_app/views/admin/user_management_screen.dart';
import 'package:provider/provider.dart';

import 'controller_test_support.dart';

Map<String, dynamic> _sampleAnalytics() => {
  'totalRevenue': 1500,
  'selectedDateRevenue': 250,
  'categoryRevenue': {'food': 250, 'fashion': 0, 'general': 0},
  'dailyBreakdown': [
    {'date': '2099-01-01', 'revenue': 250},
  ],
  'monthlyBreakdown': [
    {'month': '2099-01-01', 'revenue': 1500},
  ],
};

void main() {
  // โหลดข้อมูลแดชบอร์ดจำลองแล้วตรวจว่าแสดงการ์ด Approved revenue, Pending revenue, หัวข้อ Pending Payment Slips, จำนวน 1 pending และชื่อร้าน Shop: Tea Stand
  // กดที่รายการร้านเพื่อเปิดหน้าต่าง Review Booking แล้วกดปุ่ม Approve เพื่อตรวจว่าส่งสถานะ 'approved' ไปยัง endpoint /verify
  testWidgets(
    'AdminDashboardScreen renders metrics, pending slips, and opens review dialog',
    (tester) async {
      final verifiedStatuses = <String>[];
      final api = testApi((request) async {
        if (request.url.path.endsWith('/admin/analytics')) {
          return testJsonResponse(_sampleAnalytics());
        }
        if (request.url.path.endsWith('/admin/bookings/pending')) {
          return testJsonResponse([
            {
              ...testBooking(id: 10),
              'shop_name': 'Tea Stand',
              'real_name': 'Vendor 8',
              'phone': '0800000000',
            },
          ]);
        }
        if (request.url.path.endsWith('/stalls/status')) {
          return testJsonResponse({
            'stalls': [testStall(status: 'pending')],
          });
        }
        if (request.url.path.endsWith('/verify')) {
          verifiedStatuses.add(jsonDecode(request.body)['status'] as String);
          return testJsonResponse({});
        }
        return testJsonResponse({});
      });
      addTearDown(api.close);

      final adminController = AdminController(api);
      addTearDown(adminController.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiService>.value(value: api),
            ChangeNotifierProvider<AdminController>.value(
              value: adminController,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AdminDashboardScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Approved revenue'), findsOneWidget);
      expect(find.text('Pending revenue'), findsOneWidget);
      expect(find.text('Pending Payment Slips'), findsOneWidget);
      expect(find.text('1 pending'), findsOneWidget);
      expect(find.text('Shop: Tea Stand'), findsOneWidget);

      // เปิด dialog รีวิวและกด Approve
      await tester.tap(find.text('Shop: Tea Stand'));
      await tester.pumpAndSettle();
      expect(find.text('Review Booking'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);

      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();
      expect(verifiedStatuses, ['approved']);
    },
  );
// โหลดรายชื่อผู้ใช้จำลองแล้วตรวจว่าแสดงชื่อร้าน Tea Stand และชื่อผู้ใช้ User: vendor8
// กดปุ่ม Reset password แล้วตรวจว่ามี dialog ยืนยัน Reset Password ขึ้นมา และเมื่อกดยืนยันแล้วมีการเรียก API รีเซ็ตรหัสผ่าน
  testWidgets(
    'UserManagementScreen displays users and opens reset password confirmation',
    (tester) async {
      var resetCalled = false;
      final api = testApi((request) async {
        if (request.url.path.endsWith('/admin/users')) {
          return testJsonResponse([testUser(id: 8)]);
        }
        if (request.url.path.endsWith('/admin/users/8/reset-password')) {
          resetCalled = true;
          return testJsonResponse({});
        }
        return testJsonResponse({});
      });
      addTearDown(api.close);

      final adminController = AdminController(api);
      addTearDown(adminController.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiService>.value(value: api),
            ChangeNotifierProvider<AdminController>.value(
              value: adminController,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: UserManagementScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Manage Users'), findsOneWidget);
      expect(find.text('Tea Stand'), findsOneWidget);
      expect(find.text('User: vendor8'), findsOneWidget);

      await tester.tap(find.text('Reset password'));
      await tester.pumpAndSettle();
      expect(find.text('Reset Password'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Reset Password'));
      await tester.pumpAndSettle();
      expect(resetCalled, isTrue);
    },
  );
}