import 'package:admin_module/data/admin_store.dart';
import 'package:admin_module/models/booking.dart';
import 'package:admin_module/models/payment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Payments in AdminStore', () {
    test('every booking has a payment, pending bookings await a slip check', () {
      final store = AdminStore();
      for (final b in store.bookings) {
        expect(store.paymentFor(b.id), isNotNull);
      }
      final pending = store.bookingsByStatus(BookingStatus.pending).first;
      expect(store.paymentFor(pending.id)!.status, PaymentStatus.pending);
    });

    test('approving verifies the payment and counts it as revenue', () {
      final store = AdminStore();
      final b = store.bookingsByStatus(BookingStatus.pending).first;
      final before = store.sum(store.approvedOnDay(b.bookingDate));
      final pendingBefore = store.pendingTotal;
      final collectedBefore = store.collectedTotal;

      expect(store.approve(b.id), isTrue);

      final payment = store.paymentFor(b.id)!;
      expect(payment.status, PaymentStatus.paid);
      expect(payment.paidAt, isNotNull);
      expect(store.sum(store.approvedOnDay(b.bookingDate)), before + b.price);
      expect(store.pendingTotal, pendingBefore - b.price);
      expect(store.collectedTotal, collectedBefore + b.price);
    });

    test('rejecting fails the payment with a reason and adds no revenue', () {
      final store = AdminStore();
      final b = store.bookingsByStatus(BookingStatus.pending).first;
      final before = store.sum(store.approvedOnDay(b.bookingDate));

      store.reject(b.id, reason: 'Amount does not match');

      final payment = store.paymentFor(b.id)!;
      expect(payment.status, PaymentStatus.failed);
      expect(payment.rejectReason, 'Amount does not match');
      expect(store.sum(store.approvedOnDay(b.bookingDate)), before);
    });

    test('payment account can be updated', () {
      final store = AdminStore();
      store.updatePaymentSettings(
          promptPayId: '0899999999', accountName: 'New Owner');
      expect(store.promptPayId, '0899999999');
      expect(store.accountName, 'New Owner');
    });
  });
}
