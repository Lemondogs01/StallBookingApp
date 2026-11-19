import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/admin_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/booking_controller.dart';
import 'controllers/payment_controller.dart';
import 'controllers/profile_controller.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'views/auth/auth_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MFUMarketApp());
}

class MFUMarketApp extends StatelessWidget {
  const MFUMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(
          create: (_) => ApiService(),
          dispose: (_, api) => api.close(),
        ),
        Provider<StorageService>(create: (_) => const StorageService()),
        ChangeNotifierProvider<AuthController>(
          create: (context) {
            final controller = AuthController(
              context.read<ApiService>(),
              context.read<StorageService>(),
            );
            unawaited(controller.initialize());
            return controller;
          },
        ),
        ChangeNotifierProvider(
          create: (context) => BookingController(context.read<ApiService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => PaymentController(context.read<ApiService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ProfileController(context.read<ApiService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => AdminController(context.read<ApiService>()),
        ),
      ],
      child: MaterialApp(
        title: 'MFU Market',
        locale: const Locale('en', 'US'),
        supportedLocales: const [Locale('en', 'US')],
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthGate(),
      ),
    );
  }
}
