import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Sends requests to the Express API. Controllers can set the current JWT with
/// [setAccessToken] after loading it from secure storage.
class ApiService {
  ApiService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUri = _normalizeBaseUri(Uri.parse(baseUrl ?? defaultBaseUrl));

  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:5001/api/';
  static const String simulatorBaseUrl = 'http://localhost:5001/api/';

  static String get defaultBaseUrl =>
      defaultTargetPlatform == TargetPlatform.android
      ? androidEmulatorBaseUrl
      : simulatorBaseUrl;

  final http.Client _client;
  final Uri _baseUri;
  String? _accessToken;

  Uri get baseUri => _baseUri;

  void setAccessToken(String? token) {
    final normalizedToken = token?.trim();
    _accessToken = normalizedToken == null || normalizedToken.isEmpty
        ? null
        : normalizedToken;
  }

  void close() => _client.close();

  /// Converts API media paths such as `/uploads/slip.jpg` into absolute URLs.
  String resolveMediaUrl(String path) {
    final parsed = Uri.parse(path);
    if (parsed.hasScheme) return parsed.toString();

    final origin = Uri(
      scheme: _baseUri.scheme,
      host: _baseUri.host,
      port: _baseUri.hasPort ? _baseUri.port : null,
    );
    return origin.resolve(path.startsWith('/') ? path : '/$path').toString();
  }

  Future<Map<String, dynamic>> healthCheck() async {
    return _asMap(await _request('GET', 'health', authenticated: false));
  }

  Future<Map<String, dynamic>> registerVendor({
    required String username,
    required String password,
    required String shopName,
    required String realName,
    required String phone,
  }) async {
    return _asMap(
      await _request(
        'POST',
        'auth/register',
        authenticated: false,
        body: {
          'username': username,
          'password': password,
          'shop_name': shopName,
          'real_name': realName,
          'phone': phone,
        },
      ),
    );
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    return _asMap(
      await _request(
        'POST',
        'auth/login',
        authenticated: false,
        body: {'username': username, 'password': password},
      ),
    );
  }

  Future<Map<String, dynamic>> getStallStatus({required DateTime date}) async {
    return _asMap(
      await _request(
        'GET',
        'stalls/status',
        queryParameters: {'date': formatApiDate(date)},
      ),
    );
  }

  Future<Map<String, dynamic>> createBooking({
    required String stallId,
    required DateTime bookingDate,
  }) async {
    return _asMap(
      await _request(
        'POST',
        'bookings',
        body: {'stall_id': stallId, 'booking_date': formatApiDate(bookingDate)},
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getMyBookings() async {
    return _asMapList(await _request('GET', 'bookings/my'));
  }

  Future<Map<String, dynamic>> cancelBooking({required int bookingId}) async {
    return _asMap(await _request('PUT', 'bookings/$bookingId/cancel'));
  }

  Future<Map<String, dynamic>> uploadPaymentSlip({
    required int bookingId,
    required num amount,
    required Uint8List imageBytes,
    required String filename,
  }) async {
    final image = _prepareImage(imageBytes, filename);
    final request = http.MultipartRequest('POST', _uri('payments'))
      ..headers.addAll(_headers())
      ..fields['booking_id'] = bookingId.toString()
      ..fields['amount'] = amount.toString()
      ..files.add(
        http.MultipartFile.fromBytes(
          'slip',
          image.bytes,
          filename: image.filename,
          contentType: image.contentType,
        ),
      );

    return _asMap(await _send(request));
  }

  Future<Map<String, dynamic>> replacePaymentSlip({
    required int bookingId,
    required Uint8List imageBytes,
    required String filename,
  }) async {
    final image = _prepareImage(imageBytes, filename);
    final request =
        http.MultipartRequest('PUT', _uri('payments/$bookingId/slip'))
          ..headers.addAll(_headers())
          ..files.add(
            http.MultipartFile.fromBytes(
              'slip',
              image.bytes,
              filename: image.filename,
              contentType: image.contentType,
            ),
          );

    return _asMap(await _send(request));
  }

  Future<Map<String, dynamic>> getProfile() async {
    return _asMap(await _request('GET', 'users/profile'));
  }

  Future<Map<String, dynamic>> updateProfile({
    required String shopName,
    required String realName,
    required String phone,
    Uint8List? profileImageBytes,
    String? profileImageFilename,
  }) async {
    final fields = {
      'shop_name': shopName,
      'real_name': realName,
      'phone': phone,
    };

    if (profileImageBytes == null) {
      return _asMap(await _request('PUT', 'users/profile', body: fields));
    }

    final image = _prepareImage(
      profileImageBytes,
      profileImageFilename ?? 'profile.jpg',
    );
    final request = http.MultipartRequest('PUT', _uri('users/profile'))
      ..headers.addAll(_headers())
      ..fields.addAll(fields)
      ..files.add(
        http.MultipartFile.fromBytes(
          'profile_image',
          image.bytes,
          filename: image.filename,
          contentType: image.contentType,
        ),
      );

    return _asMap(await _send(request));
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return _asMap(
      await _request(
        'PUT',
        'users/password',
        body: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getPendingBookings() async {
    return _asMapList(await _request('GET', 'admin/bookings/pending'));
  }

  Future<Map<String, dynamic>> verifyBooking({
    required int bookingId,
    required String status,
  }) async {
    if (status != 'approved' && status != 'rejected') {
      throw ArgumentError.value(
        status,
        'status',
        'Must be approved or rejected.',
      );
    }

    return _asMap(
      await _request(
        'PUT',
        'admin/bookings/$bookingId/verify',
        body: {'status': status},
      ),
    );
  }

  Future<Map<String, dynamic>> getAdminAnalytics({
    required DateTime date,
  }) async {
    return _asMap(
      await _request(
        'GET',
        'admin/analytics',
        queryParameters: {'date': formatApiDate(date)},
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getAdminUsers({String? query}) async {
    final normalizedQuery = query?.trim();
    return _asMapList(
      await _request(
        'GET',
        'admin/users',
        queryParameters: normalizedQuery == null || normalizedQuery.isEmpty
            ? null
            : {'query': normalizedQuery},
      ),
    );
  }

  Future<Map<String, dynamic>> resetUserPassword({
    required int userId,
    String? newPassword,
  }) async {
    return _asMap(
      await _request(
        'PUT',
        'admin/users/$userId/reset-password',
        body: newPassword == null ? const {} : {'password': newPassword},
      ),
    );
  }

  static String formatApiDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static _PreparedImage _prepareImage(Uint8List bytes, String filename) {
    final imageType =
        _detectImageType(bytes) ?? _imageTypeFromFilename(filename);
    if (imageType == null || bytes.isEmpty) {
      throw const FormatException(
        'Select a JPEG, PNG, GIF, WebP, HEIC, or HEIF image.',
      );
    }

    final basename = filename.split(RegExp(r'[/\\]')).last.trim();
    final dotIndex = basename.lastIndexOf('.');
    final stem = dotIndex > 0 ? basename.substring(0, dotIndex) : basename;
    final safeStem = stem.isEmpty ? 'image' : stem;

    return _PreparedImage(
      bytes: bytes,
      filename: '$safeStem.${imageType.extension}',
      contentType: MediaType('image', imageType.subtype),
    );
  }

  static _ImageType? _detectImageType(Uint8List bytes) {
    bool startsWith(List<int> signature) =>
        bytes.length >= signature.length &&
        List.generate(signature.length, (index) => bytes[index]).join(',') ==
            signature.join(',');

    if (startsWith([0xFF, 0xD8, 0xFF])) return _ImageType.jpeg;
    if (startsWith([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
      return _ImageType.png;
    }
    if (startsWith([0x47, 0x49, 0x46, 0x38])) return _ImageType.gif;
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return _ImageType.webp;
    }
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(4, 8)) == 'ftyp') {
      final brand = String.fromCharCodes(bytes.sublist(8, 12)).toLowerCase();
      if (const {
        'heic',
        'heix',
        'hevc',
        'hevx',
        'heim',
        'heis',
      }.contains(brand)) {
        return _ImageType.heic;
      }
      if (const {'heif', 'heifs', 'mif1', 'msf1'}.contains(brand)) {
        return _ImageType.heif;
      }
    }
    return null;
  }

  static _ImageType? _imageTypeFromFilename(String filename) {
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex < 0) return null;
    return switch (filename.substring(dotIndex).toLowerCase()) {
      '.jpg' || '.jpeg' => _ImageType.jpeg,
      '.png' => _ImageType.png,
      '.gif' => _ImageType.gif,
      '.webp' => _ImageType.webp,
      '.heic' => _ImageType.heic,
      '.heif' => _ImageType.heif,
      _ => null,
    };
  }

  Future<Object?> _request(
    String method,
    String path, {
    Map<String, String>? queryParameters,
    Object? body,
    bool authenticated = true,
  }) async {
    final request = http.Request(
      method,
      _uri(path, queryParameters: queryParameters),
    )..headers.addAll(_headers(authenticated: authenticated));

    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }

    return _send(request);
  }

  Future<Object?> _send(http.BaseRequest request) async {
    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    final payload = _decodeBody(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = payload is Map<String, dynamic>
          ? payload['message']?.toString()
          : null;
      throw ApiException(
        statusCode: response.statusCode,
        message: message?.isNotEmpty == true
            ? message!
            : 'Request failed with status ${response.statusCode}.',
      );
    }

    return payload;
  }

  Map<String, String> _headers({bool authenticated = true}) {
    final headers = <String, String>{'Accept': 'application/json'};
    if (authenticated && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  Uri _uri(String path, {Map<String, String>? queryParameters}) {
    final uri = _baseUri.resolve(path);
    return queryParameters == null
        ? uri
        : uri.replace(queryParameters: queryParameters);
  }

  static Uri _normalizeBaseUri(Uri uri) {
    final normalizedPath = uri.path.endsWith('/') ? uri.path : '${uri.path}/';
    return Uri(
      scheme: uri.scheme,
      userInfo: uri.userInfo.isEmpty ? null : uri.userInfo,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: normalizedPath,
    );
  }

  static Object? _decodeBody(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return body;
    }
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('Expected a JSON object from the API.');
  }

  static List<Map<String, dynamic>> _asMapList(Object? value) {
    if (value is List) {
      return value.map(_asMap).toList(growable: false);
    }
    throw const FormatException('Expected a JSON list from the API.');
  }
}

class _PreparedImage {
  const _PreparedImage({
    required this.bytes,
    required this.filename,
    required this.contentType,
  });

  final Uint8List bytes;
  final String filename;
  final MediaType contentType;
}

class _ImageType {
  const _ImageType(this.extension, this.subtype);

  static const jpeg = _ImageType('jpg', 'jpeg');
  static const png = _ImageType('png', 'png');
  static const gif = _ImageType('gif', 'gif');
  static const webp = _ImageType('webp', 'webp');
  static const heic = _ImageType('heic', 'heic');
  static const heif = _ImageType('heif', 'heif');

  final String extension;
  final String subtype;
}

class ApiException implements Exception {
  const ApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
