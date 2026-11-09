import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mfu_market_app/services/api_service.dart';
import 'package:mfu_market_app/services/storage_service.dart';

const testBaseUrl = 'http://localhost:5001/api';

Map<String, dynamic> testUser({
  int id = 8,
  String role = 'vendor',
  String profileImage = '/uploads/profiles/vendor.png',
}) => {
  'id': id,
  'username': 'vendor$id',
  'role': role,
  'shop_name': 'Tea Stand',
  'real_name': 'Vendor $id',
  'phone': '0800000000',
  'profile_image': profileImage,
};

Map<String, dynamic> testBooking({int id = 10}) => {
  'id': id,
  'booking_code': 'BK-20990101-A1B2',
  'stall_id': 'A1',
  'stall_category': 'food',
  'booking_date': '2099-01-01',
  'price': '250.00',
  'status': 'pending',
  'slip_url': '/uploads/slips/current.png',
  'payment_amount': '250.00',
};

Map<String, dynamic> testStall({String status = 'available'}) => {
  'stall_id': 'A1',
  'category': 'food',
  'price': '250.00',
  'status': status,
};

http.Response testJsonResponse(Object body, [int statusCode = 200]) =>
    http.Response(jsonEncode(body), statusCode);

ApiService testApi(Future<http.Response> Function(http.Request) handle) =>
    ApiService(baseUrl: testBaseUrl, client: MockClient(handle));

class MemoryStorage extends StorageService {
  MemoryStorage({this.token, this.failClear = false}) : super();

  String? token;
  bool failClear;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> saveToken(String value) async {
    token = value;
  }

  @override
  Future<void> clearToken() async {
    if (failClear) throw StateError('storage unavailable');
    token = null;
  }
}
