import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../auth/user_model.dart';
import '../auth/user_repository.dart';
import 'widgets/character_section.dart';
import 'widgets/progression_card.dart';
import 'widgets/statistics_section.dart';
import '../progression/progression_controller.dart';
import '../progression/progression_model.dart';
import '../progression/martial_rank.dart';
import '../statistics/stats_controller.dart';
import '../statistics/stats_model.dart';
import '../achievements/achievement_service.dart';
import '../achievements/achievement_model.dart';
import '../../widgets/error_state.dart';

final characterUserStreamProvider = StreamProvider.family<UserModel?, String>((
  ref,
  uid,
) {
  final userRepository = UserRepository();
  return userRepository.streamUser(uid);
});

final userAchievementsProvider =
    StreamProvider.family<List<AchievementModel>, String>((ref, uid) {
      final achievementService = AchievementService();
      return achievementService.streamUserAchievements(uid);
    });

class CharacterScreen extends ConsumerStatefulWidget {
  const CharacterScreen({super.key});

  @override
  ConsumerState<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends ConsumerState<CharacterScreen> {
  @override
  Widget build(BuildContext context) {
    final weeklyStats = ref.watch(weeklyStatsProvider);
    final currentUser = FirebaseAuth.instance.currentUser;
    final userAsync = currentUser != null
        ? ref.watch(characterUserStreamProvider(currentUser.uid))
        : const AsyncValue<UserModel?>.data(null);
    final progressionAsync = currentUser != null
        ? ref.watch(userProgressionStreamProvider(currentUser.uid))
        : const AsyncValue<ProgressionModel>.data(
            ProgressionModel(
              level: 1,
              xp: 0,
              totalSessions: 0,
              rank: MartialRank.novice,
            ),
          );
    final achievementsAsync = currentUser != null
        ? ref.watch(userAchievementsProvider(currentUser.uid))
        : const AsyncValue<List<AchievementModel>>.data([]);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Character',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (currentUser != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditDialog(context, ref, currentUser.uid),
            ),
        ],
      ),
      body: userAsync.when(
        data: (userModel) => weeklyStats.when(
          data: (stats) => progressionAsync.when(
            data: (progression) {
              debugPrint(
                'Character Screen - Progression data: totalSessions=${progression.totalSessions}, xp=${progression.xp}, level=${progression.level}',
              );
              return achievementsAsync.when(
                data: (achievements) => _buildCharacterContent(
                  progression,
                  userModel,
                  stats,
                  achievements,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => ErrorState(
                  title: 'Failed to Load Achievements',
                  message: ErrorMessageHelper.getUserFriendlyMessage(error),
                  details: ErrorMessageHelper.getErrorDetails(error),
                  onRetry: () => ref.invalidate(
                    userAchievementsProvider(currentUser!.uid),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => ErrorState(
              title: 'Failed to Load Progression',
              message: ErrorMessageHelper.getUserFriendlyMessage(error),
              details: ErrorMessageHelper.getErrorDetails(error),
              onRetry: () => ref.invalidate(
                userProgressionStreamProvider(currentUser!.uid),
              ),
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => ErrorState(
            title: 'Failed to Load Statistics',
            message: ErrorMessageHelper.getUserFriendlyMessage(error),
            details: ErrorMessageHelper.getErrorDetails(error),
            onRetry: () => ref.invalidate(weeklyStatsProvider),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorState(
          title: 'Failed to Load Character Data',
          message: ErrorMessageHelper.getUserFriendlyMessage(error),
          details: ErrorMessageHelper.getErrorDetails(error),
          onRetry: () =>
              ref.invalidate(characterUserStreamProvider(currentUser!.uid)),
        ),
      ),
    );
  }

  Widget _buildCharacterContent(
    ProgressionModel progression,
    UserModel? userModel,
    WeeklyStats stats,
    List<AchievementModel> achievements,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Character Image Section
          CharacterImageSection(
            progression: progression,
            userModel: userModel,
            height: 200,
          ),

          const SizedBox(height: 24),

          // Character Progression Card
          CharacterProgressionCard(progression: progression),

          const SizedBox(height: 24),

          // Weekly Goal Progress Section
          if (userModel != null) _buildWeeklyGoalProgress(userModel),

          const SizedBox(height: 24),

          // Statistics Section
          Builder(
            builder: (context) {
              debugPrint(
                'Character Screen - Progression: totalSessions=${progression.totalSessions}, xp=${progression.xp}, level=${progression.level}',
              );
              return StatisticsSection(
                progression: progression,
                userModel: userModel,
                weeklyStats: stats,
              );
            },
          ),
          const SizedBox(height: 24),
          _buildAchievementsSection(achievements),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(List<AchievementModel> achievements) {
    final theme = Theme.of(context);

    // Get unlocked achievements sorted by unlock date (most recent first)
    final unlockedAchievements =
        achievements.where((achievement) => achievement.isUnlocked).toList()
          ..sort(
            (a, b) => (b.unlockedAt ?? DateTime(1970)).compareTo(
              a.unlockedAt ?? DateTime(1970),
            ),
          );

    // Get the latest achievement
    final latestAchievement = unlockedAchievements.isNotEmpty
        ? unlockedAchievements.first
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Latest Achievement',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/achievements'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (latestAchievement != null) ...[
          // Latest Achievement Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  latestAchievement.color.withValues(alpha: 0.1),
                  latestAchievement.color.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: latestAchievement.color.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Achievement Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: latestAchievement.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: latestAchievement.color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    latestAchievement.icon,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),

                // Achievement Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        latestAchievement.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: latestAchievement.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        latestAchievement.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: latestAchievement.color,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Unlocked ${_formatDate(latestAchievement.unlockedAt!)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: latestAchievement.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // No achievements yet
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 48,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'No achievements yet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete your first Pomodoro session to unlock achievements!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
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
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    }
  }

  Widget _buildWeeklyGoalProgress(UserModel userModel) {
    final theme = Theme.of(context);

    return Consumer(
      builder: (context, ref, child) {
        final weeklyGoalProgressAsync = ref.watch(
          weeklyGoalProgressProvider((
            uid: userModel.uid,
            weeklyGoal: userModel.weeklyGoal,
          )),
        );

        return weeklyGoalProgressAsync.when(
          data: (progress) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.flag,
                        color: progress.isCompleted
                            ? Colors.green
                            : progress.isOnTrack
                            ? Colors.blue
                            : Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Weekly Goal Progress',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${progress.weekStart.day}/${progress.weekStart.month} - ${progress.weekEnd.day}/${progress.weekEnd.month}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              progress.progressText,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: progress.isCompleted
                                    ? Colors.green
                                    : theme.colorScheme.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(progress.progress * 100).round()}%',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: progress.isCompleted
                                  ? Colors.green
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress.progress,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress.isCompleted
                              ? Colors.green
                              : progress.isOnTrack
                              ? Colors.blue
                              : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              progress.isCompleted
                                  ? '🎉 Goal completed!'
                                  : progress.isOnTrack
                                  ? '🔥 On track!'
                                  : '💪 Keep going!',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: progress.isCompleted
                                    ? Colors.green
                                    : progress.isOnTrack
                                    ? Colors.blue
                                    : Colors.orange,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!progress.isCompleted) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                progress.remainingText,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          loading: () => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 16),
                  Text(
                    'Loading weekly goal progress...',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          error: (error, stack) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.error, color: theme.colorScheme.error),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Failed to load weekly goal progress',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, String uid) {
    final userAsync = ref.read(characterUserStreamProvider(uid));
    userAsync.whenData((userModel) {
      if (userModel == null) return;

      showDialog(
        context: context,
        builder: (dialogContext) => _CharacterEditDialog(
          userModel: userModel,
          onBackgroundChanged: (backgroundNumber) async {
            final userRepository = UserRepository();
            await userRepository.updateSelectedBackground(
              uid,
              backgroundNumber,
            );
            ref.invalidate(characterUserStreamProvider(uid));
          },
          onNameChanged: (name) async {
            final userRepository = UserRepository();
            await userRepository.updateCharacterName(uid, name);
            ref.invalidate(characterUserStreamProvider(uid));
          },
        ),
      );
    });
  }
}

class _CharacterEditDialog extends StatefulWidget {
  final UserModel userModel;
  final Function(int) onBackgroundChanged;
  final Function(String?) onNameChanged;

  const _CharacterEditDialog({
    required this.userModel,
    required this.onBackgroundChanged,
    required this.onNameChanged,
  });

  @override
  State<_CharacterEditDialog> createState() => _CharacterEditDialogState();
}

class _CharacterEditDialogState extends State<_CharacterEditDialog> {
  late TextEditingController _nameController;
  int _selectedBackground = 1;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.userModel.characterName ?? '',
    );
    _selectedBackground = widget.userModel.selectedBackground;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlocked = widget.userModel.unlockedBackgrounds;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Character',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Character Name Field
              Text(
                'Character Name',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter character name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  widget.onNameChanged(value.isEmpty ? null : value);
                },
              ),
              const SizedBox(height: 24),

              // Background Selection
              Text(
                'Select Background',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Unlocked: ${unlocked.length} / 20',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              // Background Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemCount: unlocked.length,
                itemBuilder: (context, index) {
                  final bgNum = unlocked[index];
                  final isSelected = bgNum == _selectedBackground;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedBackground = bgNum;
                      });
                      widget.onBackgroundChanged(bgNum);
                    },
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 48, // WCAG 2.2 minimum tap target
                        minHeight: 48, // WCAG 2.2 minimum tap target
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                'assets/images/backgrounds/background_$bgNum.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                    ),
                                  );
                                },
                              ),
                              if (isSelected)
                                Container(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
