import 'package:flutter/material.dart';

void main() {
  runApp(const HealthTimeLineApp());
}

class HealthTimeLineApp extends StatelessWidget {
  const HealthTimeLineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HealthTimeLine',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7DBCE8),
        ),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF6FF),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.health_and_safety_outlined,
                  size: 84,
                  color: Color(0xFF397EAD),
                ),
                const SizedBox(height: 24),
                const Text(
                  'HealthTimeLine',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF204A68),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Personal health tracking and doctor preparation',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.4,
                    color: Color(0xFF506B7D),
                  ),
                ),
                const SizedBox(height: 36),
                FilledButton(
                  onPressed: () {},
                  child: const Text('Get Started'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}