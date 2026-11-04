import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'controllers/booking_controller.dart';
import 'views/login_view.dart';
import 'theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => BookingController()),
      ],
      child: MaterialApp(
        title: 'MFU Stall Booking',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const LoginView(),
      ),
    );
  }
}
