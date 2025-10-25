import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:my_kids_drawing_app2/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _strokeController;
  late AnimationController _textController;
  late AnimationController _starsController;
  late AnimationController _bgController;
  late AnimationController _splashController;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();

    // Logo bounce & rotation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Rainbow stroke animation
    _strokeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Text animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    // Stars animation
    _starsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Animated background gradient
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // Paint splash effect
    _splashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    // Shimmer effect for text
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Navigate to Home with fade transition
    Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _strokeController.dispose();
    _textController.dispose();
    _starsController.dispose();
    _bgController.dispose();
    _splashController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) {
          return Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.pinkAccent,
                  Colors.orange,
                  Colors.yellow,
                  Colors.green,
                  Colors.blue,
                  Colors.purple,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                transform: GradientRotation(_bgController.value * 2 * math.pi),
              ),
            ),
            child: Stack(
              children: [
                // Sparkling stars
                CustomPaint(
                  size: size,
                  painter: StarsPainter(_starsController.value),
                ),

                // Floating crayons, brushes & emojis
                CustomPaint(
                  size: size,
                  painter: FloatingItemsPainter(_bgController.value),
                ),

                // Shooting stars
                CustomPaint(
                  size: size,
                  painter: ShootingStarPainter(_bgController.value),
                ),

                // Center content
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Paint splash + Logo + Stroke + Glow
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Paint splash reveal
                          CustomPaint(
                            size: const Size(220, 220),
                            painter: PaintSplashPainter(
                              _splashController.value,
                            ),
                          ),
                          // Rainbow stroke
                          CustomPaint(
                            size: const Size(160, 160),
                            painter: RainbowStrokePainter(
                              _strokeController.value,
                            ),
                          ),
                          // Glowing aura behind logo
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  blurRadius: 60,
                                  spreadRadius: 40,
                                ),
                              ],
                            ),
                          ),
                          // Logo bounce & rotate
                          RotationTransition(
                            turns: Tween(
                              begin: -0.05,
                              end: 0.05,
                            ).animate(_logoController),
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.9, end: 1.2)
                                  .animate(
                                    CurvedAnimation(
                                      parent: _logoController,
                                      curve: Curves.easeInOut,
                                    ),
                                  ),
                              child: Container(
                                padding: const EdgeInsets.all(25),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 10,
                                      offset: Offset(3, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.brush,
                                  size: 90,
                                  color: Colors.deepPurpleAccent,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // App name with shimmer + rainbow text + bounce
                      SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0, 0.3),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: _textController,
                                curve: Curves.elasticOut,
                              ),
                            ),
                        child: FadeTransition(
                          opacity: _textController,
                          child: AnimatedBuilder(
                            animation: _shimmerController,
                            builder: (context, child) {
                              return ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: const [
                                    Colors.red,
                                    Colors.orange,
                                    Colors.yellow,
                                    Colors.green,
                                    Colors.blue,
                                    Colors.purple,
                                  ],
                                  transform: GradientRotation(
                                    _shimmerController.value * 2 * math.pi,
                                  ),
                                ).createShader(bounds),
                                child: const Text(
                                  "Kids Ground",
                                  style: TextStyle(
                                    fontSize: 52,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'ComicNeue',
                                    color: Colors.white,
                                    letterSpacing: 3,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black45,
                                        blurRadius: 8,
                                        offset: Offset(3, 3),
                                      ),
                                      Shadow(
                                        color: Colors.white24,
                                        blurRadius: 15,
                                        offset: Offset(-2, -2),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Subtitle with sparkle + fade in
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _textController,
                          curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
                        ),
                        child: SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0, 0.5),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: _textController,
                                  curve: const Interval(
                                    0.3,
                                    1.0,
                                    curve: Curves.easeOutBack,
                                  ),
                                ),
                              ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 2,
                              ),
                            ),
                            child: const Text(
                              "✨ Draw • Play • Imagine 🎨",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                fontStyle: FontStyle.italic,
                                color: Colors.white,
                                letterSpacing: 1.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 8,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Rainbow stroke painter
class RainbowStrokePainter extends CustomPainter {
  final double progress;
  RainbowStrokePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final gradient = SweepGradient(
      colors: [
        Colors.red,
        Colors.orange,
        Colors.yellow,
        Colors.green,
        Colors.blue,
        Colors.purple,
        Colors.red,
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final startAngle = -math.pi / 2;
    final sweepAngle = progress * 2 * math.pi;

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant RainbowStrokePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Stars painter
class StarsPainter extends CustomPainter {
  final double progress;
  StarsPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.9);

    for (int i = 0; i < 25; i++) {
      final dx =
          (size.width * ((i * 37 % 100) / 100)) +
          (10 * math.sin(progress * 2 * math.pi + i));
      final dy =
          (size.height * ((i * 53 % 100) / 100)) +
          (10 * math.cos(progress * 2 * math.pi + i));
      canvas.drawCircle(Offset(dx, dy), (i % 3 == 0 ? 3 : 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant StarsPainter oldDelegate) => true;
}

/// Floating icons + emojis
class FloatingItemsPainter extends CustomPainter {
  final double progress;
  FloatingItemsPainter(this.progress);

  final icons = ["🎨", "🖌️", "✏️", "🌈", "⭐", "🖍️", "✨"];

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < icons.length; i++) {
      final dx =
          size.width * ((i * 23 % 100) / 100) +
          (20 * math.sin(progress * 2 * math.pi + i));
      final dy =
          size.height * ((i * 41 % 100) / 100) +
          (25 * math.cos(progress * 2 * math.pi + i));

      TextPainter tp = TextPainter(
        text: TextSpan(text: icons[i], style: const TextStyle(fontSize: 28)),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(dx, dy));
    }
  }

  @override
  bool shouldRepaint(covariant FloatingItemsPainter oldDelegate) => true;
}

/// Shooting stars painter
class ShootingStarPainter extends CustomPainter {
  final double progress;
  ShootingStarPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 5; i++) {
      final dx =
          size.width * ((i * 29 % 100) / 100) + progress * size.width * 0.8;
      final dy =
          size.height * ((i * 17 % 100) / 100) + progress * size.height * 0.3;
      canvas.drawLine(Offset(dx, dy), Offset(dx - 20, dy + 20), paint);
    }
  }

  @override
  bool shouldRepaint(covariant ShootingStarPainter oldDelegate) => true;
}

/// Paint splash painter
class PaintSplashPainter extends CustomPainter {
  final double progress;
  PaintSplashPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [Colors.yellow, Colors.orange, Colors.pink, Colors.blue];

    for (int i = 0; i < 4; i++) {
      final paint = Paint()
        ..color = colors[i].withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      final radius = progress * size.width / (3 + i);
      canvas.drawCircle(size.center(Offset.zero), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant PaintSplashPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
