import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_market_app/controllers/payment_controller.dart';
import 'package:mfu_market_app/controllers/profile_controller.dart';
import 'package:mfu_market_app/services/api_service.dart';

import 'controller_test_support.dart';

void main() {
  group('ProfileController', () {
    // กรณีนี้ทดสอบ «loads the current profile»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
    test('loads the current profile', () async {
      final api = testApi((_) async => testJsonResponse(testUser()));
      addTearDown(api.close);
      final controller = ProfileController(api);
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.profile?.username, 'vendor8');
      expect(controller.errorMessage, isNull);
      expect(controller.isLoading, isFalse);
    });

    // กรณีนี้ทดสอบ «shows an API error when loading the profile fails»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
    test('shows an API error when loading the profile fails', () async {
      final api = testApi(
        (_) async => testJsonResponse({'message': 'Sign in again.'}, 401),
      );
      addTearDown(api.close);
      final controller = ProfileController(api);
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.profile, isNull);
      expect(controller.errorMessage, 'Sign in again.');
    });

    // กรณีนี้ทดสอบ «keeps profile state and resets loading after a save error»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
    test('keeps profile state and resets loading after a save error', () async {
      final api = testApi(
        (_) async => testJsonResponse({'message': 'Phone already used.'}, 409),
      );
      addTearDown(api.close);
      final controller = ProfileController(api);
      addTearDown(controller.dispose);

      final saved = await controller.save(
        shopName: 'Tea Stand',
        realName: 'Vendor Eight',
        phone: '0800000000',
      );

      expect(saved, isFalse);
      expect(controller.errorMessage, 'Phone already used.');
      expect(controller.isSaving, isFalse);
    });
  });

  group('PaymentController', () {
    // กรณีนี้ทดสอบ «submits a slip and returns the parsed payment»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
    test('submits a slip and returns the parsed payment', () async {
      final api = testApi((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/payments');
        return testJsonResponse({
          'payment': {
            'id': 31,
            'booking_id': 10,
            'amount': 250,
            'slip_url': '/uploads/slips/new.png',
          },
        });
      });
      addTearDown(api.close);
      final controller = PaymentController(api);
      addTearDown(controller.dispose);

      final payment = await controller.submitSlip(
        bookingId: 10,
        amount: 250,
        imageBytes: Uint8List.fromList([0xFF, 0xD8, 0xFF]),
        filename: 'new.png',
      );

      expect(payment.id, 31);
      expect(payment.bookingId, 10);
      expect(payment.slipUrl, '/uploads/slips/new.png');
      expect(controller.isSubmitting, isFalse);
      expect(controller.errorMessage, isNull);
    });

    // กรณีนี้ทดสอบ «reports a missing payment record and API errors»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
    test('reports a missing payment record and API errors', () async {
      final api = testApi((_) async => testJsonResponse({}));
      addTearDown(api.close);
      final controller = PaymentController(api);
      addTearDown(controller.dispose);

      await expectLater(
        controller.submitSlip(
          bookingId: 10,
          amount: 250,
          imageBytes: Uint8List.fromList([0xFF, 0xD8, 0xFF]),
          filename: 'new.jpg',
        ),
        throwsFormatException,
      );
      expect(controller.errorMessage, contains('Could not submit'));
      expect(controller.isSubmitting, isFalse);
    });

    // กรณีนี้ทดสอบ «shows the server message when slip submission is rejected»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
    test('shows the server message when slip submission is rejected', () async {
      final api = testApi(
        (_) async => testJsonResponse({
          'message': 'The booking is already approved.',
        }, 409),
      );
      addTearDown(api.close);
      final controller = PaymentController(api);
      addTearDown(controller.dispose);

      await expectLater(
        controller.submitSlip(
          bookingId: 10,
          amount: 250,
          imageBytes: Uint8List.fromList([0xFF, 0xD8, 0xFF]),
          filename: 'new.jpg',
        ),
        throwsA(isA<ApiException>()),
      );

      expect(controller.errorMessage, 'The booking is already approved.');
      expect(controller.isSubmitting, isFalse);
    });

    // กรณีนี้ทดสอบ «replaces a slip at the booking history endpoint»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
    test('replaces a slip at the booking history endpoint', () async {
      final api = testApi((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/payments/10/slip');
        return testJsonResponse({});
      });
      addTearDown(api.close);
      final controller = PaymentController(api);
      addTearDown(controller.dispose);

      await controller.replaceSlip(
        bookingId: 10,
        imageBytes: Uint8List.fromList([0xFF, 0xD8, 0xFF]),
        filename: 'replacement.jpg',
      );

      expect(controller.isSubmitting, isFalse);
      expect(controller.errorMessage, isNull);
    });

    // กรณีนี้ทดสอบ «keeps the server error when slip replacement fails»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
    test('keeps the server error when slip replacement fails', () async {
      final api = testApi(
        (_) async => testJsonResponse({
          'message': 'Only pending bookings can be edited.',
        }, 409),
      );
      addTearDown(api.close);
      final controller = PaymentController(api);
      addTearDown(controller.dispose);

      await expectLater(
        controller.replaceSlip(
          bookingId: 10,
          imageBytes: Uint8List.fromList([0xFF, 0xD8, 0xFF]),
          filename: 'replacement.jpg',
        ),
        throwsA(isA<ApiException>()),
      );
      expect(controller.errorMessage, 'Only pending bookings can be edited.');
      expect(controller.isSubmitting, isFalse);
    });
  });
}
