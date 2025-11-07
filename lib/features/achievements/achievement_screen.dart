import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'achievement_service.dart';
import 'achievement_model.dart';
import '../../widgets/empty_state.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen>
    with WidgetsBindingObserver {
  StreamSubscription<List<AchievementModel>>? _achievementsSubscription;
  List<AchievementModel> _achievements = [];
  Map<String, AchievementProgress> _progress = {};
  bool _isLoading = true;
  bool _isLoadingProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAchievements();
    // Start loading progress immediately in parallel
    _loadProgress();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _achievementsSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Reload progress when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _loadProgress();
    }
  }

  void _loadAchievements() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    final achievementService = AchievementService();

    // Listen to achievements stream
    _achievementsSubscription = achievementService
        .streamUserAchievements(currentUser.uid)
        .listen(
          (achievements) {
            if (mounted) {
              setState(() {
                _achievements = achievements;
                _isLoading = false;
              });
              // Reload progress when achievements update
              _loadProgress();
            }
          },
          onError: (error) {
            debugPrint('Error loading achievements from stream: $error');
            // Fallback: load achievements directly
            _loadAchievementsDirectly();
          },
        );

    // Also try to load achievements directly as a fallback
    _loadAchievementsDirectly();
  }

  Future<void> _loadAchievementsDirectly() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final achievementService = AchievementService();
      final achievements = await achievementService.getUserAchievements(
        currentUser.uid,
      );

      if (mounted) {
        setState(() {
          _achievements = achievements;
          _isLoading = false;
        });
        // Reload progress when achievements update
        _loadProgress();
      }
    } catch (e) {
      debugPrint('Error loading achievements directly: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadProgress() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    if (_isLoadingProgress) {
      // Already loading progress, skip
      return;
    }

    setState(() {
      _isLoadingProgress = true;
    });

    try {
      final achievementService = AchievementService();
      final progress = await achievementService.getAllAchievementProgress(
        currentUser.uid,
      );

      if (mounted) {
        setState(() {
          _progress = progress;
          _isLoadingProgress = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading achievement progress: $e');
      if (mounted) {
        setState(() {
          _isLoadingProgress = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Achievements'), elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: _buildAchievementsList(),
            ),
    );
  }

  Widget _buildAchievementsList() {
    final unlockedCount = _achievements.where((a) => a.isUnlocked).length;
    final totalCount = _achievements.length;

    return Column(
      children: [
        // Header with progress
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Text(
                '$unlockedCount of $totalCount unlocked',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: totalCount > 0 ? unlockedCount / totalCount : 0,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),

        // Empty state or achievements list
        Expanded(
          child: _achievements.isEmpty
              ? const EmptyAchievementsState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _achievements.length,
                  itemBuilder: (context, index) {
                    final achievement = _achievements[index];
                    final progress = _progress[achievement.id];

                    return _AchievementCard(
                      achievement: achievement,
                      progress: progress,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final AchievementModel achievement;
  final AchievementProgress? progress;

  const _AchievementCard({required this.achievement, this.progress});

  // Get adjusted color for better contrast based on theme brightness
  Color _getAdjustedColor(BuildContext context, Color baseColor) {
    final brightness = Theme.of(context).brightness;
    // In light mode, darken the color for better contrast
    if (brightness == Brightness.light) {
      final luminance = baseColor.computeLuminance();
      // For very light colors, darken more significantly
      if (luminance > 0.7) {
        return Color.lerp(baseColor, Colors.black, 0.3) ?? baseColor;
      } else if (luminance > 0.5) {
        return Color.lerp(baseColor, Colors.black, 0.2) ?? baseColor;
      } else if (luminance > 0.4) {
        return Color.lerp(baseColor, Colors.black, 0.15) ?? baseColor;
      }
      // For already darker colors, just use as-is
      return baseColor;
    }
    return baseColor;
  }

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked;
    final currentProgress =
        progress ?? AchievementProgress(0, achievement.requiredValue);
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    // Use higher alpha values in light mode for better visibility
    final gradientAlpha1 = isLight ? 0.25 : 0.1;
    final gradientAlpha2 = isLight ? 0.15 : 0.05;
    final borderAlpha = isLight ? 0.5 : 0.3;
    final iconBgAlpha = isLight ? 0.3 : 0.2;
    final adjustedColor = isLight
        ? _getAdjustedColor(context, achievement.color)
        : achievement.color;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isUnlocked
              ? LinearGradient(
                  colors: [
                    adjustedColor.withValues(alpha: gradientAlpha1),
                    adjustedColor.withValues(alpha: gradientAlpha2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          border: isUnlocked
              ? Border.all(
                  color: adjustedColor.withValues(alpha: borderAlpha),
                  width: 1.5,
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Achievement icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? adjustedColor.withValues(alpha: iconBgAlpha)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: isUnlocked
                      ? Border.all(color: adjustedColor, width: 2)
                      : null,
                ),
                child: Icon(
                  achievement.icon,
                  size: 32,
                  color: isUnlocked
                      ? adjustedColor
                      : Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),

              const SizedBox(width: 16),

              // Achievement details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            achievement.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isUnlocked
                                      ? adjustedColor
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                        ),
                        if (isUnlocked)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: adjustedColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'UNLOCKED',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isLight
                                        ? Colors.white
                                        : adjustedColor.computeLuminance() > 0.5
                                        ? Colors.black
                                        : Colors.white,
                                  ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      achievement.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Progress bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            Text(
                              '${currentProgress.current}/${currentProgress.required}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: isUnlocked
                                        ? adjustedColor
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: currentProgress.percentage,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isUnlocked
                                ? adjustedColor
                                : Theme.of(context).colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),

                    // Unlock date
                    if (isUnlocked && achievement.unlockedAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Unlocked ${_formatDate(achievement.unlockedAt!)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: adjustedColor.withValues(
                                  alpha: isLight ? 0.9 : 0.8,
                                ),
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
