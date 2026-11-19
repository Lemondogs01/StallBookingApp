import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_market_app/controllers/booking_controller.dart';
import 'package:mfu_market_app/services/api_service.dart';
import 'package:mfu_market_app/views/vendor/vendor_home_screen.dart';
import 'package:provider/provider.dart';

import '../controller_test_support.dart';
// เริ่มต้นตรวจว่าแสดงหน้าเลือกหมวดหมู่ (Choose a Category) และมีหมวด Food & Drinks
// กดเลือกหมวด Food & Drinks แล้วตรวจว่าเปลี่ยนไปหน้าเลือกแผง (Choose a Stall) และเห็นแผง A1, A2 รวมถึงข้อความ Booked สำหรับแผงที่จองอนุมัติแล้ว
// กดปุ่ม Change แล้วตรวจว่าย้อนกลับไปหน้าเลือกหมวดหมู่ได้อีกครั้ง
void main() {
  testWidgets('VendorHomeScreen shows categories and displays stalls after selecting one', (tester) async {
    final api = testApi((request) async {
      if (request.url.path.endsWith('/stalls/status')) {
        return testJsonResponse({
          'stalls': [
            testStall(status: 'available'),
            {
              'stall_id': 'A2',
              'category': 'food',
              'price': '250.00',
              'status': 'approved',
            },
          ],
        });
      }
      if (request.url.path.endsWith('/bookings/my')) {
        return testJsonResponse([]);
      }
      return testJsonResponse({});
    });
    addTearDown(api.close);

    final bookingController = BookingController(api);
    addTearDown(bookingController.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: api),
          ChangeNotifierProvider<BookingController>.value(value: bookingController),
        ],
        child: const MaterialApp(
          home: Scaffold(body: VendorHomeScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Choose a Category'), findsOneWidget);
    expect(find.text('Food & Drinks'), findsOneWidget);

    await tester.tap(find.text('Food & Drinks'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a Stall'), findsOneWidget);
    expect(find.text('A1'), findsOneWidget);
    expect(find.text('A2'), findsOneWidget);
    expect(find.text('Booked'), findsOneWidget);

    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a Category'), findsOneWidget);
  });
}