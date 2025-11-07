import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../onboarding_controller.dart';
import '../onboarding_models.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const GoalsScreen({super.key, required this.onNext, this.onBack});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  final List<String> _selectedGoals = [];

  @override
  void initState() {
    super.initState();
    _selectedGoals.addAll(ref.read(onboardingControllerProvider).selectedGoals);
  }

  void _toggleGoal(String goalId) {
    setState(() {
      if (_selectedGoals.contains(goalId)) {
        _selectedGoals.remove(goalId);
      } else {
        _selectedGoals.add(goalId);
      }
    });

    ref.read(onboardingControllerProvider.notifier).updateGoals(_selectedGoals);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isNarrowScreen = screenWidth < 400;

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
                      'What\'s your main goal?',
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

              // Goals Grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isNarrowScreen ? 1 : 2,
                    crossAxisSpacing: isSmallScreen ? 12 : 16,
                    mainAxisSpacing: isSmallScreen ? 12 : 16,
                    childAspectRatio: isNarrowScreen ? 3.0 : 0.85,
                  ),
                  itemCount: OnboardingGoal.all.length,
                  itemBuilder: (context, index) {
                    final goal = OnboardingGoal.all[index];
                    final isSelected = _selectedGoals.contains(goal.id);

                    return GestureDetector(
                      onTap: () => _toggleGoal(goal.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? goal.color.withValues(alpha: 0.1)
                              : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? goal.color
                                : theme.colorScheme.outline.withValues(
                                    alpha: 0.3,
                                  ),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: goal.color.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: isSmallScreen ? 2 : 4,
                            bottom: isSmallScreen ? 4 : 8,
                            left: isSmallScreen ? 4 : 8,
                            right: isSmallScreen ? 4 : 8,
                          ),
                          child: isNarrowScreen
                              ? Row(
                                  children: [
                                    // Icon
                                    Container(
                                      width: isSmallScreen ? 40 : 48,
                                      height: isSmallScreen ? 40 : 48,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? goal.color
                                            : goal.color.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        goal.icon,
                                        color: isSelected
                                            ? Colors.white
                                            : goal.color,
                                        size: isSmallScreen ? 20 : 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              goal.title,
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: isSelected
                                                        ? goal.color
                                                        : theme
                                                              .colorScheme
                                                              .onSurface,
                                                    fontSize: isSmallScreen
                                                        ? 14
                                                        : null,
                                                  ),
                                              maxLines: 4,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Flexible(
                                            flex: 2,
                                            child: Text(
                                              goal.description,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface
                                                        .withValues(alpha: 0.6),
                                                    fontSize: isSmallScreen
                                                        ? 11
                                                        : null,
                                                  ),
                                              maxLines: 4,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Selection indicator
                                    if (isSelected)
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: goal.color,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ),
                                  ],
                                )
                              : Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          // Icon
                                          Center(
                                            child: Container(
                                              width: isSmallScreen ? 40 : 48,
                                              height: isSmallScreen ? 40 : 48,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? goal.color
                                                    : goal.color.withValues(
                                                        alpha: 0.1,
                                                      ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                goal.icon,
                                                color: isSelected
                                                    ? Colors.white
                                                    : goal.color,
                                                size: isSmallScreen ? 20 : 24,
                                              ),
                                            ),
                                          ),

                                          SizedBox(
                                            height: isSmallScreen ? 4 : 8,
                                          ),

                                          // Title
                                          Flexible(
                                            child: Text(
                                              goal.title,
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: isSelected
                                                        ? goal.color
                                                        : theme
                                                              .colorScheme
                                                              .onSurface,
                                                    fontSize: isSmallScreen
                                                        ? 12
                                                        : null,
                                                  ),
                                              textAlign: TextAlign.center,
                                              maxLines: 4,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),

                                          SizedBox(
                                            height: isSmallScreen ? 8 : 16,
                                          ),

                                          // Description
                                          Flexible(
                                            flex: 2,
                                            child: Text(
                                              goal.description,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface
                                                        .withValues(alpha: 0.6),
                                                    fontSize: isSmallScreen
                                                        ? 10
                                                        : null,
                                                  ),
                                              textAlign: TextAlign.center,
                                              maxLines: 4,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Selection indicator - positioned in top-right
                                    if (isSelected)
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: goal.color,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 12,
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
              ),

              SizedBox(height: isSmallScreen ? 16 : 24),

              // Next Button
              SizedBox(
                width: double.infinity,
                height: isSmallScreen ? 48 : 56,
                child: FilledButton(
                  onPressed: _selectedGoals.isNotEmpty ? widget.onNext : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Next',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
