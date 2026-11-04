import 'package:mfu_market/model/booking_model.dart';
import 'package:mfu_market/model/stall_model.dart';
import 'package:mfu_market/model/user_model.dart';
import 'package:mfu_market/utils.dart';

class MockDb {
  static List<UserModel> users = [];
  static Map<String, String> passwords = {};
  static List<StallModel> stalls = [];
  static List<BookingModel> bookings = [];
  static int nextUserId = 100;
  static int nextBookingId = 1;

  static void reset() {
    users = [
      UserModel(id: 1, username: 'vendor', role: 'vendor'),
      UserModel(id: 2, username: 'admin', role: 'admin'),
    ];
    passwords = {'vendor': 'vendor123', 'admin': 'admin123'};
    nextUserId = 100;
    nextBookingId = 1;

    stalls = [
      _stall(1, 'A-01', '2x3', 150, 'Food'),
      _stall(2, 'A-02', '2x2', 100, 'Goods'),
      _stall(3, 'A-03', '2x3', 150, 'Food'),
      _stall(4, 'A-05', '2x2', 120, 'Drinks'),
      _stall(5, 'A-07', '2x2', 120, 'Food'),
      _stall(6, 'B-01', '2x2', 100, 'Goods'),
      _stall(7, 'B-02', '2x2', 120, 'Drinks'),
      _stall(8, 'B-04', '2x3', 150, 'Food'),
      _stall(9, 'C-01', '2x2', 100, 'Goods'),
      _stall(10, 'C-02', '2x3', 120, 'Goods'),
    ];

    bookings = [];
    final firstSale = nextSaturday();

    for (final code in ['A-01', 'A-02', 'A-05', 'B-01', 'B-04', 'C-01', 'C-02']) {
      addBooking(50, code, firstSale, 'approved');
    }
    addBooking(1, 'B-02', addDays(firstSale, 7), 'approved');
    addBooking(1, 'C-01', addDays(firstSale, 14), 'rejected');
    addBooking(1, 'A-07', addDays(firstSale, -14), 'approved');
  }

  static StallModel _stall(
      int id, String code, String size, double price, String type) {
    final zone = code.substring(0, 1);
    return StallModel(
      id: id,
      code: code,
      zone: zone,
      size: size,
      pricePerDay: price,
      productType: type,
      covered: zone != 'C',
      power: type != 'Goods',
      note: zone == 'A'
          ? 'Covered pitch · right by the main aisle'
          : zone == 'B'
              ? 'Covered pitch · quiet side lane'
              : 'Open-air pitch · by the garden',
    );
  }

  static BookingModel addBooking(
    int userId,
    String stallCode,
    DateTime date,
    String status, {
    String businessName = '',
    String contactName = '',
    String email = '',
  }) {
    final stall = stalls.firstWhere((s) => s.code == stallCode);
    final booking = BookingModel(
      id: nextBookingId++,
      userId: userId,
      stallId: stall.id,
      stallCode: stall.code,
      bookingDate: date,
      price: stall.pricePerDay,
      status: status,
      businessName: businessName,
      contactName: contactName,
      email: email,
    );
    bookings.add(booking);
    return booking;
  }

  static Set<int> bookedStallIds(DateTime date) {
    return bookings
        .where((b) =>
            sameDay(b.bookingDate, date) &&
            (b.status == 'pending' || b.status == 'approved'))
        .map((b) => b.stallId)
        .toSet();
  }
}
