import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';

class ProfileController extends ChangeNotifier {
  ProfileController(this._api);

  final ApiService _api;
  UserModel? profile;
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      profile = UserModel.fromJson(await _api.getProfile());
    } catch (error) {
      errorMessage = error is ApiException
          ? error.message
          : 'Could not load the profile.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> save({
    required String shopName,
    required String realName,
    required String phone,
    Uint8List? imageBytes,
    String? imageFilename,
  }) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await _api.updateProfile(
        shopName: shopName,
        realName: realName,
        phone: phone,
        profileImageBytes: imageBytes,
        profileImageFilename: imageFilename,
      );
      final updatedUser = response['user'];
      if (updatedUser is Map) {
        profile = UserModel.fromJson(Map<String, dynamic>.from(updatedUser));
      }
      return true;
    } catch (error) {
      errorMessage = error is ApiException
          ? error.message
          : 'Could not save the profile.';
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
