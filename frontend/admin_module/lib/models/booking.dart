/// Mirrors the `bookings` table: id, user_id, stall_id, booking_date, price, status
enum BookingStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected'),
  cancelled('Cancelled');

  const BookingStatus(this.label);
  final String label;
}

class Booking {
  const Booking({
    required this.id,
    required this.userName,
    required this.stallId,
    required this.stallCode,
    required this.bookingDate,
    required this.price,
    required this.status,
  });

  final int id;
  final String userName;
  final int stallId;
  final String stallCode;
  final DateTime bookingDate;
  final double price;
  final BookingStatus status;

  Booking copyWith({String? stallCode, BookingStatus? status}) {
    return Booking(
      id: id,
      userName: userName,
      stallId: stallId,
      stallCode: stallCode ?? this.stallCode,
      bookingDate: bookingDate,
      price: price,
      status: status ?? this.status,
    );
  }
}
