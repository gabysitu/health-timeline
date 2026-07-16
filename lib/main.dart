
//Import the other packages
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/welcome/welcome_screen.dart';

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
      theme: AppTheme.lightTheme,
      home: const WelcomeScreen(),
        );
  }
}