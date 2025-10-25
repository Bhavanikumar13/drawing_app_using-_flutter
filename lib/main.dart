import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/drawing_screen.dart';
// Remove the coloring game screen import
// import 'screens/coloring_game_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Drawing App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[200],
        useMaterial3: true,
      ),
      // Start with splash screen
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/drawing': (context) => const DrawingScreen(),
        // Remove the coloring game route
        // '/coloring': (context) => const ColoringGameScreen(),
      },
    );
  }
}
