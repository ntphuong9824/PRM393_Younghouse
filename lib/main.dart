import 'package:flutter/material.dart';
import 'package:yh/ui/screens/main_screen.dart';
import 'package:yh/ui/screens/payment_detail_screen.dart';
import 'package:yh/ui/screens/profile_completion_screen.dart';
import 'core/theme/app_theme.dart';
import 'ui/screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Young House',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainScreen(), // Đặt SplashScreen làm trang bắt đầu
    );
  }
}
