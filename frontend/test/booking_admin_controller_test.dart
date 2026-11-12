import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mfu_market_app/controllers/admin_controller.dart';
import 'package:mfu_market_app/controllers/booking_controller.dart';
import 'package:mfu_market_app/models/booking_model.dart';
import 'package:mfu_market_app/models/stall_model.dart';
import 'package:mfu_market_app/models/user_model.dart';
import 'package:mfu_market_app/services/api_service.dart';

import 'controller_test_support.dart';

Map<String, dynamic> _analytics() => {
  'totalRevenue': 1000,
  'selectedDateRevenue': 250,
  'categoryRevenue': {'food': 250, 'fashion': 0, 'general': 0},
  'dailyBreakdown': [
    {'date': '2099-01-01', 'revenue': 250},
  ],
  'monthlyBreakdown': [
    {'month': '2099-01-01', 'revenue': 1000},
  ],
};

http.Response _dashboardResponse(http.Request request) {
  if (request.url.path.endsWith('/admin/analytics')) {
    return testJsonResponse(_analytics());
  }
  if (request.url.path.endsWith('/admin/bookings/pending')) {
    return testJsonResponse([testBooking()]);
  }
  if (request.url.path.endsWith('/stalls/status')) {
    return testJsonResponse({
      'stalls': [testStall()],
    });
  }
  if (request.url.path.endsWith('/bookings/my')) {
    return testJsonResponse([testBooking()]);
  }
  if (request.url.path.endsWith('/bookings')) {
    return testJsonResponse({'booking': testBooking(id: 20)});
  }
  return testJsonResponse({});
}

void main() {
  group('BookingController', () {
    // กรณีนี้ทดสอบ «loads stalls and history, then normalizes the selected date»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
    test(
      'loads stalls and history, then normalizes the selected date',
      () async {
        final api = testApi((request) async => _dashboardResponse(request));
        addTearDown(api.close);
        final controller = BookingController(api);
        addTearDown(controller.dispose);

        await controller.load();

        expect(controller.stalls.single.id, 'A1');
        expect(controller.bookings.single.id, 10);
        expect(controller.isLoadingStalls, isFalse);
        expect(controller.isLoadingBookings, isFalse);

        await controller.setDate(DateTime(2099, 1, 2, 15, 30));
        expect(controller.selectedDate, DateTime(2099, 1, 2));
        controller.selectCategory('food');
        expect(controller.selectedCategory, 'food');
      },
    );

    // กรณีนี้ทดสอบ «creates a booking and refreshes stalls and history»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
    test('creates a booking and refreshes stalls and history', () async {
      var createWasCalled = false;
      final api = testApi((request) async {
        if (request.method == 'POST' && request.url.path == '/api/bookings') {
          createWasCalled = true;
          expect(jsonDecode(request.body)['stall_id'], 'A1');
          return testJsonResponse({'booking': testBooking(id: 20)});
        }
        return _dashboardResponse(request);
      });
      addTearDown(api.close);
      final controller = BookingController(api);
      addTearDown(controller.dispose);

      final booking = await controller.createBooking(
        // The controller uses the currently selected market date.
        (await _availableStall(api)),
      );

      expect(createWasCalled, isTrue);
      expect(booking.id, 20);
      expect(controller.stalls, hasLength(1));
      expect(controller.bookings, hasLength(1));
    });

    // กรณีนี้ทดสอบ «reports a malformed booking response and cancellation API errors»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
    test(
      'reports a malformed booking response and cancellation API errors',
      () async {
        final api = testApi((request) async {
          if (request.method == 'POST') return testJsonResponse({});
          if (request.url.path.endsWith('/cancel')) {
            return testJsonResponse({
              'message': 'Payment is already submitted.',
            }, 409);
          }
          return _dashboardResponse(request);
        });
        addTearDown(api.close);
        final controller = BookingController(api);
        addTearDown(controller.dispose);

        await expectLater(
          controller.createBooking(
            const StallModel(
              id: 'A1',
              category: 'food',
              price: 250,
              status: 'available',
            ),
          ),
          throwsFormatException,
        );
        expect(controller.errorMessage, contains('Could not load'));

        final booking = BookingModel.fromJson(testBooking());
        await expectLater(
          controller.cancelBooking(booking),
          throwsA(isA<ApiException>()),
        );
        expect(controller.errorMessage, 'Payment is already submitted.');
      },
    );

    // กรณีนี้ทดสอบ «does nothing when a booking has no ID and keeps load errors readable»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
    test(
      'does nothing when a booking has no ID and keeps load errors readable',
      () async {
        var requests = 0;
        final api = testApi((request) async {
          requests += 1;
          return testJsonResponse({'message': 'Try again later.'}, 503);
        });
        addTearDown(api.close);
        final controller = BookingController(api);
        addTearDown(controller.dispose);

        await controller.load();
        expect(controller.errorMessage, 'Try again later.');
        final bookingWithoutId = BookingModel.fromJson({
          'booking_code': 'BK-20990101-A1B2',
          'stall_id': 'A1',
          'booking_date': '2099-01-01',
        });
        final requestsBeforeCancel = requests;
        await controller.cancelBooking(bookingWithoutId);
        expect(requests, requestsBeforeCancel);
      },
    );

    // กรณีนี้ทดสอบ «cancels an identified booking and refreshes the booking lists»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
    test(
      'cancels an identified booking and refreshes the booking lists',
      () async {
        var cancellationWasCalled = false;
        final api = testApi((request) async {
          if (request.url.path.endsWith('/bookings/10/cancel')) {
            cancellationWasCalled = true;
          }
          return _dashboardResponse(request);
        });
        addTearDown(api.close);
        final controller = BookingController(api);
        addTearDown(controller.dispose);

        await controller.cancelBooking(BookingModel.fromJson(testBooking()));

        expect(cancellationWasCalled, isTrue);
        expect(controller.bookings, hasLength(1));
        expect(controller.stalls, hasLength(1));
      },
    );
  });

  group('AdminController', () {
    // กรณีนี้ทดสอบ «loads dashboard data and updates the selected day»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
    test('loads dashboard data and updates the selected day', () async {
      final requests = <http.Request>[];
      final api = testApi((request) async {
        requests.add(request);
        return _dashboardResponse(request);
      });
      addTearDown(api.close);
      final controller = AdminController(api);
      addTearDown(controller.dispose);

      await controller.loadDashboard();

      expect(controller.analytics?.totalRevenue, 1000);
      expect(controller.pendingBookings.single.id, 10);
      expect(controller.stalls.single.id, 'A1');
      expect(controller.isLoadingDashboard, isFalse);

      await controller.setDate(DateTime(2099, 1, 2, 17));
      expect(controller.selectedDate, DateTime(2099, 1, 2));
      expect(
        requests
            .where((request) => request.url.path.endsWith('/admin/analytics'))
            .last
            .url
            .queryParameters['date'],
        '2099-01-02',
      );
    });

    // กรณีนี้ทดสอบ «sends an approval decision and refreshes the dashboard»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
    test('sends an approval decision and refreshes the dashboard', () async {
      final decisions = <String>[];
      final api = testApi((request) async {
        if (request.url.path.endsWith('/verify')) {
          decisions.add(jsonDecode(request.body)['status'] as String);
        }
        return _dashboardResponse(request);
      });
      addTearDown(api.close);
      final controller = AdminController(api);
      addTearDown(controller.dispose);
      final booking = BookingModel.fromJson(testBooking());

      await controller.verifyBooking(booking, approve: true);
      await controller.verifyBooking(booking, approve: false);

      expect(decisions, ['approved', 'rejected']);
      expect(controller.errorMessage, isNull);
    });

    // กรณีนี้ทดสอบ «does not send a decision for a booking without an ID»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
    test('does not send a decision for a booking without an ID', () async {
      var requests = 0;
      final api = testApi((_) async {
        requests += 1;
        return testJsonResponse({});
      });
      addTearDown(api.close);
      final controller = AdminController(api);
      addTearDown(controller.dispose);
      final booking = BookingModel.fromJson({
        'booking_code': 'BK-20990101-A1B2',
        'stall_id': 'A1',
        'booking_date': '2099-01-01',
      });

      await controller.verifyBooking(booking, approve: true);
      expect(requests, 0);
    });

    // กรณีนี้ทดสอบ «reports verification and vendor-search errors and ignores users without IDs»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
    test(
      'reports verification and vendor-search errors and ignores users without IDs',
      () async {
        var verifyFailure = true;
        final api = testApi((request) async {
          if (request.url.path.endsWith('/verify') && verifyFailure) {
            return testJsonResponse({
              'message': 'Booking is already reviewed.',
            }, 409);
          }
          if (request.url.path.endsWith('/admin/users')) {
            return testJsonResponse({'message': 'Admin only.'}, 403);
          }
          return _dashboardResponse(request);
        });
        addTearDown(api.close);
        final controller = AdminController(api);
        addTearDown(controller.dispose);
        final booking = BookingModel.fromJson(testBooking());

        await expectLater(
          controller.verifyBooking(booking, approve: true),
          throwsA(isA<ApiException>()),
        );
        expect(controller.errorMessage, 'Booking is already reviewed.');

        verifyFailure = false;
        await controller.loadUsers(query: 'vendor');
        expect(controller.errorMessage, 'Admin only.');
        expect(controller.isLoadingUsers, isFalse);

        final userWithoutId = UserModel.fromJson({'username': 'vendor'});
        await controller.resetPassword(userWithoutId);
        expect(controller.errorMessage, 'Admin only.');
      },
    );

    // กรณีนี้ทดสอบ «uses the newest user-search result when requests finish out of order»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
    test(
      'uses the newest user-search result when requests finish out of order',
      () async {
        final oldResponse = Completer<http.Response>();
        final newResponse = Completer<http.Response>();
        final api = ApiService(
          baseUrl: testBaseUrl,
          client: MockClient((request) {
            final query = request.url.queryParameters['query'];
            return query == 'old' ? oldResponse.future : newResponse.future;
          }),
        );
        addTearDown(api.close);
        final controller = AdminController(api);
        addTearDown(controller.dispose);

        final oldRequest = controller.loadUsers(query: 'old');
        final newRequest = controller.loadUsers(query: 'new');
        newResponse.complete(testJsonResponse([testUser(id: 2)]));
        await newRequest;
        oldResponse.complete(testJsonResponse([testUser(id: 1)]));
        await oldRequest;

        expect(controller.users.single.id, 2);
        expect(controller.isLoadingUsers, isFalse);
      },
    );

    // กรณีนี้ทดสอบ «reports dashboard and password-reset API errors»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
    test('reports dashboard and password-reset API errors', () async {
      final api = testApi(
        (request) async => testJsonResponse({
          'message': 'Administrator access required.',
        }, 403),
      );
      addTearDown(api.close);
      final controller = AdminController(api);
      addTearDown(controller.dispose);

      await controller.loadDashboard();
      expect(controller.errorMessage, 'Administrator access required.');
      final user = UserModel.fromJson(testUser());
      await expectLater(
        controller.resetPassword(user),
        throwsA(isA<ApiException>()),
      );
      expect(controller.errorMessage, 'Administrator access required.');
    });
  });
}

Future<StallModel> _availableStall(ApiService api) async {
  final response = await api.getStallStatus(date: DateTime(2099, 1, 1));
  return StallModel.fromJson(
    (response['stalls'] as List).first as Map<String, dynamic>,
  );
}
