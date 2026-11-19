import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_market_app/views/widgets/app_widgets.dart';

void main() {
  // ตรวจว่าป้ายสถานะการจองแสดงคำว่า Approved, Rejected, Cancelled และ Pending ตรงตามสถานะที่ส่งเข้าไป
  testWidgets('StatusBadge renders labels for all booking statuses', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              StatusBadge('approved'),
              StatusBadge('rejected'),
              StatusBadge('cancelled'),
              StatusBadge('pending'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
  });
// ตรวจการจัดรูปแบบตัวเลขจำนวนเงิน เช่น เลขลงตัวแสดง ฿250 และเลขทศนิยมที่ไม่ลงตัวแสดง ฿199.50
  testWidgets('MoneyText formats integer and decimal amounts', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              MoneyText(250),
              MoneyText(250.0),
              MoneyText(199.5),
            ],
          ),
        ),
      ),
    );

    expect(find.text('฿250'), findsNWidgets(2));
    expect(find.text('฿199.50'), findsOneWidget);
  });

// ตรวจว่ากล่องแจ้งเตือน error แสดงข้อความที่กำหนด และเมื่อกดปุ่ม Try again จะเรียกฟังก์ชันให้ลองโหลดใหม่ (retried = true)
  testWidgets('ErrorBanner triggers retry callback when tapped', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorBanner(
            'Network error occurred.',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Network error occurred.'), findsOneWidget);
    await tester.tap(find.byTooltip('Try again'));
    await tester.pump();
    expect(retried, isTrue);
  });
}