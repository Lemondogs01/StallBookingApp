import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_market/controller/auth_controller.dart';
import 'package:mfu_market/controller/booking_controller.dart';
import 'package:mfu_market/controller/mock_db.dart';
import 'package:mfu_market/controller/stall_controller.dart';
import 'package:mfu_market/model/market_event.dart';
import 'package:mfu_market/utils.dart';

void main() {
  setUp(() {
    MockDb.reset();
  });

  group('AuthController', () {
    test('1. Login with correct password should return the user', () async {
      final user = await AuthController().login('vendor', 'vendor123');
      expect(user.username, 'vendor');
      expect(user.role, 'vendor');
    });

    test('2. Login with wrong password should throw', () async {
      await expectLater(
          AuthController().login('vendor', 'wrong'), throwsException);
    });

    test('3. Register should create a new vendor', () async {
      final auth = AuthController();
      final user = await auth.register('newvendor', 'secret1');
      expect(user.role, 'vendor');
      final again = await auth.login('newvendor', 'secret1');
      expect(again.id, user.id);
    });

    test('4. Register with a taken username should throw', () async {
      await expectLater(
          AuthController().register('vendor', 'secret1'), throwsException);
    });
  });

  group('StallController', () {
    late StallController stalls;

    setUp(() {
      stalls = StallController();
    });

    test('1. First sales date should have 3 free stalls', () async {
      final free = await stalls.fetchFreeStalls(date: nextSaturday());
      expect(free.map((s) => s.code).toList(), ['A-03', 'A-07', 'B-02']);
    });

    test('2. Filter by zone and type should narrow the list', () async {
      final zoneB =
          await stalls.fetchFreeStalls(date: nextSaturday(), zone: 'B');
      expect(zoneB.map((s) => s.code).toList(), ['B-02']);

      final food =
          await stalls.fetchFreeStalls(date: nextSaturday(), type: 'Food');
      expect(food.map((s) => s.code).toList(), ['A-03', 'A-07']);
    });

    test('3. Another date should have every stall free', () async {
      final free = await stalls.fetchFreeStalls(date: addDays(nextSaturday(), 28));
      expect(free.length, 10);
    });
  });

  group('BookingController', () {
    late BookingController bookings;
    late StallController stalls;

    setUp(() {
      bookings = BookingController();
      stalls = StallController();
    });

    test('1. Vendor should see only own bookings', () async {
      final mine = await bookings.fetchMyBookings(1);
      expect(mine.length, 3);
    });

    test('2. Request booking should create a pending booking and block the stall',
        () async {
      final date = nextSaturday();
      final free = await stalls.fetchFreeStalls(date: date);
      await bookings.requestBooking(1, free.first, date);

      final mine = await bookings.fetchMyBookings(1);
      expect(mine.last.stallCode, 'A-03');
      expect(mine.last.status, 'pending');

      final after = await stalls.fetchFreeStalls(date: date);
      expect(after.length, 2);
    });

    test('3. Booking a taken stall should throw', () async {
      final date = nextSaturday();
      final free = await stalls.fetchFreeStalls(date: date);
      await bookings.requestBooking(1, free.first, date);
      await expectLater(
          bookings.requestBooking(5, free.first, date), throwsException);
    });

    test('4. Booking today or a past date should throw', () async {
      final free = await stalls.fetchFreeStalls(date: nextSaturday());
      await expectLater(
          bookings.requestBooking(1, free.first, today()), throwsException);
    });

    test('5. Cancel should set status to cancelled and free the stall', () async {
      final date = nextSaturday();
      final free = await stalls.fetchFreeStalls(date: date);
      await bookings.requestBooking(1, free.first, date);
      final mine = await bookings.fetchMyBookings(1);
      final booking = mine.last;

      expect(bookings.canCancel(booking), isTrue);
      await bookings.cancelBooking(booking.id);
      expect(booking.status, 'cancelled');

      final after = await stalls.fetchFreeStalls(date: date);
      expect(after.length, 3);
    });

    test('6. Rejected and past bookings cannot be cancelled', () async {
      final mine = await bookings.fetchMyBookings(1);
      final rejected = mine.firstWhere((b) => b.status == 'rejected');
      final past = mine.firstWhere((b) => b.bookingDate.isBefore(today()));
      expect(bookings.canCancel(rejected), isFalse);
      expect(bookings.canCancel(past), isFalse);
      await expectLater(bookings.cancelBooking(past.id), throwsException);
    });
  });

  group('Pricing and events', () {
    test('1. Total should be price + booking fee + 7% VAT', () {
      expect(vatFor(120), closeTo(9.45, 0.001));
      expect(totalFor(120), closeTo(144.45, 0.001));
    });

    test('2. Request booking should keep the vendor details', () async {
      final stalls = StallController();
      final date = nextSaturday();
      final free = await stalls.fetchFreeStalls(date: date);
      final booking = await BookingController().requestBooking(
        1,
        free.first,
        date,
        businessName: 'Clay & Fern',
        contactName: 'Maya',
        email: 'maya@example.com',
      );
      expect(booking.businessName, 'Clay & Fern');
      expect(booking.reference.endsWith('-A03'), isTrue);
    });

    test('3. Two demo markets on different dates', () {
      final events = buildMarketEvents();
      expect(events.length, 2);
      expect(events[1].date.difference(events[0].date).inDays, 7);
    });
  });
}
