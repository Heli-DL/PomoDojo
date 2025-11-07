import 'package:flutter/material.dart';
import '../../progression/progression_model.dart';
import '../../auth/user_model.dart';
import '../../statistics/stats_model.dart';
import '../../timer/session_repository.dart';

class StatisticsSection extends StatefulWidget {
  const StatisticsSection({
    super.key,
    required this.progression,
    required this.userModel,
    this.weeklyStats,
  });

  final ProgressionModel progression;
  final UserModel? userModel;
  final WeeklyStats? weeklyStats;

  @override
  State<StatisticsSection> createState() => _StatisticsSectionState();
}

class _StatisticsSectionState extends State<StatisticsSection> {
  int? actualTotalSessions;

  @override
  void initState() {
    super.initState();
    _fetchActualTotalSessions();
  }

  Future<void> _fetchActualTotalSessions() async {
    try {
      final sessionRepository = SessionRepository();
      final allSessions = await sessionRepository.getUserSessions();

      // Count only focus sessions (not breaks)
      final focusSessionsCount = allSessions
          .where((session) => session.sessionType == 'focus')
          .length;

      setState(() {
        actualTotalSessions = focusSessionsCount;
      });
    } catch (e) {
      debugPrint('Error fetching actual total sessions: $e');
      // If fetching fails, fall back to progression value
      setState(() {
        actualTotalSessions = widget.progression.totalSessions;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.bold,
    );
    final titleColor = titleStyle?.color ?? theme.colorScheme.onSurface;

    final displaySessions =
        actualTotalSessions ?? widget.progression.totalSessions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Statistics', style: titleStyle?.copyWith(color: titleColor)),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 8,
          childAspectRatio: 1.2,
          children: [
            _StatCard(
              icon: Icons.schedule,
              label: 'all-time sessions',
              value: '$displaySessions',
            ),
            _StatCard(
              icon: Icons.local_fire_department,
              label: 'streak',
              value:
                  '${widget.weeklyStats?.streakDays ?? widget.userModel?.streak ?? 0}',
            ),
            _StatCard(
              icon: Icons.military_tech,
              label: 'level',
              value: '${widget.progression.level}',
            ),
            _StatCard(
              icon: Icons.star,
              label: 'XP',
              value: '${widget.progression.xp}',
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    final iconColor = theme.colorScheme.primary;
    final valueColor =
        theme.textTheme.titleMedium?.color ?? theme.colorScheme.onSurface;
    final labelColor =
        theme.textTheme.bodySmall?.color ?? theme.colorScheme.onSurfaceVariant;

    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: labelColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
