import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'ui/screens/splash_screen.dart';

void main() async {
  // Bắt buộc phải gọi hàm này trước khi dùng các plugin native (Firebase, SQLite...)
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Khởi tạo Firebase với options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Đăng nhập ẩn danh để có auth token hợp lệ với Firestore
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
    debugPrint("✅ Đã kết nối thành công với Firebase!");
  } catch (e) {
    debugPrint("❌ Lỗi kết nối Firebase: $e");
    // Bạn vẫn có thể chạy app bằng cách bắt lỗi này nếu cần
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
