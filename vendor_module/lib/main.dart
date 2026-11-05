import 'package:flutter/material.dart';
import 'package:mfu_market/controller/mock_db.dart';
import 'package:mfu_market/theme.dart';
import 'package:mfu_market/views/login_view.dart';

void main() {
  MockDb.reset();
  runApp(const MfuMarketApp());
}

class MfuMarketApp extends StatelessWidget {
  const MfuMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MFU Market',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      home: const LoginView(),
    );
  }
}
