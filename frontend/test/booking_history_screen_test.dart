// ทดสอบปุ่มยกเลิกและคำเตือนในหน้าประวัติการจอง
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mfu_market_app/controllers/booking_controller.dart';
import 'package:mfu_market_app/services/api_service.dart';
import 'package:mfu_market_app/views/vendor/booking_history_screen.dart';

import 'controller_test_support.dart';

void main() {
  // booking pending ที่มีสลิปต้องมีปุ่ม Cancel และแจ้งชัดเจนว่าระบบไม่คืนเงินอัตโนมัติ
  testWidgets('shows Cancel and refund warning for a pending booking with a slip', (tester) async {
    final api = testApi((request) async {
      if (request.url.path.endsWith('/bookings/my')) {
        return testJsonResponse([testBooking()]);
      }
      return testJsonResponse({});
    });
    addTearDown(api.close);
    final controller = BookingController(api);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: api),
          ChangeNotifierProvider<BookingController>.value(value: controller),
        ],
        child: const MaterialApp(
          home: Scaffold(body: BookingHistoryScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Replace Slip'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Cancel Booking?'), findsOneWidget);
    expect(
      find.textContaining('Cancellation does not automatically refund your payment'),
      findsOneWidget,
    );
    expect(find.text('Keep Booking'), findsOneWidget);

    await tester.tap(find.text('Keep Booking'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel Booking?'), findsNothing);
  });

  // booking ที่ผ่านสถานะ pending แล้วต้องไม่มีปุ่มยกเลิก
  testWidgets('hides Cancel for a booking that is no longer pending', (tester) async {
    final booking = {...testBooking(), 'status': 'approved'};
    final api = testApi((request) async {
      if (request.url.path.endsWith('/bookings/my')) {
        return testJsonResponse([booking]);
      }
      return testJsonResponse({});
    });
    addTearDown(api.close);
    final controller = BookingController(api);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: api),
          ChangeNotifierProvider<BookingController>.value(value: controller),
        ],
        child: const MaterialApp(
          home: Scaffold(body: BookingHistoryScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cancel'), findsNothing);
    expect(find.text('View Slip'), findsOneWidget);
  });
}
