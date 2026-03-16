import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'ui/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Đăng nhập ẩn danh để Firestore Rules cho phép đọc/ghi
    if (FirebaseAuth.instance.currentUser == null) {
      final cred = await FirebaseAuth.instance.signInAnonymously();
      debugPrint('✅ Firebase connected, uid: ${cred.user?.uid}');
    } else {
      debugPrint(
          '✅ Firebase already signed in: ${FirebaseAuth.instance.currentUser?.uid}');
    }
  } catch (e) {
    debugPrint('❌ Firebase error: $e');
  }
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
      home: const SplashScreen(),
    );
  }
}
