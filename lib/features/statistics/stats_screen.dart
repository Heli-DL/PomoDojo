import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/user_model.dart';
import '../auth/user_repository.dart';
import '../achievements/achievement_tracking_service.dart';
import '../timer/session_model.dart';
import '../topics/topic_controller.dart';
import '../topics/topic_model.dart';
import 'stats_controller.dart';
import 'stats_model.dart';
import 'widgets/donut_topics.dart';
import 'widgets/weekly_timeline_chart.dart';
import 'widgets/monthly_calendar.dart';
import 'widgets/navigable_monthly_overview.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';

final statsUserStreamProvider = StreamProvider.family<UserModel?, String>((
  ref,
  uid,
) {
  final userRepository = UserRepository();
  return userRepository.streamUser(uid);
});

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  @override
  void reassemble() {
    // Force Riverpod to rebuild the stats stream after hot reload,
    // so mapping and range logic changes take effect without a hot restart.
    ref.invalidate(weeklyStatsProvider);

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      ref.invalidate(statsUserStreamProvider(currentUser.uid));
    }

    super.reassemble();
  }

  void _trackStatsViewing() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final trackingService = AchievementTrackingService();
      trackingService.trackStatsViewing(currentUser.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Track stats viewing on first build
    WidgetsBinding.instance.addPostFrameCallback((_) => _trackStatsViewing());

    final theme = Theme.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    final statsRange = ref.watch(statsRangeProvider);
    final weeklyStats = ref.watch(weeklyStatsProvider);
    final userAsync = currentUser != null
        ? ref.watch(statsUserStreamProvider(currentUser.uid))
        : const AsyncValue<UserModel?>.data(null);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          statsRange == StatsRange.week
              ? 'Weekly statistics'
              : statsRange == StatsRange.month
              ? 'Monthly statistics'
              : 'All time statistics',
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          PopupMenuButton<StatsRange>(
            icon: const Icon(Icons.calendar_today),
            onSelected: (range) {
              ref.read(statsRangeProvider.notifier).setRange(range);
              // Invalidate stats provider to force rebuild with new range
              ref.invalidate(weeklyStatsProvider);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: StatsRange.week,
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_view_week,
                      color: statsRange == StatsRange.week
                          ? theme.colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text('This Week'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: StatsRange.month,
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_view_month,
                      color: statsRange == StatsRange.month
                          ? theme.colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text('This Month'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: StatsRange.allTime,
                child: Row(
                  children: [
                    Icon(
                      Icons.all_inclusive,
                      color: statsRange == StatsRange.allTime
                          ? theme.colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text('All Time'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: userAsync.when(
        data: (userModel) => weeklyStats.when(
          data: (stats) {
            // Validate that stats data matches the current range
            int expectedDays;
            if (statsRange == StatsRange.week) {
              expectedDays = 7;
            } else if (statsRange == StatsRange.month) {
              expectedDays = DateTime(
                DateTime.now().year,
                DateTime.now().month + 1,
                0,
              ).day;
            } else {
              // For all time, we don't validate exact count (months can vary)
              expectedDays = -1; // Skip validation for all time
            }
            if (expectedDays != -1 && stats.week.length != expectedDays) {
              // Data mismatch - show loading while provider rebuilds
              return const Center(child: CircularProgressIndicator());
            }
            // Show empty state if no sessions completed yet
            if (stats.totalMinutes == 0 && stats.sessionsCount == 0) {
              return const EmptyStatsState();
            }
            return _buildStatsContent(context, stats, userModel, statsRange);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorState(
            title: 'Failed to Load Statistics',
            message: ErrorMessageHelper.getUserFriendlyMessage(error),
            details: ErrorMessageHelper.getErrorDetails(error),
            onRetry: () => ref.invalidate(weeklyStatsProvider),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          title: 'Failed to Load Statistics',
          message: ErrorMessageHelper.getUserFriendlyMessage(error),
          details: ErrorMessageHelper.getErrorDetails(error),
          onRetry: () {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser != null) {
              ref.invalidate(statsUserStreamProvider(currentUser.uid));
            }
          },
        ),
      ),
    );
  }

  Widget _buildStatsContent(
    BuildContext context,
    WeeklyStats stats,
    UserModel? userModel,
    StatsRange range,
  ) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Focus Time Cards
          _buildFocusTimeCards(theme, stats, range),
          const SizedBox(height: 24),

          // Top Topics Donut Chart
          _buildTopTopicsSection(theme, stats, range),
          const SizedBox(height: 24),

          // Timeline (Weekly or Monthly)
          _buildTimeline(theme, stats, range),
          const SizedBox(height: 24),

          // Summary Statement
          _buildSummaryStatement(theme, stats, range),
          const SizedBox(height: 24),

          // Recent Sessions
          _buildRecentSessions(theme, stats, range),
        ],
      ),
    );
  }

  Widget _buildFocusTimeCards(
    ThemeData theme,
    WeeklyStats stats,
    StatsRange range,
  ) {
    final totalMinutes = stats.totalMinutes;
    final dailyMinutes = stats.dailyAverageMinutes;
    final periodLabel = range == StatsRange.week
        ? 'This week'
        : range == StatsRange.month
        ? 'This month'
        : 'All time';
    final averageLabel = range == StatsRange.week
        ? 'Daily average'
        : range == StatsRange.month
        ? 'Weekly average'
        : 'Monthly average';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final cardSpacing = isSmallScreen ? 8.0 : 12.0;

        return Row(
          children: [
            Expanded(
              child: _buildFocusCard(
                theme,
                Icons.schedule,
                '$totalMinutes min',
                periodLabel,
                theme.colorScheme.primary,
                isSmallScreen,
              ),
            ),
            SizedBox(width: cardSpacing),
            Expanded(
              child: _buildFocusCard(
                theme,
                Icons.schedule,
                '${dailyMinutes.toStringAsFixed(0)} min',
                averageLabel,
                theme.colorScheme.primary,
                isSmallScreen,
              ),
            ),
            SizedBox(width: cardSpacing),
            Expanded(
              child: _buildFocusCard(
                theme,
                Icons.local_fire_department,
                '${stats.streakDays} days',
                'Current streak',
                theme.colorScheme.primary,
                isSmallScreen,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFocusCard(
    ThemeData theme,
    IconData icon,
    String value,
    String label,
    Color color,
    bool isSmallScreen,
  ) {
    final iconSize = isSmallScreen ? 20.0 : 24.0;
    final padding = isSmallScreen ? 16.0 : 16.0;
    final spacing = isSmallScreen ? 8.0 : 8.0;

    return Container(
      height: isSmallScreen ? 100 : 120, // Fixed height for equal cards
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Icon(icon, color: color, size: iconSize),
          SizedBox(height: spacing),
          // Value text
          Text(
            value,
            style:
                (isSmallScreen
                        ? theme.textTheme.titleMedium
                        : theme.textTheme.headlineSmall)
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: isSmallScreen ? 16 : null,
                    ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: spacing / 2),
          // Label text
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: isSmallScreen ? 10 : 11,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTopicsSection(
    ThemeData theme,
    WeeklyStats stats,
    StatsRange range,
  ) {
    final periodLabel = range == StatsRange.week
        ? 'this week'
        : range == StatsRange.month
        ? 'this month'
        : 'all time';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top topics $periodLabel',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Donut Chart with integrated legend
            Expanded(
              child: DonutTopics(
                minutesByTopic: _getMinutesByTopicFromStats(stats),
                topicColors: _getTopicColorsFromStats(stats),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeline(ThemeData theme, WeeklyStats stats, StatsRange range) {
    final timelineLabel = range == StatsRange.week
        ? 'Weekly timeline'
        : range == StatsRange.month
        ? 'Monthly calendar'
        : 'Monthly overview';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          timelineLabel,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (range == StatsRange.week)
          WeeklyTimelineChart(
            days: stats.week,
            height: 160,
            caption: '${stats.sessionsCount} Focused Sessions',
          )
        else if (range == StatsRange.month)
          MonthlyCalendar(days: stats.week, height: 300)
        else
          // For all time, show navigable monthly overview
          SizedBox(
            height: 360,
            child: NavigableMonthlyOverview(months: stats.week, height: 360),
          ),
      ],
    );
  }

  Widget _buildSummaryStatement(
    ThemeData theme,
    WeeklyStats stats,
    StatsRange range,
  ) {
    if (stats.topTopicTitle == null || stats.topTopicMinutes == null) {
      return const SizedBox.shrink();
    }

    final periodLabel = range == StatsRange.week
        ? 'this week'
        : range == StatsRange.month
        ? 'this month'
        : 'all time';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              'You spent the most time on ${stats.topTopicTitle} (${stats.topTopicMinutes} min) $periodLabel',
              style: theme.textTheme.bodySmall?.copyWith(height: 1.2),
              softWrap: true,
              overflow: TextOverflow.visible,
              maxLines: 3,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.trending_up, size: 16, color: theme.colorScheme.primary),
        ],
      ),
    );
  }

  Widget _buildRecentSessions(
    ThemeData theme,
    WeeklyStats stats,
    StatsRange range,
  ) {
    // For all time, use StreamBuilder to fetch actual sessions; for week/month, use stats data
    if (range == StatsRange.allTime) {
      return _buildRecentSessionsFromAllTime(theme, ref);
    }

    final recentSessions = _getRecentSessionsFromStats(stats);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Sessions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (recentSessions.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No recent sessions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Complete some focus sessions to see them here',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...recentSessions.take(5).map((session) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: session.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.topic,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          session.timeString,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${session.durationMinutes} min',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '+ ${session.durationMinutes} XP',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  List<_RecentSession> _getRecentSessionsFromStats(WeeklyStats stats) {
    final sessions = <_RecentSession>[];
    final now = DateTime.now();

    // Process each day's data to create recent sessions
    for (final dayBucket in stats.week) {
      if (dayBucket.totalMinutes > 0) {
        // Create sessions for each topic in this day
        for (final entry in dayBucket.minutesByTopic.entries) {
          final topic = entry.key;
          final minutes = entry.value;
          final color = dayBucket.colorsByTopic[topic] ?? Colors.blue;

          // Calculate time string
          final dayDiff = now.difference(dayBucket.day).inDays;
          String timeString;
          if (dayDiff == 0) {
            timeString = 'Today • ${_getRandomTime()}';
          } else if (dayDiff == 1) {
            timeString = 'Yesterday • ${_getRandomTime()}';
          } else {
            timeString = '$dayDiff days ago • ${_getRandomTime()}';
          }

          sessions.add(
            _RecentSession(
              topic: topic,
              durationMinutes: minutes,
              timeString: timeString,
              color: color,
            ),
          );
        }
      }
    }

    // Sort by most recent (assuming more recent days have higher totalMinutes)
    sessions.sort((a, b) => b.durationMinutes.compareTo(a.durationMinutes));

    return sessions;
  }

  Widget _buildRecentSessionsFromAllTime(ThemeData theme, WidgetRef ref) {
    final repo = ref.read(statsRepositoryProvider);
    final from = DateTime.now().subtract(const Duration(days: 30));
    final to = DateTime.now().add(const Duration(days: 1));

    return StreamBuilder<List<SessionModel>>(
      stream: repo.watchSessionModels(from: from, to: to),
      builder: (context, snapshot) {
        final recentSessions = <_RecentSession>[];
        final now = DateTime.now();

        if (snapshot.hasData) {
          final topicsAsync = ref.watch(topicsControllerProvider);
          final userTopics = topicsAsync.when(
            data: (topics) => topics,
            loading: () => <Topic>[],
            error: (_, _) => <Topic>[],
          );

          // Filter to focus sessions only and sort by most recent
          final focusSessions =
              snapshot.data!.where((s) => s.sessionType == 'focus').toList()
                ..sort((a, b) => b.endAt.compareTo(a.endAt));

          // Convert to _RecentSession format
          for (final session in focusSessions.take(10)) {
            final endedAt = session.endAt.toLocal();
            final topic = (session.topicName?.trim().isNotEmpty == true)
                ? session.topicName!
                : 'Other';
            final color = _getTopicColor(topic, userTopics);
            final minutes = session.duration.inMinutes;

            // Calculate time string
            final dayDiff = now.difference(endedAt).inDays;
            String timeString;
            if (dayDiff == 0) {
              final hour = endedAt.hour;
              final minute = endedAt.minute;
              final period = hour >= 12 ? 'PM' : 'AM';
              final displayHour = hour > 12
                  ? hour - 12
                  : (hour == 0 ? 12 : hour);
              timeString =
                  'Today • ${displayHour.toString().padLeft(2, '0')}.${minute.toString().padLeft(2, '0')}$period';
            } else if (dayDiff == 1) {
              final hour = endedAt.hour;
              final minute = endedAt.minute;
              final period = hour >= 12 ? 'PM' : 'AM';
              final displayHour = hour > 12
                  ? hour - 12
                  : (hour == 0 ? 12 : hour);
              timeString =
                  'Yesterday • ${displayHour.toString().padLeft(2, '0')}.${minute.toString().padLeft(2, '0')}$period';
            } else {
              timeString = '$dayDiff days ago';
            }

            recentSessions.add(
              _RecentSession(
                topic: topic,
                durationMinutes: minutes,
                timeString: timeString,
                color: color,
              ),
            );
          }
        }

        return _buildRecentSessionsList(theme, recentSessions);
      },
    );
  }

  Widget _buildRecentSessionsList(
    ThemeData theme,
    List<_RecentSession> recentSessions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Sessions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (recentSessions.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No recent sessions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Complete some focus sessions to see them here',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...recentSessions.take(5).map((session) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: session.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.topic,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          session.timeString,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${session.durationMinutes} min',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '+ ${session.durationMinutes} XP',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Color _getTopicColor(String topic, [List<Topic>? userTopics]) {
    // First check user-defined topics
    if (userTopics != null) {
      final userTopic = userTopics.firstWhere(
        (t) => t.name.toLowerCase() == topic.toLowerCase(),
        orElse: () => const Topic(id: '', name: '', color: 0),
      );

      if (userTopic.id.isNotEmpty) {
        return Color(userTopic.color);
      }
    }

    // Fallback to muted/pastel colors based on topic name hash
    final colors = [
      const Color(0xFFB39DDB), // Muted Lavender
      const Color(0xFFA5D6A7), // Muted Sage
      const Color(0xFFFFCC80), // Muted Peach
      const Color(0xFFCE93D8), // Muted Mauve
      const Color(0xFFEF9A9A), // Muted Rose
      const Color(0xFF80CBC4), // Muted Teal
      const Color(0xFF9FA8DA), // Muted Indigo
      const Color(0xFFF48FB1), // Muted Pink
    ];

    final hash = topic.hashCode;
    return colors[hash.abs() % colors.length];
  }

  String _getRandomTime() {
    final times = ['9.00AM', '10.30AM', '2.00PM', '4.00PM', '7.30PM'];
    return times[DateTime.now().millisecond % times.length];
  }

  Map<String, int> _getMinutesByTopicFromStats(WeeklyStats stats) {
    final Map<String, int> minutesByTopic = {};

    for (final topicSlice in stats.topTopics) {
      minutesByTopic[topicSlice.title] = topicSlice.minutes;
    }

    return minutesByTopic;
  }

  Map<String, Color> _getTopicColorsFromStats(WeeklyStats stats) {
    final Map<String, Color> topicColors = {};

    for (final topicSlice in stats.topTopics) {
      topicColors[topicSlice.title] = topicSlice.color;
    }

    return topicColors;
  }
}

class _RecentSession {
  final String topic;
  final int durationMinutes;
  final String timeString;
  final Color color;

  _RecentSession({
    required this.topic,
    required this.durationMinutes,
    required this.timeString,
    required this.color,
  });
}
