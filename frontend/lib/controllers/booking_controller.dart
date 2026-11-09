import 'package:flutter/foundation.dart';

import '../models/booking_model.dart';
import '../models/stall_model.dart';
import '../services/api_service.dart';

class BookingController extends ChangeNotifier {
  BookingController(this._api) : selectedDate = _dateOnly(DateTime.now());

  final ApiService _api;
  DateTime selectedDate;
  String? selectedCategory;
  List<StallModel> stalls = const [];
  List<BookingModel> bookings = const [];
  bool isLoadingStalls = false;
  bool isLoadingBookings = false;
  String? errorMessage;

  Future<void> load() async {
    errorMessage = null;
    await Future.wait([loadStalls(), loadBookings()]);
  }

  Future<void> loadStalls() async {
    isLoadingStalls = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await _api.getStallStatus(date: selectedDate);
      final items = response['stalls'];
      stalls = items is List
          ? items
                .whereType<Map>()
                .map(
                  (item) =>
                      StallModel.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList(growable: false)
          : const [];
    } catch (error) {
      errorMessage = _messageFor(error);
    } finally {
      isLoadingStalls = false;
      notifyListeners();
    }
  }

  Future<void> loadBookings() async {
    isLoadingBookings = true;
    notifyListeners();
    try {
      bookings = (await _api.getMyBookings())
          .map(BookingModel.fromJson)
          .toList(growable: false);
    } catch (error) {
      errorMessage = _messageFor(error);
    } finally {
      isLoadingBookings = false;
      notifyListeners();
    }
  }

  Future<void> setDate(DateTime date) async {
    selectedDate = _dateOnly(date);
    await loadStalls();
  }

  void selectCategory(String? category) {
    selectedCategory = category;
    notifyListeners();
  }

  Future<BookingModel> createBooking(StallModel stall) async {
    errorMessage = null;
    notifyListeners();
    try {
      final response = await _api.createBooking(
        stallId: stall.id,
        bookingDate: selectedDate,
      );
      final booking = response['booking'];
      if (booking is! Map) {
        throw const FormatException('The server returned no booking record.');
      }
      final model = BookingModel.fromJson(Map<String, dynamic>.from(booking));
      await Future.wait([loadStalls(), loadBookings()]);
      return model;
    } catch (error) {
      errorMessage = _messageFor(error);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cancelBooking(BookingModel booking) async {
    if (booking.id == null) return;
    errorMessage = null;
    notifyListeners();
    try {
      await _api.cancelBooking(bookingId: booking.id!);
      await Future.wait([loadBookings(), loadStalls()]);
    } catch (error) {
      errorMessage = _messageFor(error);
      notifyListeners();
      rethrow;
    }
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static String _messageFor(Object error) => error is ApiException
      ? error.message
      : 'Could not load the booking data. Please try again.';
}
