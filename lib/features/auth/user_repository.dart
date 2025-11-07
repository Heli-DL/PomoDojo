import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _userCollection =>
      _firestore.collection('users');

  Future<void> createOrUpdateUser(UserModel user) async {
    try {
      await _userCollection.doc(user.uid).set(user.toMap());
    } catch (e) {
      throw Exception('Error creating/updating user: $e');
    }
  }

  // Get user by ID
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _userCollection.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, uid);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // Create user from Firebase Auth User
  Future<UserModel> createUserFromAuth(User authUser) async {
    final user = UserModel(
      uid: authUser.uid,
      name: authUser.displayName,
      photoURL: authUser.photoURL,
      createdAt: DateTime.now(),
      level: 1,
      xp: 0,
      streak: 0,
      totalSessions: 0,
      lastSessionDate: null,
      unlockedBackgrounds: [1], // Default: background_1 unlocked
      selectedBackground: 1, // Default: background_1 selected
    );
    await createOrUpdateUser(user);
    return user;
  }

  // update user data
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _userCollection.doc(uid).update(data);
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  // Update user stats
  Future<void> updateUserStats(
    String uid, {
    int? level,
    int? xp,
    int? streak,
    int? xpToAdd,
    int? totalSessions,
  }) async {
    try {
      final updates = <String, dynamic>{};

      // Get current XP
      if (xpToAdd != null) {
        final user = await getUser(uid);
        if (user != null) {
          updates['xp'] = user.xp + xpToAdd;
        }
      }
      if (level != null) updates['level'] = level;
      if (xp != null) updates['xp'] = xp;
      if (streak != null) updates['streak'] = streak;
      if (totalSessions != null) updates['totalSessions'] = totalSessions;

      await _userCollection.doc(uid).update(updates);
    } catch (e) {
      throw Exception('Error updating user stats: $e');
    }
  }

  // Update onboarding completion
  Future<void> updateOnboardingCompletion(String uid, bool completed) async {
    try {
      // Use set with merge to ensure the document exists and field is upserted
      await _userCollection.doc(uid).set({
        'onboardingCompleted': completed,
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error updating onboarding completion: $e');
    }
  }

  // Update weekly goal
  Future<void> updateWeeklyGoal(String uid, int weeklyGoal) async {
    try {
      await _userCollection.doc(uid).update({'weeklyGoal': weeklyGoal});
    } catch (e) {
      throw Exception('Error updating weekly goal: $e');
    }
  }

  // Update streak when completing session
  Future<void> updateStreak(String uid) async {
    try {
      final currentUser = await getUser(uid);
      if (currentUser == null) {
        throw Exception('User not found');
      }
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // If there is no last session date, set streak to 1
      if (currentUser.lastSessionDate == null) {
        await _userCollection.doc(uid).update({
          'streak': 1,
          'lastSessionDate': Timestamp.fromDate(today),
        });
        return;
      }
      final lastSessionDate = currentUser.lastSessionDate!;
      final lastDate = DateTime(
        lastSessionDate.year,
        lastSessionDate.month,
        lastSessionDate.day,
      );
      final difference = today.difference(lastDate).inDays;

      int newStreak;
      if (difference == 0) {
        // Same day, do nothing
        newStreak = currentUser.streak;
      } else if (difference == 1) {
        // Consecutive day, increment streak
        newStreak = currentUser.streak + 1;
      } else {
        // Missed days, reset streak
        newStreak = 1;
      }
      await _userCollection.doc(uid).update({
        'streak': newStreak,
        'lastSessionDate': Timestamp.fromDate(today),
      });
    } catch (e) {
      throw Exception('Failed to update streak: $e');
    }
  }

  Stream<UserModel?> streamUser(String uid) {
    return _userCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, uid);
      }
      return null;
    });
  }

  // Set XP directly (for testing) - level and rank will be calculated automatically
  Future<void> setXP(String uid, int xp) async {
    try {
      await _userCollection.doc(uid).update({'xp': xp});
    } catch (e) {
      throw Exception('Error setting XP: $e');
    }
  }

  // Unlock a background
  Future<void> unlockBackground(String uid, int backgroundNumber) async {
    try {
      final user = await getUser(uid);
      if (user == null) {
        throw Exception('User not found');
      }
      final currentUnlocked = List<int>.from(user.unlockedBackgrounds);
      if (!currentUnlocked.contains(backgroundNumber)) {
        currentUnlocked.add(backgroundNumber);
        currentUnlocked.sort();
        await _userCollection.doc(uid).update({
          'unlockedBackgrounds': currentUnlocked,
        });
      }
    } catch (e) {
      throw Exception('Error unlocking background: $e');
    }
  }

  // Update selected background
  Future<void> updateSelectedBackground(
    String uid,
    int backgroundNumber,
  ) async {
    try {
      await _userCollection.doc(uid).update({
        'selectedBackground': backgroundNumber.clamp(1, 20),
      });
    } catch (e) {
      throw Exception('Error updating selected background: $e');
    }
  }

  // Update character name
  Future<void> updateCharacterName(String uid, String? characterName) async {
    try {
      await _userCollection.doc(uid).update({'characterName': characterName});
    } catch (e) {
      throw Exception('Error updating character name: $e');
    }
  }
}
