import 'package:flutter/foundation.dart';

import '../models/payment_model.dart';
import '../services/api_service.dart';

class PaymentController extends ChangeNotifier {
  PaymentController(this._api);

  final ApiService _api;
  bool isSubmitting = false;
  String? errorMessage;

  Future<PaymentModel> submitSlip({
    required int bookingId,
    required num amount,
    required Uint8List imageBytes,
    required String filename,
  }) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await _api.uploadPaymentSlip(
        bookingId: bookingId,
        amount: amount,
        imageBytes: imageBytes,
        filename: filename,
      );
      final payment = response['payment'];
      if (payment is! Map) {
        throw const FormatException('The server returned no payment record.');
      }
      return PaymentModel.fromJson(Map<String, dynamic>.from(payment));
    } catch (error) {
      errorMessage = error is ApiException
          ? error.message
          : 'Could not submit the payment slip. Please try again.';
      rethrow;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> replaceSlip({
    required int bookingId,
    required Uint8List imageBytes,
    required String filename,
  }) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _api.replacePaymentSlip(
        bookingId: bookingId,
        imageBytes: imageBytes,
        filename: filename,
      );
    } catch (error) {
      errorMessage = error is ApiException
          ? error.message
          : 'Could not replace the payment slip. Please try again.';
      rethrow;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
