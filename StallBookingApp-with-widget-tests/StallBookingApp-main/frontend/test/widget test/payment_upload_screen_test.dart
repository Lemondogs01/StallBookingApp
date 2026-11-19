import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_market_app/controllers/booking_controller.dart';
import 'package:mfu_market_app/controllers/payment_controller.dart';
import 'package:mfu_market_app/models/booking_model.dart';
import 'package:mfu_market_app/models/stall_model.dart';
import 'package:mfu_market_app/services/api_service.dart';
import 'package:mfu_market_app/views/vendor/payment_upload_screen.dart';
import 'package:provider/provider.dart';

import '../controller_test_support.dart';

void main() {
  // เปิดหน้าต่างจองและจ่ายเงินของแผงตัวอย่าง (฿250) แล้วกด Book Stall and Submit Slip โดยยังไม่เลือกรูปสลิป เพื่อตรวจว่าแสดงข้อความเตือน Choose a payment slip before continuing.
  testWidgets(
    'PaymentUploadScreen shows error when submitting without selecting a slip',
    (tester) async {
      final api = testApi((_) async => testJsonResponse({}));
      addTearDown(api.close);

      final bookingController = BookingController(api);
      final paymentController = PaymentController(api);
      addTearDown(bookingController.dispose);
      addTearDown(paymentController.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiService>.value(value: api),
            ChangeNotifierProvider<BookingController>.value(
              value: bookingController,
            ),
            ChangeNotifierProvider<PaymentController>.value(
              value: paymentController,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PaymentUploadScreen(
                stall: StallModel.fromJson(testStall()),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pay for Your Stall'), findsOneWidget);
      expect(find.text('฿250'), findsOneWidget);
      expect(find.text('Book Stall and Submit Slip'), findsOneWidget);

      await tester.tap(find.text('Book Stall and Submit Slip'));
      await tester.pumpAndSettle();

      expect(
        find.text('Choose a payment slip before continuing.'),
        findsOneWidget,
      );
    },
  );

//เปิดหน้าต่างโดยส่ง existingBooking ที่มีสลิปอยู่แล้วเข้าไป เพื่อตรวจว่าหัวข้อและปุ่มเปลี่ยนเป็นโหมดแทนที่สลิป (Edit Payment Slip, Choose Replacement Slip, Replace Payment Slip) และแสดงข้อความ Current payment slip
  testWidgets(
    'PaymentUploadScreen displays replace-slip labels when editing an existing slip',
    (tester) async {
      final api = testApi((_) async => testJsonResponse({}));
      addTearDown(api.close);

      final bookingController = BookingController(api);
      final paymentController = PaymentController(api);
      addTearDown(bookingController.dispose);
      addTearDown(paymentController.dispose);

      final existingBooking = BookingModel.fromJson(testBooking(id: 10));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiService>.value(value: api),
            ChangeNotifierProvider<BookingController>.value(
              value: bookingController,
            ),
            ChangeNotifierProvider<PaymentController>.value(
              value: paymentController,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PaymentUploadScreen(
                stall: StallModel.fromJson(testStall()),
                existingBooking: existingBooking,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Payment Slip'), findsOneWidget);
      expect(find.text('Choose Replacement Slip'), findsOneWidget);
      expect(find.text('Replace Payment Slip'), findsOneWidget);
      expect(find.text('Current payment slip'), findsOneWidget);
    },
  );
}