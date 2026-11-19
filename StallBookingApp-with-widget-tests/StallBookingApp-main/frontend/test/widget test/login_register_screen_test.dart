import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_market_app/controllers/auth_controller.dart';
import 'package:mfu_market_app/views/auth/login_screen.dart';
import 'package:mfu_market_app/views/auth/register_screen.dart';
import 'package:provider/provider.dart';

import '../controller_test_support.dart';
// กดปุ่ม Sign in ตอนยังไม่กรอกข้อมูล แล้วตรวจว่าขึ้นข้อความเตือนให้กรอก Username และ Password 
// กรอกข้อมูลแล้วกด Sign in เพื่อตรวจว่า AuthController ล็อกอินสำเร็จและเก็บ token ไว้
void main() {
  testWidgets('LoginScreen validates empty inputs and submits credentials', (tester) async {
    final storage = MemoryStorage();
    final api = testApi((request) async {
      if (request.url.path == '/api/auth/login') {
        return testJsonResponse({'token': 'jwt-123', 'user': testUser()});
      }
      return testJsonResponse({});
    });
    addTearDown(api.close);

    final authController = AuthController(api, storage);
    addTearDown(authController.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthController>.value(
        value: authController,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    // กด Sign in ตอนยังไม่กรอกข้อมูล
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your username.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);

    // กรอกข้อมูลและล็อกอิน
    await tester.enterText(find.widgetWithText(TextFormField, 'Username'), 'vendor8');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password123');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(authController.isAuthenticated, isTrue);
    expect(storage.token, 'jwt-123');
  });
// กดปุ่ม Forgot your password? แล้วตรวจว่ามี dialog แสดงขึ้นมา และปิดได้ด้วยปุ่ม Got it
// กดปุ่ม Create a vendor account แล้วตรวจว่าเปิดหน้า RegisterScreen ได้จริง
  testWidgets('LoginScreen opens forgot password dialog and navigates to RegisterScreen', (tester) async {
    final api = testApi((_) async => testJsonResponse({}));
    addTearDown(api.close);
    final authController = AuthController(api, MemoryStorage());
    addTearDown(authController.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthController>.value(
        value: authController,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.tap(find.text('Forgot your password?'));
    await tester.pumpAndSettle();
    expect(find.text('Forgot your password?'), findsWidgets);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create a vendor account'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(find.text('Create your vendor account'), findsOneWidget);
  });

// กรอกเบอร์โทรสั้นเกินไป (1234) และรหัสผ่านสั้นกว่า 8 ตัว (1234567) แล้วกด Create account เพื่อตรวจว่าฟอร์มแจ้งเตือนเรื่องความยาวเบอร์โทร (8–15 หลัก) และความยาวรหัสผ่าน (อย่างน้อย 8 ตัวอักษร)
  testWidgets('RegisterScreen validates short password and invalid phone', (tester) async {
    final api = testApi((_) async => testJsonResponse({}));
    addTearDown(api.close);
    final authController = AuthController(api, MemoryStorage());
    addTearDown(authController.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthController>.value(
        value: authController,
        child: const MaterialApp(home: RegisterScreen()),
      ),
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Shop name'), 'My Shop');
    await tester.enterText(find.widgetWithText(TextFormField, 'Full name'), 'Somchai');
    await tester.enterText(find.widgetWithText(TextFormField, 'Phone number'), '1234');
    await tester.enterText(find.widgetWithText(TextFormField, 'Username'), 'somchai');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), '1234567');

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a phone number with 8 to 15 digits.'), findsOneWidget);
    expect(find.text('Use at least 8 characters.'), findsOneWidget);
  });
}