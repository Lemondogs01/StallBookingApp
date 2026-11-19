import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_market_app/controllers/auth_controller.dart';
import 'package:mfu_market_app/controllers/profile_controller.dart';
import 'package:mfu_market_app/services/api_service.dart';
import 'package:mfu_market_app/views/vendor/profile_screen.dart';
import 'package:provider/provider.dart';

import 'controller_test_support.dart';

void main() {
  // โหลดข้อมูลโปรไฟล์แล้วตรวจว่าแสดงชื่อร้าน, ชื่อจริง, เบอร์โทร และ username ถูกต้อง
  // กด Edit เพื่อเข้าสู่โหมดแก้ไข ลองกรอกเบอร์โทรสั้นเกินไป (12345) แล้วกด Save เพื่อตรวจว่าขึ้นข้อความแจ้งเตือนเบอร์โทรไม่ถูกต้อง จากนั้นกด Discard Changes เพื่อตรวจว่าออกจากโหมดแก้ไขได้
  testWidgets(
    'ProfileScreen loads user info, validates edited phone, and discards changes',
    (tester) async {
      final api = testApi((request) async {
        if (request.url.path.endsWith('/users/profile') &&
            request.method == 'GET') {
          return testJsonResponse(testUser(id: 8, profileImage: ''));
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

      expect(find.text('Tea Stand'), findsAtLeastNWidgets(1));
      expect(find.text('Vendor 8'), findsAtLeastNWidgets(1));
      expect(find.text('0800000000'), findsAtLeastNWidgets(1));
      expect(find.text('vendor8'), findsAtLeastNWidgets(1));

      // เข้าสู่โหมดแก้ไข
      final editButton = find.text('Edit');
      await tester.ensureVisible(editButton);
      await tester.pumpAndSettle();
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      // เลื่อนลงไปหาปุ่ม Discard Changes ที่อยู่ด้านล่างของ ListView
      final discardButton = find.text('Discard Changes');
      await tester.scrollUntilVisible(
        discardButton,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(discardButton, findsOneWidget);

      // ทดสอบกรอกเบอร์โทรสั้นเกินไปและกด Save
      final phoneField = find.widgetWithText(TextField, 'Phone number');
      await tester.scrollUntilVisible(
        phoneField,
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.enterText(phoneField, '12345');

      final saveButton = find.text('Save');
      await tester.scrollUntilVisible(
        saveButton,
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // เลื่อนลงไปตรวจข้อความแจ้งเตือนที่แสดงใน ErrorBanner ด้านล่าง
      final errorText = find.text('Enter a phone number with 8 to 15 digits.');
      await tester.scrollUntilVisible(
        errorText,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(errorText, findsOneWidget);

      // กด Discard Changes เพื่อยกเลิกการแก้ไข
      await tester.scrollUntilVisible(
        discardButton,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(discardButton);
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
        return testJsonResponse(testUser(id: 8, profileImage: ''));
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

    final signOutButton = find.text('Sign out');
    await tester.scrollUntilVisible(
      signOutButton,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(signOutButton);
    await tester.pumpAndSettle();

    expect(authController.isAuthenticated, isFalse);
  });
}