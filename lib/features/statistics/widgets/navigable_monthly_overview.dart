import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../stats_model.dart';
import '../stats_controller.dart';
import '../../timer/session_model.dart';
import '../../topics/topic_controller.dart';
import '../../topics/topic_model.dart';

class NavigableMonthlyOverview extends ConsumerStatefulWidget {
  const NavigableMonthlyOverview({
    super.key,
    required this.months,
    this.height = 400,
  });

  final List<DayBucket> months; // Monthly buckets for all time
  final double height;

  @override
  ConsumerState<NavigableMonthlyOverview> createState() =>
      _NavigableMonthlyOverviewState();
}

class _NavigableMonthlyOverviewState
    extends ConsumerState<NavigableMonthlyOverview> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Start at the most recent month (last in the list)
    _currentPage = widget.months.isEmpty ? 0 : widget.months.length - 1;
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPreviousMonth() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNextMonth() {
    if (_currentPage < widget.months.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.months.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _currentPage > 0 ? _goToPreviousMonth : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous month',
              ),
              Expanded(
                child: Center(
                  child: Text(
                    widget.months[_currentPage].label,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: _currentPage < widget.months.length - 1
                    ? _goToNextMonth
                    : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next month',
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Calendar content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: widget.months.length,
              itemBuilder: (context, index) {
                final monthBucket = widget.months[index];
                final selectedMonth = monthBucket.day;
                return _buildMonthCalendar(theme, selectedMonth);
              },
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  size: 10,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Days with focus sessions',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthCalendar(ThemeData theme, DateTime month) {
    // Get the first and last day of the month
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

    // Calculate the first Monday of the calendar view
    final firstMonday = firstDayOfMonth.subtract(
      Duration(days: firstDayOfMonth.weekday - 1),
    );

    // Calculate the last Sunday of the calendar view
    final lastSunday = lastDayOfMonth.add(
      Duration(days: 7 - lastDayOfMonth.weekday),
    );

    // Fetch sessions for this month
    final repo = ref.read(statsRepositoryProvider);
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 1);

    return StreamBuilder<List<SessionModel>>(
      stream: repo.watchSessionModels(from: monthStart, to: monthEnd),
      builder: (context, snapshot) {
        // Create a map of day buckets for quick lookup
        final dayBucketMap = <String, DayBucket>{};

        if (snapshot.hasData) {
          final sessions = snapshot.data!;
          final topicsAsync = ref.watch(topicsControllerProvider);
          final userTopics = topicsAsync.when(
            data: (topics) => topics,
            loading: () => <Topic>[],
            error: (_, _) => <Topic>[],
          );

          // Group sessions by day
          for (final session in sessions) {
            if (session.sessionType != 'focus') continue;

            final endedAt = session.endAt.toLocal();
            final sessionDate = DateTime(
              endedAt.year,
              endedAt.month,
              endedAt.day,
            );
            final dayKey =
                '${sessionDate.year}-${sessionDate.month}-${sessionDate.day}';

            final minutes = session.duration.inMinutes;
            final topic = (session.topicName?.trim().isNotEmpty == true)
                ? session.topicName!
                : 'Other';
            final color = _getTopicColor(topic, userTopics);

            dayBucketMap.putIfAbsent(
              dayKey,
              () => DayBucket(
                day: sessionDate,
                minutesByTopic: {},
                colorsByTopic: {},
                label: '${sessionDate.day}',
              ),
            );

            final bucket = dayBucketMap[dayKey]!;
            bucket.minutesByTopic.update(
              topic,
              (v) => v + minutes,
              ifAbsent: () => minutes,
            );
            bucket.colorsByTopic.putIfAbsent(topic, () => color);
          }
        }

        // Generate calendar days
        final calendarDays = <DateTime>[];
        var current = firstMonday;
        var iterations = 0;
        const maxIterations = 50;
        while ((current.isBefore(lastSunday) ||
                current.isAtSameMomentAs(lastSunday)) &&
            iterations < maxIterations) {
          calendarDays.add(current);
          current = current.add(const Duration(days: 1));
          iterations++;
        }

        if (calendarDays.isEmpty) {
          return const SizedBox.shrink();
        }

        final now = DateTime.now();

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth <= 0 || constraints.maxWidth.isInfinite) {
              return const SizedBox.shrink();
            }

            // Calculate number of weeks (rows) needed
            final weeks = (calendarDays.length / 7).ceil();
            // Calculate item size based on available width
            final itemSize = (constraints.maxWidth - 16) / 7;
            // Calculate height based on number of weeks, with reasonable limits
            // Use more height to show calendar fully
            final calculatedHeight = (weeks * itemSize).clamp(250.0, 450.0);

            return SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Day of week headers
                  Row(
                    children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                        .map(
                          (day) => Expanded(
                            child: Center(
                              child: Text(
                                day,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  // Calendar grid
                  SizedBox(
                    height: calculatedHeight,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: 1,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      itemCount: calendarDays.length,
                      itemBuilder: (context, index) {
                        if (index < 0 || index >= calendarDays.length) {
                          return const SizedBox.shrink();
                        }
                        final day = calendarDays[index];
                        final isCurrentMonth = day.month == month.month;
                        final isToday =
                            day.day == now.day &&
                            day.month == now.month &&
                            day.year == now.year;

                        // Get session data for this day
                        final dayKey = '${day.year}-${day.month}-${day.day}';
                        final bucket = dayBucketMap[dayKey];
                        final hasSessions =
                            bucket != null && bucket.totalMinutes > 0;

                        return Container(
                          decoration: BoxDecoration(
                            color: isToday ? theme.colorScheme.primary : null,
                            borderRadius: BorderRadius.circular(8),
                            border: isToday
                                ? Border.all(
                                    color: theme.colorScheme.primary,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${day.day}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 12,
                                  color: isCurrentMonth
                                      ? (isToday
                                            ? theme.colorScheme.onPrimary
                                            : theme.colorScheme.onSurface)
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: isToday ? FontWeight.bold : null,
                                ),
                              ),
                              if (hasSessions) ...[
                                const SizedBox(height: 2),
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    size: 8,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
}
