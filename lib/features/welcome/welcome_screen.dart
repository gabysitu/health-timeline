import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../authentication/login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.health_and_safety_outlined,
                size: 90,
                color: AppColors.primaryDark,
              ),
              const SizedBox(height: 28),
              const Text(
                'HealthTimeLine',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Track your health, understand your patterns, and prepare for your doctor appointments.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 40),
              FilledButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  },
  child: const Text('Get Started'),
),
            ],
          ),
        ),
      ),
    );
  }
}