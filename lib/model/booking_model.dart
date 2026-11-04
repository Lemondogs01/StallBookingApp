import 'package:mfu_market/utils.dart';

class BookingModel {
  final int id;
  final int userId;
  final int stallId;
  final String stallCode;
  final DateTime bookingDate;
  final double price;
  String status;
  final String businessName;
  final String contactName;
  final String email;

  BookingModel({
    required this.id,
    required this.userId,
    required this.stallId,
    required this.stallCode,
    required this.bookingDate,
    required this.price,
    required this.status,
    this.businessName = '',
    this.contactName = '',
    this.email = '',
  });

  /// Price + booking fee + VAT.
  double get total => totalFor(price);

  /// Reservation number shown on the confirmation card, e.g. MFU-261107-A07.
  String get reference {
    final yy = (bookingDate.year % 100).toString().padLeft(2, '0');
    final mm = bookingDate.month.toString().padLeft(2, '0');
    final dd = bookingDate.day.toString().padLeft(2, '0');
    return 'MFU-$yy$mm$dd-${stallCode.replaceAll('-', '')}';
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final d = DateTime.parse(json['booking_date'] as String);
    return BookingModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      stallId: json['stall_id'] as int,
      stallCode: (json['stall_code'] as String?) ?? '',
      bookingDate: DateTime(d.year, d.month, d.day),
      price: double.parse('${json['price']}'),
      status: json['status'] as String,
      businessName: (json['business_name'] as String?) ?? '',
      contactName: (json['contact_name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
    );
  }
}
