import 'package:mfu_market/controller/mock_db.dart';
import 'package:mfu_market/model/booking_model.dart';
import 'package:mfu_market/model/stall_model.dart';
import 'package:mfu_market/utils.dart';

class BookingController {
  Future<List<BookingModel>> fetchMyBookings(int userId) async {
    return MockDb.bookings.where((b) => b.userId == userId).toList();
  }

  Future<BookingModel> requestBooking(
    int userId,
    StallModel stall,
    DateTime date, {
    String businessName = '',
    String contactName = '',
    String email = '',
  }) async {
    if (!date.isAfter(today())) {
      throw Exception('Pick a sales date after today.');
    }
    if (stall.status != 'active') {
      throw Exception('This stall is not open for booking.');
    }
    if (MockDb.bookedStallIds(date).contains(stall.id)) {
      throw Exception(
          'This stall was just booked for that date. Pick another stall or date.');
    }
    return MockDb.addBooking(
      userId,
      stall.code,
      date,
      'pending',
      businessName: businessName,
      contactName: contactName,
      email: email,
    );
  }

  bool canCancel(BookingModel booking) {
    return (booking.status == 'pending' || booking.status == 'approved') &&
        booking.bookingDate.isAfter(today());
  }

  Future<void> cancelBooking(int bookingId) async {
    final booking = MockDb.bookings.firstWhere(
      (b) => b.id == bookingId,
      orElse: () => throw Exception('Booking not found.'),
    );
    if (!canCancel(booking)) {
      throw Exception('Bookings can only be cancelled before the sales date.');
    }
    booking.status = 'cancelled';
  }
}
