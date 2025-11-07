import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../onboarding_controller.dart';
import '../onboarding_models.dart';

class PresetScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const PresetScreen({super.key, required this.onNext, this.onBack});

  @override
  ConsumerState<PresetScreen> createState() => _PresetScreenState();
}

class _PresetScreenState extends ConsumerState<PresetScreen> {
  PomodoroPreset? _selectedPreset;

  @override
  void initState() {
    super.initState();
    _selectedPreset = ref.read(onboardingControllerProvider).selectedPreset;
  }

  void _selectPreset(PomodoroPreset preset) {
    setState(() {
      _selectedPreset = preset;
    });

    ref.read(onboardingControllerProvider.notifier).updatePreset(preset);
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
                      'Choose your focus session length',
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

              SizedBox(height: isSmallScreen ? 16 : 24),

              // Presets Grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isNarrowScreen ? 1 : 2,
                    crossAxisSpacing: isSmallScreen ? 12 : 16,
                    mainAxisSpacing: isSmallScreen ? 12 : 16,
                    // Make tiles even taller so multi-line text fits comfortably
                    childAspectRatio: isNarrowScreen ? 2.0 : 0.65,
                  ),
                  itemCount: PomodoroPreset.all.length,
                  itemBuilder: (context, index) {
                    final preset = PomodoroPreset.all[index];
                    final isSelected = _selectedPreset?.name == preset.name;

                    return GestureDetector(
                      onTap: () => _selectPreset(preset),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary.withValues(alpha: 0.1)
                              : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withValues(
                                    alpha: 0.3,
                                  ),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.2,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: isNarrowScreen
                                    ? Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          // Timer Icon
                                          Container(
                                            width: isSmallScreen ? 20 : 40,
                                            height: isSmallScreen ? 20 : 40,
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? theme.colorScheme.primary
                                                  : theme.colorScheme.primary
                                                        .withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.timer,
                                              color: isSelected
                                                  ? Colors.white
                                                  : theme.colorScheme.primary,
                                              size: isSmallScreen ? 10 : 20,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Content
                                          Flexible(
                                            fit: FlexFit.loose,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    preset.name,
                                                    style: theme
                                                        .textTheme
                                                        .headlineSmall
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: isSelected
                                                              ? theme
                                                                    .colorScheme
                                                                    .primary
                                                              : theme
                                                                    .colorScheme
                                                                    .onSurface,
                                                          fontSize:
                                                              isSmallScreen
                                                              ? 14
                                                              : 16,
                                                        ),
                                                    maxLines: 3,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    '${preset.focusMinutes} min focus • ${preset.breakMinutes} min break',
                                                    style: theme
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          color: theme
                                                              .colorScheme
                                                              .onSurface
                                                              .withValues(
                                                                alpha: 0.7,
                                                              ),
                                                          fontSize:
                                                              isSmallScreen
                                                              ? 12
                                                              : null,
                                                        ),
                                                    maxLines: 3,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    preset.description,
                                                    style: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: theme
                                                              .colorScheme
                                                              .onSurface
                                                              .withValues(
                                                                alpha: 0.6,
                                                              ),
                                                          fontStyle:
                                                              FontStyle.italic,
                                                          fontSize:
                                                              isSmallScreen
                                                              ? 10
                                                              : null,
                                                        ),
                                                    maxLines: 6,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          // Timer Icon
                                          Center(
                                            child: Container(
                                              width: isSmallScreen ? 50 : 60,
                                              height: isSmallScreen ? 50 : 60,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? theme.colorScheme.primary
                                                    : theme.colorScheme.primary
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.timer,
                                                color: isSelected
                                                    ? Colors.white
                                                    : theme.colorScheme.primary,
                                                size: isSmallScreen ? 25 : 30,
                                              ),
                                            ),
                                          ),

                                          SizedBox(
                                            height: isSmallScreen ? 12 : 16,
                                          ),

                                          // Preset Name
                                          Flexible(
                                            flex: 1,
                                            child: Text(
                                              preset.name,
                                              style: theme
                                                  .textTheme
                                                  .headlineSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: isSelected
                                                        ? theme
                                                              .colorScheme
                                                              .primary
                                                        : theme
                                                              .colorScheme
                                                              .onSurface,
                                                    fontSize: isSmallScreen
                                                        ? 14
                                                        : 16,
                                                  ),
                                              textAlign: TextAlign.center,
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),

                                          SizedBox(
                                            height: isSmallScreen ? 4 : 6,
                                          ),

                                          // Time Details
                                          Flexible(
                                            flex: 1,
                                            child: Text(
                                              '${preset.focusMinutes} min focus\n${preset.breakMinutes} min break',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface
                                                        .withValues(alpha: 0.7),
                                                    fontSize: isSmallScreen
                                                        ? 12
                                                        : null,
                                                  ),
                                              textAlign: TextAlign.center,
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),

                                          SizedBox(
                                            height: isSmallScreen ? 4 : 6,
                                          ),

                                          // Description
                                          Flexible(
                                            flex: 2,
                                            child: Text(
                                              preset.description,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface
                                                        .withValues(alpha: 0.6),
                                                    fontStyle: FontStyle.italic,
                                                    fontSize: isSmallScreen
                                                        ? 10
                                                        : null,
                                                  ),
                                              textAlign: TextAlign.center,
                                              maxLines: 6,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),

                                          // Bottom spacer to balance content
                                          const Spacer(flex: 1),
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
                                      color: theme.colorScheme.primary,
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
                  onPressed: _selectedPreset != null ? widget.onNext : null,
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
                    'Continue',
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
