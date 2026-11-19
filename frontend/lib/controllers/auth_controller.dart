import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._api, this._storage);

  final ApiService _api;
  final StorageService _storage;

  UserModel? user;
  bool isLoading = false;
  bool isChangingPassword = false;
  String? passwordErrorMessage;
  bool isInitialized = false;
  String? errorMessage;

  bool get isAuthenticated => user != null;

  Future<void> initialize() async {
    try {
      final token = await _storage.readToken();
      if (token != null && token.isNotEmpty) {
        _api.setAccessToken(token);
        user = UserModel.fromJson(await _api.getProfile());
      }
    } catch (error) {
      _api.setAccessToken(null);
      if (error is ApiException &&
          (error.statusCode == 401 || error.statusCode == 404)) {
        try {
          await _storage.clearToken();
        } catch (_) {
          // Continue to the sign-in screen if secure storage is unavailable.
        }
      }
    } finally {
      isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    return _authenticate(
      () => _api.login(username: username, password: password),
    );
  }

  Future<bool> register({
    required String username,
    required String password,
    required String shopName,
    required String realName,
    required String phone,
  }) async {
    return _authenticate(
      () => _api.registerVendor(
        username: username,
        password: password,
        shopName: shopName,
        realName: realName,
        phone: phone,
      ),
    );
  }

  Future<bool> _authenticate(
    Future<Map<String, dynamic>> Function() action,
  ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await action();
      final token = response['token']?.toString();
      final userJson = response['user'];
      if (token == null || token.isEmpty || userJson is! Map) {
        throw const FormatException('The server returned an invalid session.');
      }

      await _storage.saveToken(token);
      _api.setAccessToken(token);
      user = UserModel.fromJson(Map<String, dynamic>.from(userJson));
      isInitialized = true;
      return true;
    } catch (error) {
      errorMessage = _messageFor(error);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _storage.clearToken();
    } catch (_) {
      // Always clear the in-memory session, even if secure storage fails.
    }
    _api.setAccessToken(null);
    user = null;
    errorMessage = null;
    notifyListeners();
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    isChangingPassword = true;
    passwordErrorMessage = null;
    notifyListeners();
    try {
      await _api.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (error) {
      passwordErrorMessage = _messageFor(error);
      return false;
    } finally {
      isChangingPassword = false;
      notifyListeners();
    }
  }

  static String _messageFor(Object error) => error is ApiException
      ? error.message
      : 'Could not connect to the service. Please try again.';
}
