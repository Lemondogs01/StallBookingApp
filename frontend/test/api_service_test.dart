import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mfu_market_app/services/api_service.dart';

http.Response _jsonResponse(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);

void main() {
  group('ApiService configuration', () {
    // กรณีนี้ทดสอบ «supports simulator and Android emulator addresses»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
    test('supports simulator and Android emulator addresses', () {
      expect(ApiService.simulatorBaseUrl, 'http://localhost:5001/api/');
      expect(ApiService.androidEmulatorBaseUrl, 'http://10.0.2.2:5001/api/');
      expect(ApiService.formatApiDate(DateTime(2026, 3, 4)), '2026-03-04');
    });

    // กรณีนี้ทดสอบ «selects a base URL for the active platform and normalizes its path»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
    test(
      'selects a base URL for the active platform and normalizes its path',
      () {
        final previousPlatform = debugDefaultTargetPlatformOverride;
        try {
          debugDefaultTargetPlatformOverride = TargetPlatform.android;
          expect(ApiService.defaultBaseUrl, ApiService.androidEmulatorBaseUrl);
          debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
          expect(ApiService.defaultBaseUrl, ApiService.simulatorBaseUrl);
        } finally {
          debugDefaultTargetPlatformOverride = previousPlatform;
        }

        final api = ApiService(
          baseUrl: 'http://localhost:5001/api?old=1#fragment',
        );
        addTearDown(api.close);
        expect(api.baseUri.toString(), 'http://localhost:5001/api/');
      },
    );

    // กรณีนี้ทดสอบ «resolves relative media paths and preserves absolute URLs»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
    test('resolves relative media paths and preserves absolute URLs', () {
      final api = ApiService(
        baseUrl: 'http://localhost:5001/api',
        client: MockClient((_) async => _jsonResponse({})),
      );
      addTearDown(api.close);

      expect(
        api.resolveMediaUrl('/uploads/profiles/vendor.png'),
        'http://localhost:5001/uploads/profiles/vendor.png',
      );
      expect(
        api.resolveMediaUrl('https://cdn.example.test/vendor.png'),
        'https://cdn.example.test/vendor.png',
      );
    });
  });

  // กรณีนี้ทดสอบ «uses the expected HTTP paths, JSON fields, query values, and auth headers»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  test(
    'uses the expected HTTP paths, JSON fields, query values, and auth headers',
    () async {
      final requests = <http.Request>[];
      final api = ApiService(
        baseUrl: 'http://localhost:5001/api',
        client: MockClient((request) async {
          requests.add(request);
          final path = request.url.path;
          if (path.endsWith('/bookings/my') ||
              path.endsWith('/admin/bookings/pending') ||
              path.endsWith('/admin/users')) {
            return _jsonResponse([]);
          }
          return _jsonResponse({});
        }),
      );
      addTearDown(api.close);
      api.setAccessToken('  test-token  ');

      await api.healthCheck();
      await api.registerVendor(
        username: 'vendor1',
        password: 'password123',
        shopName: 'Tea Shop',
        realName: 'Vendor One',
        phone: '0800000000',
      );
      await api.login(username: 'vendor1', password: 'password123');
      await api.getStallStatus(date: DateTime(2026, 3, 4));
      await api.createBooking(stallId: 'A1', bookingDate: DateTime(2026, 3, 4));
      await api.getMyBookings();
      await api.cancelBooking(bookingId: 10);
      await api.getProfile();
      await api.updateProfile(
        shopName: 'Tea Shop',
        realName: 'Vendor One',
        phone: '0800000000',
      );
      await api.changePassword(
        currentPassword: 'old-password',
        newPassword: 'new-password',
      );
      await api.getPendingBookings();
      await api.verifyBooking(bookingId: 10, status: 'approved');
      await api.getAdminAnalytics(date: DateTime(2026, 3, 4));
      await api.getAdminUsers(query: ' vendor ');
      await api.getAdminUsers(query: '   ');
      await api.resetUserPassword(userId: 7, newPassword: 'new-password');
      await api.resetUserPassword(userId: 7);

      expect(requests.map((request) => request.method).toList(), [
        'GET',
        'POST',
        'POST',
        'GET',
        'POST',
        'GET',
        'PUT',
        'GET',
        'PUT',
        'PUT',
        'GET',
        'PUT',
        'GET',
        'GET',
        'GET',
        'PUT',
        'PUT',
      ]);
      expect(requests[0].url.path, '/api/health');
      expect(requests[1].url.path, '/api/auth/register');
      expect(requests[2].url.path, '/api/auth/login');
      expect(requests[3].url.queryParameters['date'], '2026-03-04');
      expect(requests[4].url.path, '/api/bookings');
      expect(requests[5].url.path, '/api/bookings/my');
      expect(requests[6].url.path, '/api/bookings/10/cancel');
      expect(requests[10].url.path, '/api/admin/bookings/pending');
      expect(requests[11].url.path, '/api/admin/bookings/10/verify');
      expect(requests[13].url.queryParameters['query'], 'vendor');
      expect(requests[14].url.queryParameters.containsKey('query'), isFalse);
      expect(requests[15].url.path, '/api/admin/users/7/reset-password');

      for (final index in [1, 2]) {
        final body = jsonDecode(requests[index].body) as Map<String, dynamic>;
        expect(body.containsKey('email'), isFalse);
      }
      expect(jsonDecode(requests[4].body), {
        'stall_id': 'A1',
        'booking_date': '2026-03-04',
      });
      expect(requests[0].headers.containsKey('Authorization'), isFalse);
      expect(requests[1].headers.containsKey('Authorization'), isFalse);
      expect(requests[2].headers.containsKey('Authorization'), isFalse);
      for (final request in requests.skip(3)) {
        expect(request.headers['Authorization'], 'Bearer test-token');
      }
    },
  );

  // กรณีนี้ทดสอบ «sends multipart slip fields and validates approval decisions»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  test(
    'sends multipart slip fields and validates approval decisions',
    () async {
      final requests = <http.Request>[];
      final api = ApiService(
        baseUrl: 'http://localhost:5001/api/',
        client: MockClient((request) async {
          requests.add(request);
          return _jsonResponse({});
        }),
      );
      addTearDown(api.close);

      await api.uploadPaymentSlip(
        bookingId: 10,
        amount: 250,
        imageBytes: Uint8List.fromList([0xFF, 0xD8, 0xFF]),
        filename: 'receipt.jpeg',
      );
      await expectLater(
        api.verifyBooking(bookingId: 10, status: 'cancelled'),
        throwsArgumentError,
      );

      expect(requests, hasLength(1));
      expect(requests.single.method, 'POST');
      expect(requests.single.url.path, '/api/payments');
      final multipart = String.fromCharCodes(requests.single.bodyBytes);
      expect(multipart, contains('name="booking_id"'));
      expect(multipart, contains('10'));
      expect(multipart, contains('name="amount"'));
      expect(multipart, contains('250'));
      expect(multipart, contains('name="slip"'));
      expect(multipart, contains('filename="receipt.jpg"'));
    },
  );

  // กรณีนี้ทดสอบ «recognizes GIF, WebP, HEIC, HEIF, and safe filename extensions»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  test(
    'recognizes GIF, WebP, HEIC, HEIF, and safe filename extensions',
    () async {
      final bodies = <String>[];
      final api = ApiService(
        baseUrl: 'http://localhost:5001/api',
        client: MockClient((request) async {
          bodies.add(String.fromCharCodes(request.bodyBytes));
          return _jsonResponse({});
        }),
      );
      addTearDown(api.close);
      final cases =
          <({List<int> bytes, String filename, String mime, String safeName})>[
            (
              bytes: [0x47, 0x49, 0x46, 0x38],
              filename: 'market.gif',
              mime: 'image/gif',
              safeName: 'market.gif',
            ),
            (
              bytes: [82, 73, 70, 70, 0, 0, 0, 0, 87, 69, 66, 80],
              filename: 'market.webp',
              mime: 'image/webp',
              safeName: 'market.webp',
            ),
            (
              bytes: [0, 0, 0, 0, 102, 116, 121, 112, 104, 101, 105, 99],
              filename: 'market.heic',
              mime: 'image/heic',
              safeName: 'market.heic',
            ),
            (
              bytes: [0, 0, 0, 0, 102, 116, 121, 112, 104, 101, 105, 102],
              filename: 'market.heif',
              mime: 'image/heif',
              safeName: 'market.heif',
            ),
            (
              bytes: [1],
              filename: '../receipt.JPEG',
              mime: 'image/jpeg',
              safeName: 'receipt.jpg',
            ),
          ];

      for (final (index, item) in cases.indexed) {
        await api.replacePaymentSlip(
          bookingId: index + 1,
          imageBytes: Uint8List.fromList(item.bytes),
          filename: item.filename,
        );
        expect(bodies[index], contains('content-type: ${item.mime}'));
        expect(bodies[index], contains('filename="${item.safeName}"'));
      }
    },
  );

  // กรณีนี้ทดสอบ «converts HTTP errors to ApiException with the server message»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  test(
    'converts HTTP errors to ApiException with the server message',
    () async {
      final api = ApiService(
        baseUrl: 'http://localhost:5001/api',
        client: MockClient(
          (_) async =>
              _jsonResponse({'message': 'Booking is already approved.'}, 409),
        ),
      );
      addTearDown(api.close);

      await expectLater(
        api.getProfile(),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 409)
              .having(
                (error) => error.message,
                'message',
                'Booking is already approved.',
              ),
        ),
      );
    },
  );

  // กรณีนี้ทดสอบ «prints an ApiException with its status and message»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  test('prints an ApiException with its status and message', () {
    const error = ApiException(statusCode: 401, message: 'Sign in again.');

    expect(error.toString(), 'ApiException(401): Sign in again.');
  });

  // กรณีนี้ทดสอบ «uses a fallback error message when the server sends no message»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  test(
    'uses a fallback error message when the server sends no message',
    () async {
      final api = ApiService(
        baseUrl: 'http://localhost:5001/api',
        client: MockClient((_) async => http.Response('', 503)),
      );
      addTearDown(api.close);

      await expectLater(
        api.getProfile(),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            'Request failed with status 503.',
          ),
        ),
      );
    },
  );

  // กรณีนี้ทดสอบ «rejects a successful response with the wrong JSON shape»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  test('rejects a successful response with the wrong JSON shape', () async {
    final api = ApiService(
      baseUrl: 'http://localhost:5001/api',
      client: MockClient((_) async => _jsonResponse([])),
    );
    addTearDown(api.close);

    await expectLater(api.getProfile(), throwsFormatException);
  });

  // กรณีนี้ทดสอบ «handles empty or malformed JSON and invalid list entries»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  test('handles empty or malformed JSON and invalid list entries', () async {
    final responses = <http.Response>[
      http.Response('', 200),
      http.Response('not-json', 200),
      _jsonResponse([
        {'id': 1},
        'invalid-entry',
      ]),
    ];
    final api = ApiService(
      baseUrl: 'http://localhost:5001/api',
      client: MockClient((_) async => responses.removeAt(0)),
    );
    addTearDown(api.close);

    await expectLater(api.getProfile(), throwsFormatException);
    await expectLater(api.getProfile(), throwsFormatException);
    await expectLater(api.getMyBookings(), throwsFormatException);
  });

  // กรณีนี้ทดสอบ «rejects an empty or unsupported image without sending a request»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  test(
    'rejects an empty or unsupported image without sending a request',
    () async {
      var requestCount = 0;
      final api = ApiService(
        baseUrl: 'http://localhost:5001/api',
        client: MockClient((_) async {
          requestCount += 1;
          return _jsonResponse({});
        }),
      );
      addTearDown(api.close);

      for (final filename in ['document.pdf', '']) {
        await expectLater(
          api.replacePaymentSlip(
            bookingId: 10,
            imageBytes: Uint8List(0),
            filename: filename,
          ),
          throwsFormatException,
        );
      }
      expect(requestCount, 0);
    },
  );
}
