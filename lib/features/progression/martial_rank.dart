import 'package:flutter/material.dart';

enum MartialRank {
  novice(
    name: 'Novice',
    levelRange: (1, 2),
    dialogue: 'I am ready to begin my training!',
    icon: Icons.person_outline,
    color: Color(0xFF8BC34A),
  ),
  apprentice(
    name: 'Apprentice',
    levelRange: (3, 4),
    dialogue: 'I am starting to understand focus.',
    icon: Icons.person,
    color: Color(0xFF2196F3),
  ),
  disciple(
    name: 'Disciple',
    levelRange: (5, 6),
    dialogue: 'Discipline is my path forward.',
    icon: Icons.self_improvement,
    color: Color(0xFF9C27B0),
  ),
  adept(
    name: 'Adept',
    levelRange: (7, 8),
    dialogue: 'Now I train not just the body, but the mind.',
    icon: Icons.star,
    color: Color(0xFFFF9800),
  ),
  master(
    name: 'Master',
    levelRange: (9, 10),
    dialogue: 'Through focus, I find freedom.',
    icon: Icons.military_tech,
    color: Color(0xFFF44336),
  ),
  grandmaster(
    name: 'Grandmaster',
    levelRange: (11, 999), // Up to level 999 for grandmaster
    dialogue: 'I no longer train—I embody the art itself.',
    icon: Icons.emoji_events,
    color: Color(0xFFE91E63),
  );

  final String name;
  final (int, int) levelRange;
  final String dialogue;
  final IconData icon;
  final Color color;

  const MartialRank({
    required this.name,
    required this.levelRange,
    required this.dialogue,
    required this.icon,
    required this.color,
  });

  // Get rank from level
  static MartialRank fromLevel(int level) {
    if (level >= 11) return MartialRank.grandmaster;
    if (level >= 9) return MartialRank.master;
    if (level >= 7) return MartialRank.adept;
    if (level >= 5) return MartialRank.disciple;
    if (level >= 3) return MartialRank.apprentice;
    return MartialRank.novice;
  }
}
