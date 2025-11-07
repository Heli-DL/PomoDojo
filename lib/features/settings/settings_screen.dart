import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/theme_controller.dart';
import '../auth/auth_service.dart';
import '../timer/timer_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../progression/progression_controller.dart';
import '../progression/progression_model.dart';
import '../progression/martial_rank.dart';
import '../progression/progression_celebration_service.dart';
import '../onboarding/onboarding_controller.dart';
import '../auth/user_repository.dart';
import '../auth/user_model.dart';
import '../achievements/achievement_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  AppLifecycleListener? _lifecycleListener;
  int _dndRefreshNonce = 0;

  @override
  void initState() {
    super.initState();
    // App lifecycle (new API)
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        if (!mounted) return;
        setState(() => _dndRefreshNonce++);
        // Samsung/OEMs can delay reporting permission changes; refresh a few times
        for (int i = 1; i <= 5; i++) {
          Future.delayed(Duration(milliseconds: 300 * i), () {
            if (mounted) setState(() => _dndRefreshNonce++);
          });
        }
      },
    );
    // Legacy observer for wider device compatibility
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() => _dndRefreshNonce++);
      for (int i = 1; i <= 5; i++) {
        Future.delayed(Duration(milliseconds: 300 * i), () {
          if (mounted) setState(() => _dndRefreshNonce++);
        });
      }
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = AuthService();
    final currentUser = FirebaseAuth.instance.currentUser;
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

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          progressionAsync.when(
            data: (progression) =>
                _buildUserInfoCard(context, currentUser, progression),
            loading: () => _buildUserInfoCard(
              context,
              currentUser,
              const ProgressionModel(
                level: 1,
                xp: 0,
                totalSessions: 0,
                rank: MartialRank.novice,
              ),
            ),
            error: (_, _) => _buildUserInfoCard(
              context,
              currentUser,
              const ProgressionModel(
                level: 1,
                xp: 0,
                totalSessions: 0,
                rank: MartialRank.novice,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Theme',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.phone_android),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode),
              ),
            ],
            selected: {ref.watch(themeModeProvider)},
            onSelectionChanged: (s) =>
                ref.read(themeModeProvider.notifier).setThemeMode(s.first),
          ),
          const SizedBox(height: 32),
          _buildFocusShieldSection(context, ref),
          const SizedBox(height: 32),
          _buildTestCelebrationsSection(context),
          const SizedBox(height: 32),
          Text(
            'Account',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(
              'Sign Out',
              style: GoogleFonts.leagueSpartan(fontSize: 16),
            ),
            subtitle: const Text('Sign out of your account'),
            onTap: () async {
              try {
                await authService.signOut();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Signed out successfully')),
                  );
                  // Router will automatically redirect to login screen
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sign out failed: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(
    BuildContext context,
    User? currentUser,
    ProgressionModel progression,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              child: currentUser?.photoURL != null
                  ? ClipOval(
                      child: Image.network(
                        currentUser!.photoURL!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const CircularProgressIndicator();
                        },
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.person,
                          size: 40,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 40,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
            ),

            const SizedBox(width: 16),

            // User Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentUser?.displayName ?? currentUser?.email ?? 'User',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentUser?.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: progression.rank.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: progression.rank.color,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          progression.rank.icon,
                          size: 14,
                          color: progression.rank.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          progression.rank.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: progression.rank.color,
                          ),
                        ),
                      ],
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

  Widget _buildFocusShieldSection(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timerController = ref.read(timerControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Focus Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              // Focus Shield Toggle
              Semantics(
                label: 'Focus Shield',
                hint:
                    'Toggle to automatically enable Do Not Disturb during focus sessions',
                child: SwitchListTile(
                  title: Text(
                    'Enable Focus Shield',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: const Text(
                    'Automatically enable Do Not Disturb during focus sessions',
                  ),
                  value: ref.watch(timerControllerProvider).focusShieldEnabled,
                  onChanged: (value) async {
                    await timerController.setFocusShieldEnabled(value);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value
                                ? 'Focus Shield enabled'
                                : 'Focus Shield disabled',
                          ),
                        ),
                      );
                    }
                  },
                  secondary: const Icon(Icons.shield),
                ),
              ),

              // DND Permission Check
              if (ref.watch(timerControllerProvider).focusShieldEnabled) ...[
                Semantics(
                  label: 'DND Permission Status',
                  child: _buildDNDPermissionTile(context, ref, timerController),
                ),
              ],

              const Divider(),

              // Session Notifications Toggle
              Semantics(
                label: 'Session Notifications',
                hint: 'Toggle to receive notifications when focus sessions end',
                child: SwitchListTile(
                  title: Text(
                    'Session Complete Notifications',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: const Text('Get notified when focus sessions end'),
                  value: ref
                      .watch(timerControllerProvider)
                      .sessionNotificationsEnabled,
                  onChanged: (value) async {
                    await timerController.setSessionNotificationsEnabled(value);
                  },
                  secondary: const Icon(Icons.notifications),
                ),
              ),

              // Break Notifications Toggle
              Semantics(
                label: 'Break Notifications',
                hint: 'Toggle to receive notifications when breaks end',
                child: SwitchListTile(
                  title: Text(
                    'Break Over Notifications',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: const Text('Get notified when breaks end'),
                  value: ref
                      .watch(timerControllerProvider)
                      .breakNotificationsEnabled,
                  onChanged: (value) async {
                    await timerController.setBreakNotificationsEnabled(value);
                  },
                  secondary: const Icon(Icons.notifications),
                ),
              ),

              const Divider(),

              // Test Notification Button
              // Notification permissions
              ListTile(
                leading: const Icon(Icons.notifications),
                title: Text(
                  'Notification Permissions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: const Text('Open Android notification settings'),
                onTap: () async {
                  try {
                    // Request notification permission
                    final flutterLocalNotifications =
                        FlutterLocalNotificationsPlugin();
                    final result = await flutterLocalNotifications
                        .resolvePlatformSpecificImplementation<
                          AndroidFlutterLocalNotificationsPlugin
                        >()
                        ?.requestNotificationsPermission();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            result == true
                                ? 'Notification permission granted!'
                                : 'Please enable notifications in Android settings',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error requesting permission: $e'),
                        ),
                      );
                    }
                  }
                },
              ),

              const Divider(),

              // Auto-start Sessions Toggle
              SwitchListTile(
                title: Text(
                  'Auto-start Sessions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: const Text(
                  'Automatically start next session in Pomodoro cycles',
                ),
                value: ref.watch(timerControllerProvider).autoStartEnabled,
                onChanged: (value) async {
                  await timerController.setAutoStartEnabled(value);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? 'Auto-start enabled - sessions will continue automatically'
                              : 'Auto-start disabled - manual start required',
                        ),
                      ),
                    );
                  }
                },
                secondary: const Icon(Icons.play_arrow),
              ),
            ],
          ),
        ),

        // Weekly Goal Section
        const SizedBox(height: 32),
        Text(
          'Weekly Goal',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildWeeklyGoalSection(context, ref),

        // Debug Section (only show in debug mode)
        if (kDebugMode) ...[
          const SizedBox(height: 32),
          Text(
            'Debug',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.refresh, color: Colors.orange),
                  title: Text(
                    'Reset Onboarding',
                    style: GoogleFonts.leagueSpartan(fontSize: 16),
                  ),
                  subtitle: const Text(
                    'Reset onboarding completion status (for testing)',
                  ),
                  onTap: () async {
                    await OnboardingController.resetOnboarding();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Onboarding reset - restart app to see changes',
                          ),
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.emoji_events, color: Colors.red),
                  title: Text(
                    'Reset Achievements',
                    style: GoogleFonts.leagueSpartan(fontSize: 16),
                  ),
                  subtitle: const Text(
                    'Clear all unlocked achievements (for testing)',
                  ),
                  onTap: () async {
                    final currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser != null) {
                      try {
                        await AchievementService.resetUserAchievements(
                          currentUser.uid,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'All achievements reset - restart app to see changes',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to reset achievements: ${e.toString()}',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.trending_up, color: Colors.blue),
                  title: Text(
                    'Set XP / Level',
                    style: GoogleFonts.leagueSpartan(fontSize: 16),
                  ),
                  subtitle: const Text(
                    'Manually set your XP (level and rank will be calculated)',
                  ),
                  onTap: () async {
                    await _showSetXPDialog(context, ref);
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDNDPermissionTile(
    BuildContext context,
    WidgetRef ref,
    TimerController timerController,
  ) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool refreshing = false;
        return FutureBuilder<bool>(
          key: ValueKey(_dndRefreshNonce),
          future: timerController.hasDNDPermission(),
          builder: (context, snapshot) {
            final hasPermission = snapshot.data ?? false;
            return ListTile(
              leading: Icon(
                hasPermission ? Icons.check_circle : Icons.warning,
                color: hasPermission ? Colors.green : Colors.orange,
              ),
              title: Text(
                hasPermission
                    ? 'DND Permission Granted'
                    : 'DND Permission Required',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(
                hasPermission
                    ? 'Focus Shield can control Do Not Disturb'
                    : 'Tap to open Android settings and grant "Do Not Disturb" access',
              ),
              trailing: hasPermission
                  ? null
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: refreshing
                          ? const SizedBox(
                              key: ValueKey('spinner'),
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              key: const ValueKey('refresh'),
                              icon: const Icon(Icons.refresh),
                              onPressed: () async {
                                setState(() => refreshing = true);
                                final granted = await timerController
                                    .hasDNDPermission();
                                if (!context.mounted) return;
                                // Force rebuilds
                                setState(() => refreshing = false);
                                final outer = context
                                    .findAncestorStateOfType<
                                      _SettingsScreenState
                                    >();
                                outer?.setState(() => outer._dndRefreshNonce++);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      granted
                                          ? 'DND permission is granted'
                                          : 'DND permission still required',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              tooltip: 'Refresh permission status',
                            ),
                    ),
              onTap: hasPermission
                  ? null
                  : () async {
                      final success = await timerController.openDNPSettings();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Opening DND settings...'
                                  : 'Failed to open DND settings',
                            ),
                          ),
                        );
                        // Poll for permission up to ~10 seconds after returning
                        if (success) {
                          for (int i = 0; i < 10; i++) {
                            await Future.delayed(const Duration(seconds: 1));
                            final granted = await timerController
                                .hasDNDPermission();
                            if (!context.mounted) break;
                            if (granted) {
                              // Force rebuilds
                              final outer = context
                                  .findAncestorStateOfType<
                                    _SettingsScreenState
                                  >();
                              outer?.setState(() => outer._dndRefreshNonce++);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('DND permission granted!'),
                                ),
                              );
                              break;
                            }
                          }
                        }
                      }
                    },
            );
          },
        );
      },
    );
  }

  Widget _buildWeeklyGoalSection(BuildContext context, WidgetRef ref) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set how many Pomodoros you want to complete each week',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildWeeklyGoalSlider(context, ref, currentUser.uid),
          ],
        ),
      ),
    );
  }

  Future<void> _showSetXPDialog(BuildContext context, WidgetRef ref) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final progressionAsync = ref.watch(
      userProgressionStreamProvider(currentUser.uid),
    );
    final currentXP = progressionAsync.maybeWhen(
      data: (progression) => progression.xp,
      orElse: () => 0,
    );
    final currentLevel = progressionAsync.maybeWhen(
      data: (progression) => progression.level,
      orElse: () => 1,
    );
    final currentRank = progressionAsync.maybeWhen(
      data: (progression) => progression.rank.name,
      orElse: () => 'Novice',
    );

    final xpController = TextEditingController(text: currentXP.toString());
    final levelController = TextEditingController(
      text: currentLevel.toString(),
    );

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Set XP / Level'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current: Level $currentLevel, $currentXP XP, $currentRank',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: xpController,
              decoration: const InputDecoration(
                labelText: 'XP (0-100000)',
                hintText: 'Enter XP value',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: levelController,
              decoration: const InputDecoration(
                labelText: 'Level (1-100)',
                hintText: 'Enter level',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            Text(
              'Note: Entering XP will calculate level automatically. '
              'Entering level will set minimum XP for that level.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final xpText = xpController.text.trim();
              final levelText = levelController.text.trim();

              try {
                final userRepository = UserRepository();
                int xpToSet;

                if (xpText.isNotEmpty && xpText != '0') {
                  xpToSet = int.parse(xpText);
                  if (xpToSet < 0) {
                    throw Exception('XP cannot be negative');
                  }
                  if (xpToSet > 100000) {
                    throw Exception('XP cannot exceed 100000');
                  }
                } else if (levelText.isNotEmpty && levelText != '0') {
                  final targetLevel = int.parse(levelText);
                  if (targetLevel < 1 || targetLevel > 100) {
                    throw Exception('Level must be between 1 and 100');
                  }
                  // Calculate minimum XP for that level
                  xpToSet = ProgressionModel.xpForLevel(targetLevel);
                } else {
                  throw Exception('Please enter either XP or Level');
                }

                await userRepository.setXP(currentUser.uid, xpToSet);

                // Refresh progression
                await ref
                    .read(progressionControllerProvider.notifier)
                    .refreshProgression();

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                  final newLevel = ProgressionModel.levelFromXP(xpToSet);
                  final newRank = MartialRank.fromLevel(newLevel);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'XP set to $xpToSet → Level $newLevel, ${newRank.name}',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyGoalSlider(
    BuildContext context,
    WidgetRef ref,
    String uid,
  ) {
    return StreamBuilder<UserModel?>(
      stream: UserRepository().streamUser(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final user = snapshot.data!;
        final currentGoal = user.weeklyGoal.toDouble();

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${currentGoal.round()} Pomodoros',
                    style: GoogleFonts.leagueSpartan(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(currentGoal * 25 / 60).toStringAsFixed(1)} hours',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: currentGoal,
              min: 4,
              max: 40,
              divisions: 36,
              label: '${currentGoal.round()} Pomodoros',
              onChanged: (value) async {
                try {
                  // Updating weekly goal
                  await UserRepository().updateWeeklyGoal(uid, value.round());
                } catch (e) {
                  debugPrint('Failed to update weekly goal: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update weekly goal: $e'),
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Light\n(4-8)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Moderate\n(12-20)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Intensive\n(24-40)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTestCelebrationsSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Test Celebrations',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Test different celebration screens to see how they look',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              // Level Up Test Button
              ListTile(
                leading: const Icon(Icons.trending_up, color: Colors.blue),
                title: const Text('Test Level Up'),
                subtitle: const Text('Show level up celebration'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ProgressionCelebrationService.showLevelUp(
                    context,
                    newLevel: 5,
                    newXp: 250,
                  );
                },
              ),
              const Divider(height: 1),
              // Rank Up Test Buttons
              ExpansionTile(
                leading: const Icon(Icons.military_tech, color: Colors.orange),
                title: const Text('Test Rank Up'),
                subtitle: const Text('Choose a rank to test'),
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.person_outline,
                      color: MartialRank.novice.color,
                    ),
                    title: Text(MartialRank.novice.name),
                    onTap: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          ProgressionCelebrationService.showRankUp(
                            context,
                            newRank: MartialRank.novice,
                            newLevel: 2,
                          );
                        }
                      });
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.person,
                      color: MartialRank.apprentice.color,
                    ),
                    title: Text(MartialRank.apprentice.name),
                    onTap: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          ProgressionCelebrationService.showRankUp(
                            context,
                            newRank: MartialRank.apprentice,
                            newLevel: 3,
                          );
                        }
                      });
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.self_improvement,
                      color: MartialRank.disciple.color,
                    ),
                    title: Text(MartialRank.disciple.name),
                    onTap: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          ProgressionCelebrationService.showRankUp(
                            context,
                            newRank: MartialRank.disciple,
                            newLevel: 5,
                          );
                        }
                      });
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.star, color: MartialRank.adept.color),
                    title: Text(MartialRank.adept.name),
                    onTap: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          ProgressionCelebrationService.showRankUp(
                            context,
                            newRank: MartialRank.adept,
                            newLevel: 7,
                          );
                        }
                      });
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.military_tech,
                      color: MartialRank.master.color,
                    ),
                    title: Text(MartialRank.master.name),
                    onTap: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          ProgressionCelebrationService.showRankUp(
                            context,
                            newRank: MartialRank.master,
                            newLevel: 9,
                          );
                        }
                      });
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.emoji_events,
                      color: MartialRank.grandmaster.color,
                    ),
                    title: Text(MartialRank.grandmaster.name),
                    onTap: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          ProgressionCelebrationService.showRankUp(
                            context,
                            newRank: MartialRank.grandmaster,
                            newLevel: 11,
                          );
                        }
                      });
                    },
                  ),
                ],
              ),
              const Divider(height: 1),
              // Background Unlock Test Button
              ListTile(
                leading: const Icon(Icons.image, color: Colors.purple),
                title: const Text('Test Background Unlock'),
                subtitle: const Text('Show background unlock celebration'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ProgressionCelebrationService.showBackgroundUnlock(
                    context,
                    backgroundNumber: 5,
                    level: 6,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
