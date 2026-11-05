import 'package:mfu_market/controller/mock_db.dart';
import 'package:mfu_market/model/user_model.dart';

class AuthController {
  Future<UserModel> login(String username, String password) async {
    final key = username.trim().toLowerCase();
    if (MockDb.passwords[key] != password) {
      throw Exception('Wrong username or password.');
    }
    return MockDb.users.firstWhere((u) => u.username.toLowerCase() == key);
  }

  Future<UserModel> register(String username, String password) async {
    final key = username.trim().toLowerCase();
    if (MockDb.passwords.containsKey(key)) {
      throw Exception('This username is already taken.');
    }
    final user = UserModel(
      id: MockDb.nextUserId++,
      username: username.trim(),
      role: 'vendor',
    );
    MockDb.users.add(user);
    MockDb.passwords[key] = password;
    return user;
  }
}
