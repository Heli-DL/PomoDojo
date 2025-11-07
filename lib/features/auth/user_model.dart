import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String? name;
  final String? photoURL;
  final DateTime createdAt;
  final int level;
  final int xp;
  final int streak;
  final String? characterName;
  final int totalSessions;
  final DateTime? lastSessionDate;
  final bool onboardingCompleted;
  final int weeklyGoal;
  final List<int> unlockedBackgrounds;
  final int selectedBackground;

  const UserModel({
    required this.uid,
    this.name,
    this.photoURL,
    required this.createdAt,
    this.level = 1,
    this.xp = 0,
    this.streak = 0,
    this.characterName,
    this.totalSessions = 0,
    this.lastSessionDate,
    this.onboardingCompleted = false,
    this.weeklyGoal = 20,
    this.unlockedBackgrounds = const [1], // background_1 is default
    this.selectedBackground = 1, // Default to background_1
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'],
      photoURL: map['photoURL'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      level: map['level'] ?? 1,
      xp: map['xp'] ?? 0,
      streak: map['streak'] ?? 0,
      characterName: map['characterName'],
      totalSessions: map['totalSessions'] ?? 0,
      lastSessionDate: map['lastSessionDate'] != null
          ? (map['lastSessionDate'] as Timestamp).toDate()
          : null,
      onboardingCompleted: map['onboardingCompleted'] ?? false,
      weeklyGoal: map['weeklyGoal'] ?? 20,
      unlockedBackgrounds: _parseUnlockedBackgrounds(
        map['unlockedBackgrounds'],
      ),
      selectedBackground: (map['selectedBackground'] as int?) ?? 1,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'photoURL': photoURL,
      'createdAt': Timestamp.fromDate(createdAt),
      'level': level,
      'xp': xp,
      'streak': streak,
      'characterName': characterName,
      'totalSessions': totalSessions,
      'lastSessionDate': lastSessionDate != null
          ? Timestamp.fromDate(lastSessionDate!)
          : null,
      'onboardingCompleted': onboardingCompleted,
      'weeklyGoal': weeklyGoal,
      'unlockedBackgrounds': unlockedBackgrounds,
      'selectedBackground': selectedBackground,
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? photoURL,
    DateTime? createdAt,
    int? level,
    int? xp,
    int? streak,
    String? characterName,
    int? totalSessions,
    DateTime? lastSessionDate,
    bool? onboardingCompleted,
    int? weeklyGoal,
    List<int>? unlockedBackgrounds,
    int? selectedBackground,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
      characterName: characterName ?? this.characterName,
      totalSessions: totalSessions ?? this.totalSessions,
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
      unlockedBackgrounds: unlockedBackgrounds ?? this.unlockedBackgrounds,
      selectedBackground: selectedBackground ?? this.selectedBackground,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.uid == uid &&
        other.name == name &&
        other.photoURL == photoURL &&
        other.createdAt == createdAt &&
        other.level == level &&
        other.xp == xp &&
        other.streak == streak &&
        other.characterName == characterName &&
        other.totalSessions == totalSessions &&
        other.lastSessionDate == lastSessionDate &&
        other.onboardingCompleted == onboardingCompleted &&
        other.weeklyGoal == weeklyGoal &&
        other.unlockedBackgrounds == unlockedBackgrounds &&
        other.selectedBackground == selectedBackground;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        name.hashCode ^
        photoURL.hashCode ^
        createdAt.hashCode ^
        level.hashCode ^
        xp.hashCode ^
        streak.hashCode ^
        characterName.hashCode ^
        totalSessions.hashCode ^
        lastSessionDate.hashCode ^
        onboardingCompleted.hashCode ^
        weeklyGoal.hashCode ^
        unlockedBackgrounds.hashCode ^
        selectedBackground.hashCode;
  }

  // Helper to safely parse unlockedBackgrounds from Firestore
  static List<int> _parseUnlockedBackgrounds(dynamic value) {
    if (value == null) return [1];
    try {
      if (value is List) {
        return value
            .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 1)
            .where((e) => e >= 1 && e <= 20)
            .toList()
          ..sort();
      }
    } catch (e) {
      // Fallback on any error
    }
    return [1]; // Default: background_1 unlocked
  }
}
