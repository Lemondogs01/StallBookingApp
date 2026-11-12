import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_market_app/services/storage_service.dart';

void main() {
  // กรณีนี้ทดสอบ «reads, saves, and clears the saved access token»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  test('reads, saves, and clears the saved access token', () async {
    FlutterSecureStorage.setMockInitialValues({});
    const storage = StorageService();

    expect(await storage.readToken(), isNull);
    await storage.saveToken('test-token');
    expect(await storage.readToken(), 'test-token');
    await storage.clearToken();
    expect(await storage.readToken(), isNull);
  });
}
