import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../onboarding_controller.dart';

class WeeklyGoalScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const WeeklyGoalScreen({super.key, required this.onNext, this.onBack});

  @override
  ConsumerState<WeeklyGoalScreen> createState() => _WeeklyGoalScreenState();
}

class _WeeklyGoalScreenState extends ConsumerState<WeeklyGoalScreen> {
  double _weeklyGoal = 20.0;

  @override
  void initState() {
    super.initState();
    final currentGoal = ref.read(onboardingControllerProvider).weeklyGoal;
    // Ensure the goal is within our realistic range
    _weeklyGoal = currentGoal.clamp(4, 40).toDouble();
  }

  void _updateGoal(double value) {
    setState(() {
      _weeklyGoal = value;
    });

    ref
        .read(onboardingControllerProvider.notifier)
        .updateWeeklyGoal(value.round());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      'Set Your Weekly Goal',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 20 : null,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),

              SizedBox(height: isSmallScreen ? 12 : 16),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How many Pomodoros would you like to complete each week?',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                          fontSize: isSmallScreen ? 16 : null,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: isSmallScreen ? 8 : 24),

                      // Goal Display
                      Center(
                        child: Container(
                          width: isSmallScreen ? 150 : 200,
                          height: isSmallScreen ? 150 : 200,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.3,
                              ),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _weeklyGoal.round().toString(),
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                  fontSize: isSmallScreen ? 36 : 48,
                                ),
                              ),
                              Text(
                                'Pomodoros',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: isSmallScreen ? 14 : null,
                                ),
                              ),
                              Text(
                                'per week',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                  fontSize: isSmallScreen ? 12 : null,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '(${(_weeklyGoal * 25 / 60).toStringAsFixed(1)} hours)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                  fontSize: isSmallScreen ? 10 : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Slider
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '4',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                  fontSize: isSmallScreen ? 12 : null,
                                ),
                              ),
                              Text(
                                '40',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                  fontSize: isSmallScreen ? 12 : null,
                                ),
                              ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: theme.colorScheme.primary,
                              inactiveTrackColor: theme.colorScheme.outline
                                  .withValues(alpha: 0.3),
                              thumbColor: theme.colorScheme.primary,
                              overlayColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.2),
                              trackHeight: 6,
                              thumbShape: RoundSliderThumbShape(
                                enabledThumbRadius: isSmallScreen ? 10 : 12,
                              ),
                            ),
                            child: Slider(
                              value: _weeklyGoal,
                              min: 4,
                              max: 40,
                              divisions: 36,
                              onChanged: _updateGoal,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isSmallScreen ? 8 : 16),

                      // Goal Suggestions
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(
                              alpha: 0.2,
                            ),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: theme.colorScheme.primary,
                                  size: isSmallScreen ? 18 : 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Goal Suggestions',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                    fontSize: isSmallScreen ? 12 : null,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 12),
                            _buildGoalSuggestion(
                              'Light',
                              '4-8 Pomodoros',
                              '1-2 hours per week',
                              theme,
                              isSmallScreen,
                            ),
                            SizedBox(height: isSmallScreen ? 6 : 8),
                            _buildGoalSuggestion(
                              'Moderate',
                              '12-20 Pomodoros',
                              '3-5 hours per week',
                              theme,
                              isSmallScreen,
                            ),
                            SizedBox(height: isSmallScreen ? 6 : 8),
                            _buildGoalSuggestion(
                              'Intensive',
                              '24-40 Pomodoros',
                              '6-10 hours per week',
                              theme,
                              isSmallScreen,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 20 : 24),

                      // Encouraging Text
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.secondary.withValues(
                              alpha: 0.3,
                            ),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.eco,
                              color: theme.colorScheme.secondary,
                              size: isSmallScreen ? 20 : 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Small goals build big habits. You can adjust this anytime.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.secondary,
                                  fontStyle: FontStyle.italic,
                                  fontSize: isSmallScreen ? 12 : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 20 : 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          child: SizedBox(
            width: double.infinity,
            height: isSmallScreen ? 48 : 56,
            child: FilledButton(
              onPressed: widget.onNext,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Set Goal',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalSuggestion(
    String level,
    String range,
    String description,
    ThemeData theme,
    bool isSmallScreen,
  ) {
    return Row(
      children: [
        Container(
          width: isSmallScreen ? 6 : 8,
          height: isSmallScreen ? 6 : 8,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: isSmallScreen ? 8 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$level: $range',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: isSmallScreen ? 11 : null,
                ),
              ),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: isSmallScreen ? 10 : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
