import 'package:flutter/foundation.dart';

import '../models/booking.dart';
import '../models/stall.dart';
import '../utils/format.dart';

/// In-memory mock data for Sprint 2 (no front-back connection yet).
/// In Sprint 3 this is replaced by Models + Controllers that call the API.
class AdminStore extends ChangeNotifier {
  AdminStore() {
    _seed();
  }

  static const zones = ['A', 'B', 'C', 'D'];
  static const productTypes = [
    'Food',
    'Drinks',
    'Clothing',
    'Accessories',
    'Handmade',
    'Other',
  ];

  final List<Stall> _stalls = [];
  final List<Booking> _bookings = [];
  int _nextStallId = 1;
  int _nextBookingId = 1;

  List<Stall> get stalls => List.unmodifiable(_stalls);
  List<Booking> get bookings => List.unmodifiable(_bookings);

  // ---------------------------------------------------------------- stalls

  bool codeExists(String code, {int? excludeId}) => _stalls.any(
      (s) => s.code.toLowerCase() == code.toLowerCase() && s.id != excludeId);

  void addStall(Stall draft) {
    _stalls.add(draft.copyWith(id: _nextStallId++));
    notifyListeners();
  }

  void updateStall(Stall updated) {
    final i = _stalls.indexWhere((s) => s.id == updated.id);
    if (i == -1) return;
    _stalls[i] = updated;
    for (var j = 0; j < _bookings.length; j++) {
      if (_bookings[j].stallId == updated.id) {
        _bookings[j] = _bookings[j].copyWith(stallCode: updated.code);
      }
    }
    notifyListeners();
  }

  /// Returns false when the stall still has pending/approved bookings
  /// today or in the future.
  bool deleteStall(int id) {
    final today = dateOnly(DateTime.now());
    final inUse = _bookings.any((b) =>
        b.stallId == id &&
        !b.bookingDate.isBefore(today) &&
        (b.status == BookingStatus.pending ||
            b.status == BookingStatus.approved));
    if (inUse) return false;
    _stalls.removeWhere((s) => s.id == id);
    notifyListeners();
    return true;
  }

  // -------------------------------------------------------------- bookings

  List<Booking> bookingsByStatus(BookingStatus status) {
    final list = _bookings.where((b) => b.status == status).toList();
    list.sort((a, b) => status == BookingStatus.pending
        ? a.bookingDate.compareTo(b.bookingDate)
        : b.bookingDate.compareTo(a.bookingDate));
    return list;
  }

  int countByStatus(BookingStatus status) =>
      _bookings.where((b) => b.status == status).length;

  /// Approve a pending request. Fails if the same stall is already approved
  /// for that date (prevents the double-booking problem).
  bool approve(int id) {
    final i = _bookings.indexWhere((b) => b.id == id);
    if (i == -1) return false;
    final target = _bookings[i];
    final conflict = _bookings.any((b) =>
        b.id != id &&
        b.stallId == target.stallId &&
        b.status == BookingStatus.approved &&
        dateOnly(b.bookingDate) == dateOnly(target.bookingDate));
    if (conflict) return false;
    _bookings[i] = target.copyWith(status: BookingStatus.approved);
    notifyListeners();
    return true;
  }

  void reject(int id) {
    final i = _bookings.indexWhere((b) => b.id == id);
    if (i == -1) return;
    _bookings[i] = _bookings[i].copyWith(status: BookingStatus.rejected);
    notifyListeners();
  }

  // --------------------------------------------------------------- revenue
  // Revenue = price of approved bookings, grouped by sales (booking) date.

  List<Booking> _approvedWhere(bool Function(DateTime d) test) => _bookings
      .where((b) => b.status == BookingStatus.approved && test(b.bookingDate))
      .toList();

  List<Booking> approvedOnDay(DateTime day) =>
      _approvedWhere((d) => dateOnly(d) == dateOnly(day));

  List<Booking> approvedInMonth(int year, int month) =>
      _approvedWhere((d) => d.year == year && d.month == month);

  double sum(List<Booking> list) =>
      list.fold<double>(0, (total, b) => total + b.price);

  // ------------------------------------------------------------------ seed

  void _seed() {
    const sizes = ['2x2 m', '3x3 m', '3x4 m'];
    const prices = [120.0, 180.0, 250.0];
    for (var zi = 0; zi < zones.length; zi++) {
      for (var n = 1; n <= 3; n++) {
        _stalls.add(Stall(
          id: _nextStallId++,
          code: '${zones[zi]}$n',
          zone: zones[zi],
          size: sizes[n - 1],
          pricePerDay: prices[n - 1] + zi * 20,
          productType: productTypes[(zi * 3 + n) % productTypes.length],
          status: (zi == 3 && n == 3)
              ? StallStatus.unavailable
              : StallStatus.available,
        ));
      }
    }

    const users = [
      'somchai', 'malee', 'john_doe', 'napat', 'ploy', 'kittisak', 'aung',
    ];
    final today = dateOnly(DateTime.now());

    void add(Stall s, DateTime date, BookingStatus status, int userSeed) {
      _bookings.add(Booking(
        id: _nextBookingId++,
        userName: users[userSeed % users.length],
        stallId: s.id,
        stallCode: s.code,
        bookingDate: date,
        price: s.pricePerDay,
        status: status,
      ));
    }

    // ~5 months of history so daily and monthly revenue both have data
    for (var d = 150; d >= 1; d--) {
      final count = (d % 3) + (d % 7 == 0 ? 1 : 0);
      for (var k = 0; k < count; k++) {
        final stall = _stalls[(d + k * 5) % _stalls.length];
        final status = (d + k) % 11 == 0
            ? BookingStatus.cancelled
            : (d + k) % 13 == 0
                ? BookingStatus.rejected
                : BookingStatus.approved;
        add(stall, today.subtract(Duration(days: d)), status, d + k);
      }
    }

    // today
    add(_stalls[0], today, BookingStatus.approved, 1);
    add(_stalls[4], today, BookingStatus.approved, 2);

    // upcoming
    add(_stalls[7], today.add(const Duration(days: 2)),
        BookingStatus.approved, 3);
    for (var i = 1; i <= 6; i++) {
      add(_stalls[(i * 2) % _stalls.length], today.add(Duration(days: i)),
          BookingStatus.pending, i + 2);
    }
  }
}

final adminStore = AdminStore();
