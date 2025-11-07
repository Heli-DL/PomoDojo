import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../onboarding_models.dart';

class HowItWorksScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const HowItWorksScreen({super.key, required this.onNext});

  @override
  ConsumerState<HowItWorksScreen> createState() => _HowItWorksScreenState();
}

class _HowItWorksScreenState extends ConsumerState<HowItWorksScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < OnboardingStep.howItWorks.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onNext();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    IconButton(
                      onPressed: _previousStep,
                      icon: Icon(Icons.arrow_back),
                    ),
                  Expanded(
                    child: Text(
                      'How It Works',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 20 : null,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (_currentStep > 0) const SizedBox(width: 48),
                ],
              ),
            ),

            // Progress Indicator
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 24,
              ),
              child: Row(
                children: List.generate(
                  OnboardingStep.howItWorks.length,
                  (index) => Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(
                        right: index < OnboardingStep.howItWorks.length - 1
                            ? 8
                            : 0,
                      ),
                      decoration: BoxDecoration(
                        color: index <= _currentStep
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: isSmallScreen ? 16 : 32),

            // Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentStep = page;
                  });
                },
                itemCount: OnboardingStep.howItWorks.length,
                itemBuilder: (context, index) {
                  final step = OnboardingStep.howItWorks[index];
                  return _buildStepContent(step, theme, isSmallScreen);
                },
              ),
            ),

            // Navigation
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 12 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: _currentStep > 0 ? 1 : 1,
                    child: SizedBox(
                      height: isSmallScreen ? 48 : 56,
                      child: FilledButton(
                        onPressed: _nextStep,
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _currentStep == OnboardingStep.howItWorks.length - 1
                              ? 'Get Started'
                              : 'Next',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _buildStepContent(
    OnboardingStep step,
    ThemeData theme,
    bool isSmallScreen,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Add slight top spacing to move images down
            SizedBox(height: isSmallScreen ? 12 : 16),
            // Icon (remove circle for focus/rest and use images)
            if (step.id == 'focus')
              Image.asset(
                'assets/images/monkey_meditating.png',
                width: isSmallScreen ? 140 : 180,
                height: isSmallScreen ? 140 : 180,
                fit: BoxFit.contain,
              )
            else if (step.id == 'rest')
              Image.asset(
                'assets/images/monkey_sleeping.png',
                width: isSmallScreen ? 140 : 180,
                height: isSmallScreen ? 140 : 180,
                fit: BoxFit.contain,
              )
            else if (step.id == 'grow')
              Image.asset(
                'assets/images/monkey_laughing.png',
                width: isSmallScreen ? 140 : 180,
                height: isSmallScreen ? 140 : 180,
                fit: BoxFit.contain,
              )
            else
              Container(
                width: isSmallScreen ? 80 : 120,
                height: isSmallScreen ? 80 : 120,
                decoration: BoxDecoration(
                  color: step.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: step.color.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  step.icon,
                  size: isSmallScreen ? 40 : 60,
                  color: step.color,
                ),
              ),

            SizedBox(height: isSmallScreen ? 16 : 32),

            // Title
            Text(
              step.title,
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: step.color,
                fontSize: isSmallScreen ? 20 : null,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: isSmallScreen ? 16 : 24),

            // Description
            Text(
              step.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
                fontSize: isSmallScreen ? 14 : null,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: isSmallScreen ? 16 : 32),

            // Visual Element
            _buildVisualElement(step, theme, isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualElement(
    OnboardingStep step,
    ThemeData theme,
    bool isSmallScreen,
  ) {
    final containerWidth = isSmallScreen ? 150.0 : 200.0;
    final containerHeight = isSmallScreen ? 80.0 : 120.0;
    final iconSize = isSmallScreen ? 30.0 : 40.0;

    switch (step.id) {
      case 'focus':
        return Container(
          width: containerWidth,
          height: containerHeight,
          decoration: BoxDecoration(
            color: step.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: step.color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer, size: iconSize, color: step.color),
              const SizedBox(height: 8),
              Text(
                '25 min',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: step.color,
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 14 : null,
                ),
              ),
            ],
          ),
        );
      case 'rest':
        return Container(
          width: containerWidth,
          height: containerHeight,
          decoration: BoxDecoration(
            color: step.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: step.color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.coffee, size: iconSize, color: step.color),
              const SizedBox(height: 8),
              Text(
                '5 min',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: step.color,
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 14 : null,
                ),
              ),
            ],
          ),
        );
      case 'grow':
        return Container(
          width: containerWidth,
          height: containerHeight,
          decoration: BoxDecoration(
            color: step.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: step.color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, size: iconSize, color: step.color),
              const SizedBox(height: 8),
              Text(
                'Achievements',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: step.color,
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 14 : null,
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
