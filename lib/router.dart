import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'home_screen.dart';
import 'features/character/character_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/statistics/stats_screen.dart';
import 'features/tasks/tasks_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/user_model.dart';
import 'features/auth/user_repository.dart';
import 'features/timer/timer_mode_screen.dart';
import 'widgets/central_button.dart';
import 'features/achievements/achievement_screen.dart';
import 'features/topics/topic_selection_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/onboarding/onboarding_controller.dart';
import 'features/splash/splash_screen.dart';
import 'features/timer/timer_controller.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final userStreamProvider = StreamProvider.family<UserModel?, String>((
  ref,
  uid,
) {
  final userRepository = UserRepository();
  return userRepository.streamUser(uid);
});

// Ensures we show the splash screen exactly once after a successful login
bool _postLoginSplashShown = false;

// Track previous user ID to detect account switches
// Using a simple variable since StateProvider may not be available
String? _previousUserId;

final appRouter = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final isSplashRoute = state.matchedLocation == '/splash';
      final isOnboardingRoute = state.matchedLocation == '/onboarding';
      final isAuthRoute = state.matchedLocation == '/login';

      if (authState.isLoading) {
        return null; // Still loading, don't redirect
      }

      final isLoggedIn = authState.value != null;
      final currentUserId = authState.value?.uid;

      // Reset the post-login splash flag on logout
      if (!isLoggedIn) {
        if (_postLoginSplashShown) {
          _postLoginSplashShown = false;
        }
        // Clear all celebration states when user logs out
        // Use Future to avoid modifying provider during redirect
        try {
          Future(() {
            ref.read(timerControllerProvider.notifier).clearAllCelebrations();
          });
        } catch (e) {
          // Ignore if timer controller is not available
        }
      } else {
        // When a new user logs in, also clear celebrations to prevent showing
        // achievements from the previous user
        // We'll track the previous user ID to detect account switches
        if (_previousUserId != null && _previousUserId != currentUserId) {
          // User switched accounts - clear celebrations
          try {
            Future(() {
              ref.read(timerControllerProvider.notifier).clearAllCelebrations();
            });
          } catch (e) {
            // Ignore if timer controller is not available
          }
        }
        // Update previous user ID
        _previousUserId = currentUserId;
      }

      // If not logged in and not on login, go to login
      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      // If logged in and on login screen, go to splash then home
      if (isLoggedIn && isAuthRoute) {
        return '/splash';
      }

      // Don't redirect if already on splash or onboarding
      if (isSplashRoute || isOnboardingRoute) {
        return null;
      }

      // If logged in and haven't shown post-login splash yet, show it once
      if (isLoggedIn) {
        if (!_postLoginSplashShown) {
          _postLoginSplashShown = true;
          return '/splash';
        }
      }

      // If logged in and on home or other main routes, check if we need onboarding
      if (isLoggedIn) {
        try {
          final onboardingCompleted =
              await OnboardingController.isOnboardingCompleted();
          if (!onboardingCompleted) {
            return '/onboarding';
          }
        } catch (e) {
          debugPrint('Error checking onboarding status: $e');
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LogInScreen()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(
            path: '/timer-mode',
            builder: (context, state) => const TimerModeSelectionScreen(),
          ),
          GoRoute(
            path: '/character',
            builder: (context, state) => const CharacterScreen(),
          ),
          GoRoute(
            path: '/stats',
            builder: (context, state) => const StatsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/tasks',
            builder: (context, state) => const TasksScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/achievements',
        builder: (context, state) => const AchievementsScreen(),
      ),
      GoRoute(
        path: '/topic-selection',
        builder: (context, state) => const TopicSelectionScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
    ],
  );
});

// Bottom navigation bar
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  static const tabs = <({String path, IconData icon, String label})>[
    (path: '/', icon: Icons.timer, label: 'Timer'),
    (path: '/character', icon: Icons.person, label: 'Character'),
    (path: '/stats', icon: Icons.bar_chart, label: 'Stats'),
    (path: '/settings', icon: Icons.settings, label: 'Settings'),
  ];

  int _locationToTabIndex(String location) {
    if (location.startsWith('/character')) return 1;
    if (location.startsWith('/stats')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    final int currentIndex = _locationToTabIndex(location);
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final compact = width < 360;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 2,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 4 : 8,
              vertical: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Left side navigation items
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (int i = 0; i < 2; i++)
                        _buildNavItem(
                          context,
                          tabs[i],
                          i == currentIndex,
                          theme,
                          compact,
                        ),
                    ],
                  ),
                ),

                // Central button
                const CentralButton(
                  size: 56,
                  homeRoute: '/',
                  selectionRoute: '/timer-mode',
                ),

                // Right side navigation items
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (int i = 2; i < tabs.length; i++)
                        _buildNavItem(
                          context,
                          tabs[i],
                          i == currentIndex,
                          theme,
                          compact,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    ({String path, IconData icon, String label}) tab,
    bool isSelected,
    ThemeData theme,
    bool compact,
  ) {
    return Semantics(
      label: '${tab.label} ${isSelected ? 'selected' : ''}',
      hint: 'Double tap to navigate to ${tab.label}',
      button: true,
      selected: isSelected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(tab.path),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            // Ensure minimum touch target size (48x48 dp)
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 12,
              vertical: 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  tab.icon,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 24,
                ),
                if (!compact) ...[
                  const SizedBox(height: 2),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 68),
                    child: Text(
                      tab.label,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
