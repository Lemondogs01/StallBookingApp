import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_market_app/controllers/auth_controller.dart';

import 'controller_test_support.dart';

void main() {
  group('AuthController', () {
    test('logs in, saves the token, and loads the user', () async {
      final storage = MemoryStorage();
      final api = testApi((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/auth/login');
        return testJsonResponse({'token': 'jwt-token', 'user': testUser()});
      });
      addTearDown(api.close);
      final controller = AuthController(api, storage);
      addTearDown(controller.dispose);

      final signedIn = await controller.login(
        username: 'vendor8',
        password: 'password123',
      );

      expect(signedIn, isTrue);
      expect(storage.token, 'jwt-token');
      expect(controller.user?.username, 'vendor8');
      expect(controller.isAuthenticated, isTrue);
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
    });

    test('returns a readable message when the API rejects login', () async {
      final api = testApi(
        (_) async =>
            testJsonResponse({'message': 'Invalid username or password.'}, 401),
      );
      addTearDown(api.close);
      final controller = AuthController(api, MemoryStorage());
      addTearDown(controller.dispose);

      final signedIn = await controller.login(
        username: 'vendor8',
        password: 'wrong-password',
      );

      expect(signedIn, isFalse);
      expect(controller.errorMessage, 'Invalid username or password.');
      expect(controller.isLoading, isFalse);
    });

    test('restores an existing session and clears an expired one', () async {
      final validStorage = MemoryStorage(token: 'saved-token');
      final validApi = testApi((request) async {
        expect(request.method, 'GET');
        expect(request.headers['Authorization'], 'Bearer saved-token');
        return testJsonResponse(testUser());
      });
      addTearDown(validApi.close);
      final validController = AuthController(validApi, validStorage);
      addTearDown(validController.dispose);

      await validController.initialize();
      expect(validController.user?.id, 8);
      expect(validController.isInitialized, isTrue);

      final expiredStorage = MemoryStorage(token: 'expired-token');
      final expiredApi = testApi(
        (_) async =>
            testJsonResponse({'message': 'Invalid or expired token.'}, 401),
      );
      addTearDown(expiredApi.close);
      final expiredController = AuthController(expiredApi, expiredStorage);
      addTearDown(expiredController.dispose);

      await expiredController.initialize();
      expect(expiredController.user, isNull);
      expect(expiredStorage.token, isNull);
      expect(expiredController.isInitialized, isTrue);
    });

    test('registers vendors and does not require an email field', () async {
      final api = testApi((request) async {
        expect(request.url.path, '/api/auth/register');
        expect(request.body, isNot(contains('email')));
        return testJsonResponse({'token': 'new-token', 'user': testUser()});
      });
      addTearDown(api.close);
      final storage = MemoryStorage();
      final controller = AuthController(api, storage);
      addTearDown(controller.dispose);

      final registered = await controller.register(
        username: 'vendor8',
        password: 'password123',
        shopName: 'Tea Stand',
        realName: 'Vendor Eight',
        phone: '0800000000',
      );

      expect(registered, isTrue);
      expect(storage.token, 'new-token');
      expect(controller.user?.role, 'vendor');
    });

    test(
      'clears the in-memory session on logout even if secure storage fails',
      () async {
        final storage = MemoryStorage(token: 'saved-token', failClear: true);
        final authorizationHeaders = <String?>[];
        final api = testApi((request) async {
          authorizationHeaders.add(request.headers['Authorization']);
          return testJsonResponse(testUser());
        });
        addTearDown(api.close);
        final controller = AuthController(api, storage);
        addTearDown(controller.dispose);

        await controller.initialize();
        await controller.logout();
        await api.getProfile();

        expect(controller.user, isNull);
        expect(authorizationHeaders, ['Bearer saved-token', null]);
      },
    );

    test('changes a password and reports API errors', () async {
      var shouldFail = false;
      final api = testApi((request) async {
        expect(request.url.path, '/api/users/password');
        if (shouldFail) {
          return testJsonResponse({
            'message': 'Current password is incorrect.',
          }, 401);
        }
        return testJsonResponse({});
      });
      addTearDown(api.close);
      final controller = AuthController(api, MemoryStorage());
      addTearDown(controller.dispose);

      expect(
        await controller.changePassword(
          currentPassword: 'old-password',
          newPassword: 'new-password',
        ),
        isTrue,
      );
      shouldFail = true;
      expect(
        await controller.changePassword(
          currentPassword: 'wrong-password',
          newPassword: 'new-password',
        ),
        isFalse,
      );
      expect(controller.passwordErrorMessage, 'Current password is incorrect.');
      expect(controller.isChangingPassword, isFalse);
    });
  });
}
