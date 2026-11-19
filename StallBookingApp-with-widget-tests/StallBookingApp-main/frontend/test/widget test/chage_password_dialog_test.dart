import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_market_app/controllers/auth_controller.dart';
import 'package:mfu_market_app/views/auth/change_password_dialog.dart';
import 'package:provider/provider.dart';

import '../controller_test_support.dart';
// เปิด dialog แล้วกรอก New password กับ Confirm new password ให้ไม่ตรงกัน แล้วกด Save password เพื่อตรวจว่าขึ้นข้อความ Passwords do not match. และยังไม่ส่งคำขอเปลี่ยนรหัสผ่านไปที่ API
// แก้ Confirm new password ให้ตรงกันแล้วกด Save password เพื่อตรวจว่าเรียก API เปลี่ยนรหัสผ่านสำเร็จและปิด dialog คืนค่า true
void main() {
  testWidgets('ChangePasswordDialog validates mismatch and submits new password', (tester) async {
    var passwordChanged = false;
    final api = testApi((request) async {
      if (request.url.path == '/api/users/password') {
        passwordChanged = true;
        return testJsonResponse({});
      }
      return testJsonResponse({});
    });
    addTearDown(api.close);

    final authController = AuthController(api, MemoryStorage());
    addTearDown(authController.dispose);

    bool? dialogResult;

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthController>.value(
        value: authController,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await showChangePasswordDialog(context);
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // กรอก Confirm ไม่ตรงกัน
    await tester.enterText(find.widgetWithText(TextFormField, 'Current password'), 'oldpass123');
    await tester.enterText(find.widgetWithText(TextFormField, 'New password'), 'newpass123');
    await tester.enterText(find.widgetWithText(TextFormField, 'Confirm new password'), 'different123');
    await tester.tap(find.text('Save password'));
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(passwordChanged, isFalse);

    // กรอก Confirm ให้ตรงกันแล้วบันทึก
    await tester.enterText(find.widgetWithText(TextFormField, 'Confirm new password'), 'newpass123');
    await tester.tap(find.text('Save password'));
    await tester.pumpAndSettle();

    expect(passwordChanged, isTrue);
    expect(dialogResult, isTrue);
  });
}