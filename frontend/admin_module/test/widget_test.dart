import 'package:admin_module/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Login screen is shown on start', (tester) async {
    await tester.pumpWidget(const AdminApp());
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('MFUgrowtogether'), findsOneWidget);
  });
}
