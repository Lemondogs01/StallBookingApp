/// Mirrors the `payments` table:
/// id, booking_id, amount, payment_method, payment_status, paid_at, created_at
enum PaymentMethod {
  promptpay('PromptPay');

  const PaymentMethod(this.label);
  final String label;
}

enum PaymentStatus {
  pending('Awaiting check'), // vendor uploaded a slip, admin has not checked it
  paid('Paid'), // admin verified the slip
  failed('Rejected'), // admin rejected the slip
  refunded('Refunded'); // booking cancelled after payment

  const PaymentStatus(this.label);
  final String label;
}

class Payment {
  const Payment({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.reference,
    this.method = PaymentMethod.promptpay,
    this.paidAt,
    this.rejectReason,
  });

  final int id;
  final int bookingId;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final DateTime? paidAt;
  final DateTime createdAt;
  final String reference; // transfer reference shown on the slip
  final String? rejectReason;

  Payment copyWith({
    PaymentStatus? status,
    DateTime? paidAt,
    String? rejectReason,
  }) {
    return Payment(
      id: id,
      bookingId: bookingId,
      amount: amount,
      method: method,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt,
      reference: reference,
      rejectReason: rejectReason ?? this.rejectReason,
    );
  }
}
