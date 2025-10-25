import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:ui';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _logoController;
  late AnimationController _buttonController;
  late AnimationController _imageController;
  int _currentQuote = 0;

  final List<String> _quotes = [
    "Every child is an artist. 🖌️",
    "Draw your dreams into reality!",
    "Imagination has no limits! ✨",
    "Create, Play, and Explore! 🎨",
  ];

  final List<String> _imagePaths = [
    'https://cdn.pixabay.com/photo/2019/05/05/17/00/house-4181057_1280.png',
    'https://cdn.pixabay.com/photo/2019/04/29/20/41/amsterdam-4167026_1280.png',
    'https://cdn.pixabay.com/photo/2021/08/31/09/42/hedgehog-6588339_1280.jpg',
    'https://cdn.pixabay.com/photo/2014/12/19/22/35/children-drawing-573584_1280.jpg',
    'https://cdn.pixabay.com/photo/2022/03/09/19/51/mama-7058608_1280.jpg',
    'https://cdn.pixabay.com/photo/2021/11/05/08/45/house-6770693_1280.png',
  ];

  final List<IconData> _floatingIcons = [
    Icons.brush,
    Icons.create,
    Icons.color_lens,
    Icons.star,
  ];

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
      lowerBound: 0.0,
      upperBound: 0.05,
    )..repeat(reverse: true);

    _imageController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25), // slower = smoother
    )..repeat();

    Future.delayed(const Duration(seconds: 5), _autoChangeQuote);
  }

  void _autoChangeQuote() {
    if (!mounted) return;
    setState(() {
      _currentQuote = (_currentQuote + 1) % _quotes.length;
    });
    Future.delayed(const Duration(seconds: 5), _autoChangeQuote);
  }

  @override
  void dispose() {
    _bgController.dispose();
    _logoController.dispose();
    _buttonController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  // Background animation
  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        double value = _bgController.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(
                  Colors.pink.shade300,
                  Colors.purple.shade400,
                  value,
                )!,
                Color.lerp(Colors.blue.shade300, Colors.pink.shade300, value)!,
                Color.lerp(
                  Colors.yellow.shade300,
                  Colors.orange.shade300,
                  value,
                )!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );
      },
    );
  }

  // Floating icons
  Widget _buildFloatingShapes() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: List.generate(20, (index) {
        final random = math.Random(index);
        final left = random.nextDouble() * screenWidth;
        final top = random.nextDouble() * screenHeight;
        final size = 12.0 + random.nextDouble() * 28;
        final icon = _floatingIcons[index % _floatingIcons.length];

        return AnimatedBuilder(
          animation: _bgController,
          builder: (context, child) {
            double opacity =
                (0.3 +
                        0.5 *
                            math.sin(_bgController.value * 2 * math.pi + index))
                    .clamp(0.0, 1.0);
            return Positioned(
              left:
                  (left +
                          15 *
                              math.sin(
                                _bgController.value * 2 * math.pi + index,
                              ))
                      .clamp(0, screenWidth),
              top:
                  (top +
                          15 *
                              math.cos(
                                _bgController.value * 2 * math.pi + index,
                              ))
                      .clamp(0, screenHeight),
              child: Opacity(
                opacity: opacity,
                child: Icon(
                  icon,
                  color: Colors.primaries[index % Colors.primaries.length]
                      .withValues(alpha: 0.7),
                  size: size,
                ),
              ),
            );
          },
        );
      }),
    );
  }

  // Logo on top
  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.only(top: 40.0, bottom: 10),
      child: AnimatedBuilder(
        animation: _logoController,
        builder: (context, child) {
          final scale = 0.95 + 0.15 * _logoController.value;
          final rotation = 0.04 * math.sin(_logoController.value * 2 * math.pi);

          return Transform.rotate(
            angle: rotation,
            child: Transform.scale(
              scale: scale,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.purpleAccent.withValues(alpha: 0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 25,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.brush,
                      size: 80,
                      color: Colors.deepPurpleAccent,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Moving images row
  Widget _buildMovingImages() {
    return SizedBox(
      height: 180, // increased height for bigger images
      child: AnimatedBuilder(
        animation: _imageController,
        builder: (context, child) {
          double progress = _imageController.value; // 0 → 1

          // Total width of the row (sum of all images + spacing)
          double totalWidth = _imagePaths.length * 160.0; // Reduced total width

          // Calculate horizontal offset for smooth looping
          double offsetX = -totalWidth * progress;

          return ClipRect(
            child: Transform.translate(
              offset: Offset(offsetX, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min, // Use min to prevent overflow
                  children: [
                    ..._imagePaths.map(
                      (path) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            width: 120, // Further reduced width
                            height: 140, // image height
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: const Offset(2, 4),
                                ),
                              ],
                            ),
                            child: Image.network(
                              path,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade300,
                                  child: const Icon(
                                    Icons.broken_image,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    // duplicate images for smooth looping
                    ..._imagePaths.map(
                      (path) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: SizedBox(
                            width: 120, // Further reduced width
                            height: 140,
                            child: Image.network(path, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Quotes with improved visibility
  Widget _buildQuote() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 20),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 800),
        child: ClipRRect(
          key: ValueKey<int>(_currentQuote),
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Text(
                _quotes[_currentQuote],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Start button
  Widget _buildStartButton() {
    return AnimatedBuilder(
      animation: _buttonController,
      builder: (context, child) {
        final scale = 1 + _buttonController.value;
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/drawing'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Colors.purpleAccent,
                    Colors.deepPurple,
                    Colors.pinkAccent,
                  ],
                ),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pinkAccent.withValues(alpha: 0.6),
                    blurRadius: 20,
                    offset: const Offset(3, 4),
                  ),
                  BoxShadow(
                    color: Colors.deepPurple.withValues(alpha: 0.4),
                    blurRadius: 25,
                    offset: const Offset(-3, -4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.color_lens, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Text(
                    "Start Drawing",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          _buildFloatingShapes(),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLogo(),
                _buildMovingImages(),
                _buildQuote(),
                _buildStartButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
