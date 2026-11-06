import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class AdminController extends ChangeNotifier {
  bool _isLoading = false;
  Map<String, dynamic> _analyticsData = {};
  List<dynamic> _bookingRequests = [];
  List<dynamic> _events = [];

  bool get isLoading => _isLoading;
  Map<String, dynamic> get analyticsData => _analyticsData;
  List<dynamic> get bookingRequests => _bookingRequests;
  List<dynamic> get events => _events;

  // ดึงข้อมูล Analytics
  Future<void> fetchAnalytics(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/analytics'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        _analyticsData = jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('Fetch Analytics Error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ดึงรายการ Request การจอง
  Future<void> fetchBookingRequests(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/requests'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as List<dynamic>;
        _bookingRequests = decoded.map((request) {
          final booking = Map<String, dynamic>.from(request as Map);
          // The API names this field booking_id; the view uses id internally.
          booking['id'] ??= booking['booking_id'];
          return booking;
        }).toList();
      }
    } catch (e) {
      debugPrint('Fetch Requests Error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ดึงรายการ Events ทั้งหมด
  Future<void> fetchEvents() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/events'));

      if (response.statusCode == 200) {
        _events = jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Fetch Events Error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ✅ เปลี่ยนสถานะการจอง (อนุมัติ / ปฏิเสธ)
  Future<bool> updateRequestStatus(
    String token,
    dynamic bookingId,
    String status,
  ) async {
    try {
      final res = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/admin/requests/$bookingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      );

      if (res.statusCode == 200) {
        // 🟢 1. อัปเดตสถานะในตัวแปร _bookingRequests ทันที
        final index = _bookingRequests.indexWhere(
          (req) => '${req['id'] ?? req['booking_id']}' == '$bookingId',
        );
        if (index != -1) {
          _bookingRequests[index]['status'] = status;
        }

        // 🟢 2. แจ้ง Flutter ให้ Rebuild หน้าจอทันที (ปุ่ม Reject/Approve จะหายไป และ PENDING จะเปลี่ยนเป็น APPROVED)
        notifyListeners();

        // 3. ดึงข้อมูลอัปเดตจาก Server ซ้ำอีกรอบ
        fetchBookingRequests(token);
        fetchAnalytics(token);
        return true;
      }
    } catch (e) {
      debugPrint('Update Status Error: $e');
    }
    return false;
  }

  // ✅ ลบ Event
  Future<bool> deleteEvent(String token, dynamic eventId) async {
    try {
      final res = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/admin/events/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Delete Event Code: ${res.statusCode}');
      debugPrint('Delete Event Response: ${res.body}');

      if (res.statusCode == 200) {
        await fetchEvents(); // โหลดรายการ Events ใหม่ทันที
        return true;
      }
    } catch (e) {
      debugPrint('Delete Event Error: $e');
    }
    return false;
  }

  // สร้าง Event ใหม่
  Future<bool> createEvent({
    required String token,
    required String name,
    required String location,
    required double price,
    required int stallsLeft,
    File? imageFile,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/admin/events'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['name'] = name;
      request.fields['location'] = location;
      request.fields['price'] = price.toString();
      request.fields['stalls_left'] = stallsLeft.toString();

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        await fetchEvents();
        return true;
      }
    } catch (e) {
      debugPrint('Create Event Error: $e');
    }
    return false;
  }
}
