import 'package:flutter/foundation.dart';

import '../models/admin_analytics_model.dart';
import '../models/booking_model.dart';
import '../models/stall_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AdminController extends ChangeNotifier {
  AdminController(this._api) : selectedDate = _dateOnly(DateTime.now());

  final ApiService _api;
  DateTime selectedDate;
  AdminAnalyticsModel? analytics;
  List<BookingModel> pendingBookings = const [];
  List<StallModel> stalls = const [];
  List<UserModel> users = const [];
  bool isLoadingDashboard = false;
  bool isLoadingUsers = false;
  String? errorMessage;
  int _usersRequestId = 0;

  Future<void> loadDashboard() async {
    isLoadingDashboard = true;
    errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.getAdminAnalytics(date: selectedDate),
        _api.getPendingBookings(),
        _api.getStallStatus(date: selectedDate),
      ]);
      analytics = AdminAnalyticsModel.fromJson(
        results[0] as Map<String, dynamic>,
      );
      pendingBookings = (results[1] as List<Map<String, dynamic>>)
          .map(BookingModel.fromJson)
          .toList(growable: false);
      final stallResponse = results[2] as Map<String, dynamic>;
      final stallItems = stallResponse['stalls'];
      stalls = stallItems is List
          ? stallItems
                .whereType<Map>()
                .map(
                  (item) =>
                      StallModel.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList(growable: false)
          : const [];
    } catch (error) {
      errorMessage = error is ApiException
          ? error.message
          : 'Could not load the dashboard.';
    } finally {
      isLoadingDashboard = false;
      notifyListeners();
    }
  }

  Future<void> setDate(DateTime date) async {
    selectedDate = _dateOnly(date);
    await loadDashboard();
  }

  Future<void> verifyBooking(
    BookingModel booking, {
    required bool approve,
  }) async {
    if (booking.id == null) return;
    try {
      await _api.verifyBooking(
        bookingId: booking.id!,
        status: approve ? 'approved' : 'rejected',
      );
      await loadDashboard();
    } catch (error) {
      errorMessage = error is ApiException
          ? error.message
          : 'Could not update the booking status.';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadUsers({String? query}) async {
    final requestId = ++_usersRequestId;
    isLoadingUsers = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await _api.getAdminUsers(query: query);
      if (requestId == _usersRequestId) {
        users = response.map(UserModel.fromJson).toList(growable: false);
      }
    } catch (error) {
      if (requestId == _usersRequestId) {
        errorMessage = error is ApiException
            ? error.message
            : 'Could not load the vendor list.';
      }
    } finally {
      if (requestId == _usersRequestId) {
        isLoadingUsers = false;
        notifyListeners();
      }
    }
  }

  Future<void> resetPassword(UserModel user) async {
    if (user.id == null) return;
    errorMessage = null;
    try {
      await _api.resetUserPassword(userId: user.id!);
    } catch (error) {
      errorMessage = error is ApiException
          ? error.message
          : 'Could not reset the password.';
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
