class StallModel {
  const StallModel({
    required this.id,
    required this.category,
    required this.price,
    required this.status,
    this.booking,
  });

  final String id;
  final String category;
  final double price;
  final String status;
  final StallBookingSummary? booking;

  bool get isAvailable => status == 'available';

  String get categoryLabel => switch (category) {
    'food' => 'Food & Drinks',
    'fashion' => 'Fashion',
    'general' => 'General Goods',
    _ => category,
  };

  factory StallModel.fromJson(Map<String, dynamic> json) {
    final bookingJson = json['booking'];
    return StallModel(
      id: (json['id'] ?? json['stall_id'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      price: _toDouble(json['price']),
      status: (json['status'] ?? 'available').toString(),
      booking: bookingJson is Map
          ? StallBookingSummary.fromJson(Map<String, dynamic>.from(bookingJson))
          : null,
    );
  }

  static double _toDouble(Object? value) =>
      value == null ? 0 : double.tryParse(value.toString()) ?? 0;
}

class StallBookingSummary {
  const StallBookingSummary({
    required this.id,
    required this.status,
    this.bookingCode,
    this.bookingDate,
    this.price,
    this.shopName,
    this.vendorName,
    this.vendorPhone,
    this.slipUrl,
    this.paidAmount,
  });

  final int? id;
  final String status;
  final String? bookingCode;
  final DateTime? bookingDate;
  final double? price;
  final String? shopName;
  final String? vendorName;
  final String? vendorPhone;
  final String? slipUrl;
  final double? paidAmount;

  factory StallBookingSummary.fromJson(Map<String, dynamic> json) {
    return StallBookingSummary(
      id: json['id'] == null ? null : int.tryParse(json['id'].toString()),
      status: (json['status'] ?? '').toString(),
      bookingCode: _nullableString(json['bookingCode'] ?? json['booking_code']),
      bookingDate: _toDate(json['bookingDate'] ?? json['booking_date']),
      price: _toNullableDouble(json['price']),
      shopName: json['shopName']?.toString(),
      vendorName: _nullableString(json['vendorName'] ?? json['real_name']),
      vendorPhone: _nullableString(json['vendorPhone'] ?? json['phone']),
      slipUrl: json['slipUrl']?.toString(),
      paidAmount: _toNullableDouble(json['paidAmount'] ?? json['paid_amount']),
    );
  }

  static DateTime? _toDate(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString());

  static double? _toNullableDouble(Object? value) =>
      value == null ? null : double.tryParse(value.toString());

  static String? _nullableString(Object? value) =>
      value == null || value.toString().isEmpty ? null : value.toString();
}
