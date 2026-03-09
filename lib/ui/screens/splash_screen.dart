import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Chuyển sang màn hình Đăng nhập sau 3 giây
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top Waves
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 300),
              painter: TopWavePainter(),
            ),
          ),
          
          // Bottom Waves
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 300),
              painter: BottomWavePainter(),
            ),
          ),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logoText.png',
                  width: MediaQuery.of(context).size.width * 0.8,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Text(
                    "Young House",
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF1E88C8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Version
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Version: 1.0.0",
                style: TextStyle(
                  color: AppColors.textDark.withOpacity(0.4),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TopWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..style = PaintingStyle.fill;
    paint.color = AppColors.primary.withOpacity(0.15);
    Path path1 = Path();
    path1.lineTo(0, size.height * 0.7);
    path1.quadraticBezierTo(size.width * 0.25, size.height * 0.9, size.width * 0.5, size.height * 0.75);
    path1.quadraticBezierTo(size.width * 0.75, size.height * 0.6, size.width, size.height * 0.8);
    path1.lineTo(size.width, 0);
    path1.close();
    canvas.drawPath(path1, paint);

    paint.color = AppColors.primary.withOpacity(0.4);
    Path path2 = Path();
    path2.lineTo(0, size.height * 0.5);
    path2.quadraticBezierTo(size.width * 0.4, size.height * 0.7, size.width * 0.75, size.height * 0.45);
    path2.quadraticBezierTo(size.width * 0.9, size.height * 0.35, size.width, size.height * 0.5);
    path2.lineTo(size.width, 0);
    path2.close();
    canvas.drawPath(path2, paint);

    paint.color = AppColors.primary.withOpacity(0.85);
    Path path3 = Path();
    path3.lineTo(0, size.height * 0.35);
    path3.quadraticBezierTo(size.width * 0.3, size.height * 0.5, size.width * 0.65, size.height * 0.3);
    path3.quadraticBezierTo(size.width * 0.85, size.height * 0.15, size.width, size.height * 0.35);
    path3.lineTo(size.width, 0);
    path3.close();
    canvas.drawPath(path3, paint);
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class BottomWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..style = PaintingStyle.fill;
    paint.color = AppColors.secondary.withOpacity(0.1);
    Path path1 = Path();
    path1.moveTo(0, size.height * 0.3);
    path1.quadraticBezierTo(size.width * 0.3, size.height * 0.1, size.width * 0.6, size.height * 0.4);
    path1.quadraticBezierTo(size.width * 0.85, size.height * 0.6, size.width, size.height * 0.3);
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint);

    paint.color = AppColors.secondary.withOpacity(0.6);
    Path path2 = Path();
    path2.moveTo(0, size.height * 0.6);
    path2.quadraticBezierTo(size.width * 0.35, size.height * 0.45, size.width * 0.7, size.height * 0.7);
    path2.quadraticBezierTo(size.width * 0.9, size.height * 0.85, size.width, size.height * 0.65);
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint);
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
