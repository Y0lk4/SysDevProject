import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    _animationController.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(Duration(seconds: 2 ));

    if (mounted) {
      await _animationController.reverse();
    }

    if (mounted) {
      final prefs = await SharedPreferences.getInstance();
      final loggedIn = prefs.getBool('loggedIn') ?? false;
      Navigator.of(context).pushReplacementNamed(loggedIn ? '/home' : '/login');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color(0xFF757575),
                    width: 8,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'BROCHETTE',
                      style: TextStyle(
                        color: Color(0xFFEF8B7C),
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 12),
                    CustomPaint(
                      size: Size(40, 60),
                      painter: _BrochettePainter(),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'MEAT & GRILL',
                      style: TextStyle(
                        color: Color(0xFF757575),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 60),
              Text(
                'Financial Reports',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 32,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Daily Report Management',
                style: TextStyle(
                  color: Color(0xFF78909C),
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrochettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintStick = Paint()
      ..color = Color(0xFFD4A574)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final paintMeat = Paint()
      ..color = Color(0xFFEF8B7C)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(5 * math.pi / 180);
    canvas.translate(-size.width / 2, -size.height / 2);

    final centerX = size.width / 2;

    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      paintStick,
    );

    final meatYPositions = [15.0, 30.0, 45.0];
    for (int i = 0; i < meatYPositions.length; i++) {
      final rect = Rect.fromCenter(
        center: Offset(centerX, meatYPositions[i]),
        width: 26,
        height: 18,
      );

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: Radius.circular(8),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(8),
        ),
        paintMeat,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}