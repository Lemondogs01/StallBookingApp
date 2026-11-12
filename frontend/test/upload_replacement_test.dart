import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mfu_market_app/controllers/profile_controller.dart';
import 'package:mfu_market_app/services/api_service.dart';

void main() {
  group('upload replacement requests', () {
    // กรณีนี้ทดสอบ «sends a replacement slip to the booking slip endpoint»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
    test('sends a replacement slip to the booking slip endpoint', () async {
      var requestWasCorrect = false;
      final api = ApiService(
        baseUrl: 'http://localhost:5001/api',
        client: MockClient((request) async {
          final multipartBody = String.fromCharCodes(request.bodyBytes);
          requestWasCorrect =
              request.method == 'PUT' &&
              request.url.path == '/api/payments/9/slip' &&
              multipartBody.contains('name="slip"') &&
              multipartBody.contains('new-slip.png');
          return http.Response('{}', 200);
        }),
      );

      await api.replacePaymentSlip(
        bookingId: 9,
        imageBytes: Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
        ]),
        filename: 'new-slip.png',
      );

      expect(requestWasCorrect, isTrue);
      api.close();
    });

    // กรณีนี้ทดสอบ «uses the newly returned profile image in controller state»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
    test('uses the newly returned profile image in controller state', () async {
      final api = ApiService(
        baseUrl: 'http://localhost:5001/api',
        client: MockClient((request) async {
          final multipartBody = String.fromCharCodes(request.bodyBytes);
          expect(request.method, 'PUT');
          expect(request.url.path, '/api/users/profile');
          expect(multipartBody, contains('name="profile_image"'));
          expect(multipartBody, contains('new-profile.png'));

          return http.Response(
            jsonEncode({
              'user': {
                'id': 7,
                'username': 'vendor7',
                'role': 'vendor',
                'shop_name': 'Tea Stand',
                'real_name': 'A Vendor',
                'phone': '0800000000',
                'profile_image': '/uploads/profiles/new-profile.png',
              },
            }),
            200,
          );
        }),
      );
      final controller = ProfileController(api);

      final saved = await controller.save(
        shopName: 'Tea Stand',
        realName: 'A Vendor',
        phone: '0800000000',
        imageBytes: Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
        ]),
        imageFilename: 'new-profile.png',
      );

      expect(saved, isTrue);
      expect(
        controller.profile?.profileImage,
        '/uploads/profiles/new-profile.png',
      );
      expect(controller.isSaving, isFalse);
      controller.dispose();
      api.close();
    });

    // กรณีนี้ทดสอบ «rejects an empty or unsupported image before sending a request»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
    test(
      'rejects an empty or unsupported image before sending a request',
      () async {
        final api = ApiService(
          baseUrl: 'http://localhost:5001/api',
          client: MockClient((_) async => http.Response('{}', 200)),
        );

        await expectLater(
          api.replacePaymentSlip(
            bookingId: 9,
            imageBytes: Uint8List(0),
            filename: 'document.pdf',
          ),
          throwsFormatException,
        );
        api.close();
      },
    );
  });
}
