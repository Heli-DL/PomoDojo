import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'onboarding_models.dart';
import '../auth/user_repository.dart';
import '../achievements/achievement_service.dart';
import '../achievements/achievement_model.dart';

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingData>(() {
      return OnboardingController();
    });

class OnboardingController extends Notifier<OnboardingData> {
  @override
  OnboardingData build() {
    return OnboardingData(
      selectedPreset: PomodoroPreset.all[0], // Default to 25/5
    );
  }

  void updateGoals(List<String> goals) {
    state = state.copyWith(selectedGoals: goals);
  }

  void updatePreset(PomodoroPreset preset) {
    state = state.copyWith(selectedPreset: preset);
  }

  void updateWeeklyGoal(int goal) {
    state = state.copyWith(weeklyGoal: goal);
  }

  void updateNotifications(bool enabled) {
    state = state.copyWith(notificationsEnabled: enabled);
  }

  void updateDoNotDisturb(bool enabled) {
    state = state.copyWith(doNotDisturbEnabled: enabled);
  }

  Future<void> completeOnboarding() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userRepository = UserRepository();

    // Update onboarding completion and weekly goal in Firebase
    await userRepository.updateOnboardingCompletion(currentUser.uid, true);
    await userRepository.updateWeeklyGoal(currentUser.uid, state.weeklyGoal);

    // Unlock "Getting Started" achievement
    try {
      final gettingStartedAchievement = Achievements.getById('getting_started');
      if (gettingStartedAchievement != null) {
        final achievementService = AchievementService();
        final userAchievements = await achievementService.getUserAchievements(
          currentUser.uid,
        );

        // Check if achievement is already unlocked
        final isAlreadyUnlocked = userAchievements.any(
          (a) => a.id == 'getting_started' && a.isUnlocked,
        );

        if (!isAlreadyUnlocked) {
          final unlockedAchievement = gettingStartedAchievement.copyWith(
            unlockedAt: DateTime.now(),
          );
          await achievementService.unlockAchievement(
            currentUser.uid,
            unlockedAchievement,
          );
          debugPrint('Getting Started achievement unlocked');
        }
      }
    } catch (e) {
      debugPrint('Error unlocking Getting Started achievement: $e');
      // Don't fail onboarding if achievement unlock fails
    }

    // Save user preferences to SharedPreferences for local access
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    await prefs.setStringList('onboarding_goals', state.selectedGoals);
    await prefs.setString('selected_preset', state.selectedPreset.name);
    await prefs.setInt('weekly_goal', state.weeklyGoal);
    await prefs.setBool('notifications_enabled', state.notificationsEnabled);
    await prefs.setBool('do_not_disturb_enabled', state.doNotDisturbEnabled);

    // If DND permission was granted during onboarding, enable Focus Shield
    // This ensures the setting is toggled on in the settings screen
    if (state.doNotDisturbEnabled) {
      await prefs.setBool('focus_shield_enabled', true);
    }
  }

  static Future<bool> isOnboardingCompleted() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    try {
      final userRepository = UserRepository();
      final user = await userRepository.getUser(currentUser.uid);
      return user?.onboardingCompleted ?? false;
    } catch (e) {
      // Fallback to SharedPreferences if Firebase fails
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('onboarding_completed') ?? false;
    }
  }

  static Future<void> resetOnboarding() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final userRepository = UserRepository();
        await userRepository.updateOnboardingCompletion(currentUser.uid, false);
      } catch (e) {
        // Fallback to SharedPreferences if Firebase fails
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('onboarding_completed');
      }
    }

    // Clear local preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_completed');
    await prefs.remove('onboarding_goals');
    await prefs.remove('selected_preset');
    await prefs.remove('weekly_goal');
    await prefs.remove('notifications_enabled');
    await prefs.remove('do_not_disturb_enabled');
  }
}
