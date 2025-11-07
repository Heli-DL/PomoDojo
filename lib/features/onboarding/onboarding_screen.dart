import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'onboarding_controller.dart';
import '../timer/timer_controller.dart';
import 'screens/welcome_screen.dart';
import 'screens/how_it_works_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/preset_screen.dart';
import 'screens/weekly_goal_screen.dart';
import 'screens/permissions_screen.dart';
import 'screens/celebration_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 6) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding() async {
    await ref.read(onboardingControllerProvider.notifier).completeOnboarding();

    // Reload timer controller settings to pick up Focus Shield setting
    // if DND was enabled during onboarding
    try {
      await ref.read(timerControllerProvider.notifier).reloadSettings();
    } catch (e) {
      // Timer controller might not be initialized yet, that's okay
      debugPrint('Could not reload timer settings: $e');
    }

    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: (page) {
            setState(() {
              _currentPage = page;
            });
          },
          children: [
            WelcomeScreen(onNext: _nextPage),
            HowItWorksScreen(onNext: _nextPage),
            GoalsScreen(onNext: _nextPage, onBack: _previousPage),
            PresetScreen(onNext: _nextPage, onBack: _previousPage),
            WeeklyGoalScreen(onNext: _nextPage, onBack: _previousPage),
            PermissionsScreen(onNext: _nextPage, onBack: _previousPage),
            CelebrationScreen(onComplete: _completeOnboarding),
          ],
        ),
      ),
    );
  }
}
