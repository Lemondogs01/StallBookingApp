class BookingModel {
  const BookingModel({
    required this.id,
    required this.bookingCode,
    required this.stallId,
    required this.category,
    required this.bookingDate,
    required this.price,
    required this.status,
    this.createdAt,
    this.slipUrl,
    this.paymentDate,
    this.shopName,
    this.realName,
    this.phone,
    this.paidAmount,
  });

  final int? id;
  final String bookingCode;
  final String stallId;
  final String category;
  final DateTime bookingDate;
  final double price;
  final String status;
  final DateTime? createdAt;
  final String? slipUrl;
  final DateTime? paymentDate;
  final String? shopName;
  final String? realName;
  final String? phone;
  final double? paidAmount;

  String get categoryLabel => switch (category) {
    'food' => 'Food & Drinks',
    'fashion' => 'Fashion',
    'general' => 'General Goods',
    _ => category,
  };

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final dateText = (json['booking_date'] ?? '').toString();
    return BookingModel(
      id: _toInt(json['id']),
      bookingCode: (json['booking_code'] ?? json['bookingCode'] ?? '')
          .toString(),
      stallId: (json['stall_id'] ?? json['stallId'] ?? '').toString(),
      category: (json['category'] ?? json['stall_category'] ?? '').toString(),
      bookingDate: DateTime.tryParse(dateText) ?? DateTime.now(),
      price: _toDouble(json['price']),
      status: (json['status'] ?? 'pending').toString(),
      createdAt: _toDate(json['created_at'] ?? json['createdAt']),
      slipUrl: _nullableString(json['slip_url'] ?? json['slipUrl']),
      paymentDate: _toDate(json['payment_date'] ?? json['paymentDate']),
      shopName: _nullableString(json['shop_name'] ?? json['shopName']),
      realName: _nullableString(json['real_name'] ?? json['realName']),
      phone: _nullableString(json['phone']),
      paidAmount: _toNullableDouble(
        json['paid_amount'] ?? json['payment_amount'],
      ),
    );
  }

  static int? _toInt(Object? value) =>
      value == null ? null : int.tryParse(value.toString());

  static double _toDouble(Object? value) =>
      value == null ? 0 : double.tryParse(value.toString()) ?? 0;

  static double? _toNullableDouble(Object? value) =>
      value == null ? null : double.tryParse(value.toString());

  static DateTime? _toDate(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString());

  static String? _nullableString(Object? value) =>
      value == null || value.toString().isEmpty ? null : value.toString();
}
