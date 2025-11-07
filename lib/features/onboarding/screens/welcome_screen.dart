import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onNext;

  const WelcomeScreen({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          child: Column(
            children: [
              SizedBox(height: isSmallScreen ? 20 : 40),

              // App Icon/Logo
              Image.asset(
                'assets/images/logo.png',
                width: isSmallScreen ? 140 : 180,
                fit: BoxFit.contain,
              ),

              SizedBox(height: isSmallScreen ? 24 : 48),

              // Welcome Text
              Text(
                'Welcome to PomoDojo',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  fontSize: isSmallScreen ? 24 : null,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: isSmallScreen ? 12 : 16),

              Text(
                'Your journey to focus and consistency starts now.',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                  fontSize: isSmallScreen ? 16 : null,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: isSmallScreen ? 16 : 24),

              Text(
                'Build better habits, stay consistent, and track your progress with the Pomodoro method.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                  fontSize: isSmallScreen ? 14 : null,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: isSmallScreen ? 24 : 40),

              const Spacer(),

              // Let's Begin Button
              SizedBox(
                width: double.infinity,
                height: isSmallScreen ? 48 : 56,
                child: FilledButton(
                  onPressed: onNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Let\'s Begin',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SizedBox(height: isSmallScreen ? 16 : 24),
            ],
          ),
        ),
      ),
    );
  }
}
