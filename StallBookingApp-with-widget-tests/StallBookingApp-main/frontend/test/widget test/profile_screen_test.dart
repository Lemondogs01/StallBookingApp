import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_market_app/controllers/auth_controller.dart';
import 'package:mfu_market_app/controllers/profile_controller.dart';
import 'package:mfu_market_app/services/api_service.dart';
import 'package:mfu_market_app/views/vendor/profile_screen.dart';
import 'package:provider/provider.dart';

import '../controller_test_support.dart';

void main() {
  // โหลดข้อมูลโปรไฟล์แล้วตรวจว่าแสดงชื่อร้าน, ชื่อจริง, เบอร์โทร และ username ถูกต้อง
  // กด Edit เพื่อเข้าสู่โหมดแก้ไข ลองกรอกเบอร์โทรสั้นเกินไป (12345) แล้วกด Save เพื่อตรวจว่าขึ้นข้อความแจ้งเตือนเบอร์โทรไม่ถูกต้อง จากนั้นกด Discard Changes เพื่อตรวจว่าออกจากโหมดแก้ไขได้
  testWidgets(
    'ProfileScreen loads user info, validates edited phone, and discards changes',
    (tester) async {
      final api = testApi((request) async {
        if (request.url.path.endsWith('/users/profile') &&
            request.method == 'GET') {
          return testJsonResponse(testUser(id: 8));
        }
        return testJsonResponse({});
      });
      addTearDown(api.close);

      final storage = MemoryStorage(token: 'token-8');
      final authController = AuthController(api, storage);
      final profileController = ProfileController(api);
      addTearDown(authController.dispose);
      addTearDown(profileController.dispose);

      await authController.initialize();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiService>.value(value: api),
            ChangeNotifierProvider<AuthController>.value(value: authController),
            ChangeNotifierProvider<ProfileController>.value(
              value: profileController,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ProfileScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tea Stand'), findsOneWidget);
      expect(find.text('Vendor 8'), findsOneWidget);
      expect(find.text('0800000000'), findsOneWidget);
      expect(find.text('vendor8'), findsOneWidget);

      // เข้าสู่โหมดแก้ไขและทดสอบกรอกเบอร์โทรสั้นเกินไป
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(find.text('Discard Changes'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Phone number'),
        '12345',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(
        find.text('Enter a phone number with 8 to 15 digits.'),
        findsOneWidget,
      );

      // ยกเลิกการแก้ไข
      await tester.tap(find.text('Discard Changes'));
      await tester.pumpAndSettle();
      expect(find.text('Discard Changes'), findsNothing);
    },
  );

// ตรวจว่าตอนเริ่มผู้ใช้ล็อกอินอยู่ (isAuthenticated == true) แล้วกดปุ่ม Sign out เพื่อตรวจว่าออกจากระบบสำเร็จ (isAuthenticated == false)
  testWidgets('ProfileScreen signs out user when Sign out is tapped', (
    tester,
  ) async {
    final api = testApi((request) async {
      if (request.url.path.endsWith('/users/profile') &&
          request.method == 'GET') {
        return testJsonResponse(testUser(id: 8));
      }
      return testJsonResponse({});
    });
    addTearDown(api.close);

    final storage = MemoryStorage(token: 'token-8');
    final authController = AuthController(api, storage);
    final profileController = ProfileController(api);
    addTearDown(authController.dispose);
    addTearDown(profileController.dispose);

    await authController.initialize();
    expect(authController.isAuthenticated, isTrue);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: api),
          ChangeNotifierProvider<AuthController>.value(value: authController),
          ChangeNotifierProvider<ProfileController>.value(
            value: profileController,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ProfileScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(authController.isAuthenticated, isFalse);
  });
}