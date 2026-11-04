import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';

class BookingController extends ChangeNotifier {
  bool _isUploading = false;
  bool get isUploading => _isUploading;

  Future<bool> uploadSlip({
    required int bookingId,
    required double amount,
    required File imageFile,
    required String token,
  }) async {
    _isUploading = true;
    notifyListeners();

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/payments/upload'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['booking_id'] = bookingId.toString();
      request.fields['amount'] = amount.toStringAsFixed(2);

      request.files.add(
        await http.MultipartFile.fromPath(
          'slip',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        _isUploading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Upload Slip Error: $e');
    }

    _isUploading = false;
    notifyListeners();
    return false;
  }
}
