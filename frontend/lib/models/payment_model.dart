class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.slipUrl,
    this.createdAt,
  });

  final int? id;
  final int? bookingId;
  final double amount;
  final String slipUrl;
  final DateTime? createdAt;

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: _toInt(json['id']),
      bookingId: _toInt(json['booking_id'] ?? json['bookingId']),
      amount: _toDouble(json['amount']),
      slipUrl: (json['slip_url'] ?? json['slipUrl'] ?? '').toString(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
    );
  }

  static int? _toInt(Object? value) =>
      value == null ? null : int.tryParse(value.toString());

  static double _toDouble(Object? value) =>
      value == null ? 0 : double.tryParse(value.toString()) ?? 0;
}
