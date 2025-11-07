import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../stats_model.dart';

class WeeklyTimelineChart extends StatelessWidget {
  const WeeklyTimelineChart({
    super.key,
    required this.days,
    this.height = 180,
    this.trackColor = const Color(0xFF4A4F56), // bar background
    this.cardColor, // container color
    this.caption, // e.g., "45 Focused Sessions"
  });

  final List<DayBucket> days;
  final double height;
  final Color trackColor;
  final Color? cardColor;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final maxMinutes =
        (days.map((d) => d.totalMinutes).fold<int>(0, (a, b) => a > b ? a : b))
            .clamp(1, 99999);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor ?? theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: height,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                baselineY: 0,
                alignment: BarChartAlignment.spaceAround,
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= days.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            days[i].label,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(days.length, (i) {
                  final d = days[i];

                  // Build stacked segments
                  double from = 0;
                  final stacks = <BarChartRodStackItem>[];
                  d.minutesByTopic.forEach((topic, mins) {
                    final to = from + (mins / maxMinutes) * 100.0;
                    stacks.add(
                      BarChartRodStackItem(
                        from,
                        to,
                        d.colorsByTopic[topic] ?? Colors.grey,
                      ),
                    );
                    from = to;
                  });

                  // Add background "track" to show empty headroom
                  if (from < 100) {
                    stacks.add(BarChartRodStackItem(from, 100, trackColor));
                  }

                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: 100, // normalize bars to same height
                        rodStackItems: stacks,
                        width: 14,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (caption != null)
            Text(caption!, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
