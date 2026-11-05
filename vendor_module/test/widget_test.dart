import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_market/controller/mock_db.dart';
import 'package:mfu_market/main.dart';

void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(440, 956);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> loginAsVendor(WidgetTester tester) async {
  useTallScreen(tester);
  await tester.pumpWidget(const MfuMarketApp());
  await tester.enterText(find.byType(TextField).at(0), 'vendor');
  await tester.enterText(find.byType(TextField).at(1), 'vendor123');
  await tester.tap(find.text('Login'));
  await tester.pumpAndSettle();
}

/// Discover -> event -> stall picker -> review screen (stall A03 preselected).
Future<void> openReview(WidgetTester tester) async {
  await loginAsVendor(tester);
  await tester.tap(find.text('MFU night market (inside uni.)'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Choose a stall'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Continue with A03'));
  await tester.pumpAndSettle();
}

Future<void> agreeToTerms(WidgetTester tester) async {
  await tester.ensureVisible(find.byType(Checkbox));
  await tester.tap(find.byType(Checkbox));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    MockDb.reset();
  });

  testWidgets('1. Wrong password should show an error', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(const MfuMarketApp());
    await tester.enterText(find.byType(TextField).at(0), 'vendor');
    await tester.enterText(find.byType(TextField).at(1), 'wrong');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Wrong username or password.'), findsOneWidget);
  });

  testWidgets('2. Login should show the Discover page with both markets',
      (tester) async {
    await loginAsVendor(tester);

    expect(find.textContaining('Big possibilities.'), findsOneWidget);
    expect(find.text('3 stalls left'), findsOneWidget);
    expect(find.textContaining('9 stalls left'), findsOneWidget);
  });

  testWidgets('3. Search should narrow the list of markets', (tester) async {
    await loginAsVendor(tester);

    await tester.enterText(find.byType(TextField), 'outside');
    await tester.pumpAndSettle();

    expect(find.text('MFU night market (outside uni.)'), findsOneWidget);
    expect(find.text('MFU night market (inside uni.)'), findsNothing);
  });

  testWidgets('4. Booking flow should end on My bookings with a pending booking',
      (tester) async {
    await openReview(tester);
    expect(find.text('Review & book'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'Clay & Fern');
    await tester.enterText(find.byType(TextField).at(1), 'Maya Thompson');
    await tester.enterText(find.byType(TextField).at(2), 'maya@clayfern.co.uk');
    await agreeToTerms(tester);

    await tester.tap(find.textContaining('Book stall'));
    await tester.pumpAndSettle();
    expect(find.textContaining('starts at A03'), findsOneWidget);

    await tester.tap(find.text('View my bookings'));
    await tester.pumpAndSettle();

    expect(find.text('My bookings'), findsWidgets);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Cancel booking'), findsWidgets);
  });

  testWidgets('5. Review should ask for the business name', (tester) async {
    await openReview(tester);
    await agreeToTerms(tester);

    await tester.tap(find.textContaining('Book stall'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your business name.'), findsOneWidget);
  });

  testWidgets('6. Log out should go back to the login page', (tester) async {
    await loginAsVendor(tester);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
  });
}
