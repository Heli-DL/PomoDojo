import 'package:flutter/material.dart';
import '../stats_model.dart';

class MonthlyCalendar extends StatelessWidget {
  const MonthlyCalendar({
    super.key,
    required this.days,
    this.height = 300,
    this.cardColor,
  });

  final List<DayBucket> days;
  final double height;
  final Color? cardColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    // Safety check: ensure days list is not empty
    if (days.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get the first day of the month
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    // Calculate the first Monday of the calendar view
    final firstMonday = firstDayOfMonth.subtract(
      Duration(days: firstDayOfMonth.weekday - 1),
    );

    // Calculate the last Sunday of the calendar view
    final lastSunday = lastDayOfMonth.add(
      Duration(days: 7 - lastDayOfMonth.weekday),
    );

    // Create a map of day buckets for quick lookup
    final dayBucketMap = <String, DayBucket>{};
    for (final bucket in days) {
      final key = '${bucket.day.year}-${bucket.day.month}-${bucket.day.day}';
      dayBucketMap[key] = bucket;
    }

    // Generate calendar days
    final calendarDays = <DateTime>[];
    var current = firstMonday;
    var iterations = 0;
    const maxIterations = 50; // Safety limit to prevent infinite loops
    while ((current.isBefore(lastSunday) ||
            current.isAtSameMomentAs(lastSunday)) &&
        iterations < maxIterations) {
      calendarDays.add(current);
      current = current.add(const Duration(days: 1));
      iterations++;
    }
    
    // Safety check: ensure we have at least 28 days (4 weeks)
    if (calendarDays.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor ?? theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month and year header
          Text(
            '${_getMonthName(now.month)} ${now.year}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

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
          LayoutBuilder(
            builder: (context, constraints) {
              // Safety check for constraints
              if (constraints.maxWidth <= 0 || constraints.maxWidth.isInfinite) {
                return const SizedBox.shrink();
              }
              
              // Calculate number of weeks (rows) needed
              final weeks = (calendarDays.length / 7).ceil();
              // Calculate item size based on available width
              final itemSize = (constraints.maxWidth - 16) / 7; // 16 for padding/margins
              // Calculate height based on number of weeks
              final calculatedHeight = weeks * itemSize;

              return SizedBox(
                height: calculatedHeight.clamp(200, 500),
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
                    final isCurrentMonth = day.month == now.month;
                    final isToday = day.day == now.day && day.month == now.month;

                    // Get session count for this day
                    final dayKey = '${day.year}-${day.month}-${day.day}';
                    final bucket = dayBucketMap[dayKey];
                    final sessionCount = bucket?.totalMinutes ?? 0;
                    final hasSessions = sessionCount > 0;

                    return Container(
                      decoration: BoxDecoration(
                        color: isToday ? theme.colorScheme.primary : null,
                        borderRadius: BorderRadius.circular(8),
                        border: isToday
                            ? Border.all(color: theme.colorScheme.primary, width: 2)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${day.day}',
                            style: theme.textTheme.bodyMedium?.copyWith(
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
                          ],
                        ],
                      ),
                    );
              },
            ),
            );
            },
          ),

          // Legend
          const SizedBox(height: 16),
          Row(
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

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
