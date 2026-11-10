import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_market_app/models/booking_model.dart';
import 'package:mfu_market_app/models/admin_analytics_model.dart';
import 'package:mfu_market_app/models/payment_model.dart';
import 'package:mfu_market_app/models/stall_model.dart';
import 'package:mfu_market_app/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('reads backend fields and does not add an email field', () {
      final user = UserModel.fromJson({
        'id': 7,
        'username': 'vendor7',
        'role': 'vendor',
        'shop_name': 'Tea Stand',
        'real_name': 'A Vendor',
        'phone': '0800000000',
        'profile_image': '/uploads/profiles/new.png',
      });

      expect(user.id, 7);
      expect(user.username, 'vendor7');
      expect(user.profileImage, '/uploads/profiles/new.png');
      expect(user.toJson().containsKey('email'), isFalse);
    });

    test('accepts camelCase fields and recognizes an administrator', () {
      final user = UserModel.fromJson({
        'id': '9',
        'username': 'market-admin',
        'role': 'admin',
        'shopName': 'Market Office',
        'realName': 'Market Admin',
        'phone': '0800000000',
        'profileImage': '/uploads/profiles/admin.png',
        'createdAt': '2026-03-04T10:00:00Z',
      });

      expect(user.id, 9);
      expect(user.isAdmin, isTrue);
      expect(user.shopName, 'Market Office');
      expect(user.createdAt, DateTime.utc(2026, 3, 4, 10));
      expect(user.toJson()['created_at'], '2026-03-04T10:00:00.000Z');
    });
  });

  group('StallModel', () {
    test('parses an available stall and a numeric price', () {
      final stall = StallModel.fromJson({
        'stall_id': 'A12',
        'category': 'food',
        'price': '250.00',
        'status': 'available',
      });

      expect(stall.id, 'A12');
      expect(stall.price, 250);
      expect(stall.isAvailable, isTrue);
      expect(stall.categoryLabel, 'Food & Drinks');
    });

    test(
      'maps other category labels and handles missing or invalid fields',
      () {
        expect(
          StallModel.fromJson({'category': 'fashion'}).categoryLabel,
          'Fashion',
        );
        expect(
          StallModel.fromJson({'category': 'general'}).categoryLabel,
          'General Goods',
        );
        final unknown = StallModel.fromJson({
          'stall_id': 'X1',
          'category': 'seasonal',
          'price': 'invalid',
        });
        expect(unknown.id, 'X1');
        expect(unknown.categoryLabel, 'seasonal');
        expect(unknown.price, 0);
        expect(unknown.status, 'available');
      },
    );

    test('parses an approved stall booking audit record', () {
      final stall = StallModel.fromJson({
        'id': 'A2',
        'category': 'fashion',
        'price': 300,
        'status': 'approved',
        'booking': {
          'id': '12',
          'status': 'approved',
          'booking_code': 'BK-20990101-A1B2',
          'booking_date': '2099-01-01',
          'price': '300.00',
          'shopName': 'Hat Shop',
          'real_name': 'Vendor Name',
          'phone': '0800000000',
          'slipUrl': '/uploads/slips/paid.png',
          'paid_amount': '300.00',
          'approved_by_username': 'admin',
          'approved_by_name': 'Market Admin',
          'approved_at': '2099-01-01T10:00:00Z',
        },
      });

      expect(stall.booking?.id, 12);
      expect(stall.booking?.bookingCode, 'BK-20990101-A1B2');
      expect(stall.booking?.shopName, 'Hat Shop');
      expect(stall.booking?.vendorName, 'Vendor Name');
      expect(stall.booking?.vendorPhone, '0800000000');
      expect(stall.booking?.slipUrl, '/uploads/slips/paid.png');
      expect(stall.booking?.approvedByUsername, 'admin');
      expect(stall.booking?.approvedByName, 'Market Admin');
      expect(stall.booking?.approvedAt, DateTime.utc(2099, 1, 1, 10));
    });
  });

  group('BookingModel and PaymentModel', () {
    test('reads the current slip URL from a booking response', () {
      final booking = BookingModel.fromJson({
        'id': 9,
        'booking_code': 'BK-20261110-A1B2',
        'stall_id': 'A12',
        'stall_category': 'food',
        'booking_date': '2026-11-10',
        'price': '250.00',
        'status': 'pending',
        'slip_url': '/uploads/slips/replaced.png',
        'payment_amount': '250.00',
      });

      expect(booking.slipUrl, '/uploads/slips/replaced.png');
      expect(booking.paidAmount, 250);
      expect(booking.categoryLabel, 'Food & Drinks');
    });

    test('supports alternate response keys and safe defaults', () {
      final booking = BookingModel.fromJson({
        'id': 'not-a-number',
        'bookingCode': 'BK-ALT',
        'stallId': 'B2',
        'category': 'fashion',
        'booking_date': 'invalid-date',
        'price': 'invalid',
        'status': null,
        'createdAt': '2026-03-04T10:00:00Z',
        'slipUrl': '',
        'paymentDate': '2026-03-04T11:00:00Z',
        'shopName': 'Hat Shop',
        'realName': 'Vendor Name',
        'payment_amount': '275.50',
      });

      expect(booking.id, isNull);
      expect(booking.bookingCode, 'BK-ALT');
      expect(booking.stallId, 'B2');
      expect(booking.categoryLabel, 'Fashion');
      expect(booking.price, 0);
      expect(booking.status, 'pending');
      expect(booking.createdAt, DateTime.utc(2026, 3, 4, 10));
      expect(booking.slipUrl, isNull);
      expect(booking.paymentDate, DateTime.utc(2026, 3, 4, 11));
      expect(booking.shopName, 'Hat Shop');
      expect(booking.realName, 'Vendor Name');
      expect(booking.paidAmount, 275.5);
    });

    test('uses the other booking category labels', () {
      expect(
        BookingModel.fromJson({'category': 'general'}).categoryLabel,
        'General Goods',
      );
      expect(
        BookingModel.fromJson({'category': 'seasonal'}).categoryLabel,
        'seasonal',
      );
    });

    test('parses a payment returned after upload', () {
      final payment = PaymentModel.fromJson({
        'id': 31,
        'booking_id': 9,
        'amount': '250.00',
        'slip_url': '/uploads/slips/new.png',
      });

      expect(payment.bookingId, 9);
      expect(payment.amount, 250);
      expect(payment.slipUrl, '/uploads/slips/new.png');
    });

    test('handles camelCase payment keys and invalid numeric values', () {
      final payment = PaymentModel.fromJson({
        'id': 'invalid',
        'bookingId': '9',
        'amount': 'invalid',
        'slipUrl': '/uploads/slips/alt.png',
        'created_at': 'invalid-date',
      });

      expect(payment.id, isNull);
      expect(payment.bookingId, 9);
      expect(payment.amount, 0);
      expect(payment.slipUrl, '/uploads/slips/alt.png');
      expect(payment.createdAt, isNull);
    });
  });

  group('AdminAnalyticsModel', () {
    test('parses revenue totals, category values, and date breakdowns', () {
      final analytics = AdminAnalyticsModel.fromJson({
        'totalRevenue': '1200.50',
        'selectedDateRevenue': 250,
        'categoryRevenue': {'food': '250', 'fashion': 'invalid'},
        'dailyBreakdown': [
          {'date': '2026-03-04', 'revenue': '250'},
          'ignored',
        ],
        'monthlyBreakdown': [
          {'month': '2026-03-01', 'revenue': 1200.5},
        ],
      });

      expect(analytics.totalRevenue, 1200.5);
      expect(analytics.selectedDateRevenue, 250);
      expect(analytics.categoryRevenue, {'food': 250, 'fashion': 0});
      expect(analytics.dailyBreakdown.single.revenue, 250);
      expect(analytics.monthlyBreakdown.single.revenue, 1200.5);
    });

    test(
      'centers the selected date and fills missing days in chronological order',
      () {
        final selectedDate = DateTime(2026, 11, 10);
        final analytics = AdminAnalyticsModel.fromJson({
          'dailyBreakdown': [
            {'date': '2026-11-13', 'revenue': 130},
            {'date': '2026-11-10', 'revenue': 100},
            {'date': '2026-11-07', 'revenue': 70},
          ],
        });

        final trend = analytics.dailyTrendCenteredOn(selectedDate);

        expect(trend, hasLength(7));
        expect(trend.map((day) => day.date.day), [7, 8, 9, 10, 11, 12, 13]);
        expect(trend[3].date, selectedDate);
        expect(trend.map((day) => day.revenue), [70, 0, 0, 100, 0, 0, 130]);
      },
    );

    test('keeps the selected date centered across a year boundary', () {
      final selectedDate = DateTime(2026, 1, 1);
      final analytics = AdminAnalyticsModel.fromJson({
        'dailyBreakdown': [
          {'date': '2025-12-29', 'revenue': 20},
          {'date': '2026-01-01', 'revenue': 50},
          {'date': '2026-01-04', 'revenue': 40},
        ],
      });

      final trend = analytics.dailyTrendCenteredOn(selectedDate);

      expect(
        trend.map(
          (day) => '${day.date.year}-${day.date.month}-${day.date.day}',
        ),
        [
          '2025-12-29',
          '2025-12-30',
          '2025-12-31',
          '2026-1-1',
          '2026-1-2',
          '2026-1-3',
          '2026-1-4',
        ],
      );
      expect(trend[3].date, selectedDate);
      expect(trend[0].revenue, 20);
      expect(trend[3].revenue, 50);
      expect(trend[6].revenue, 40);
    });

    test(
      'uses empty collections and safe numeric defaults for malformed data',
      () {
        final analytics = AdminAnalyticsModel.fromJson({
          'totalRevenue': 'bad',
          'selectedDateRevenue': null,
          'categoryRevenue': 'bad',
          'dailyBreakdown': 'bad',
          'monthlyBreakdown': null,
        });

        expect(analytics.totalRevenue, 0);
        expect(analytics.selectedDateRevenue, 0);
        expect(analytics.categoryRevenue, isEmpty);
        expect(analytics.dailyBreakdown, isEmpty);
        expect(analytics.monthlyBreakdown, isEmpty);
      },
    );
  });
}
