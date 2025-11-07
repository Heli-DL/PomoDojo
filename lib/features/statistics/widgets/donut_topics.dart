import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DonutTopics extends StatelessWidget {
  const DonutTopics({
    super.key,
    required this.minutesByTopic,
    required this.topicColors,
  });

  final Map<String, int> minutesByTopic;
  final Map<String, Color> topicColors;

  @override
  Widget build(BuildContext context) {
    final entries = minutesByTopic.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = entries.fold<int>(0, (a, b) => a + b.value);

    final sections = entries.map((e) {
      final color = topicColors[e.key] ?? Colors.grey;
      return PieChartSectionData(
        value: e.value.toDouble(),
        color: color,
        radius: 44,
        showTitle: false, // we'll draw legend on the right
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Donut Chart
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: sections.isEmpty
                        ? [
                            PieChartSectionData(
                              value: 1,
                              color: Colors.grey.shade700,
                            ),
                          ]
                        : sections,
                    sectionsSpace: 2,
                    centerSpaceRadius: 60, // makes it a donut
                    startDegreeOffset: 270, // 12 o'clock start
                    borderData: FlBorderData(show: false),
                  ),
                ),
                // Center label (total minutes)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$total min',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Focused',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Legend under the chart
          if (entries.isNotEmpty) ...[
            Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: entries.map((e) {
                final color = topicColors[e.key] ?? Colors.grey;
                final mins = e.value;
                final pct = (e.value / total * 100).round();
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          e.key,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$mins min • $pct%',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                );
              }).toList(),
            ),
          ] else ...[
            Text(
              'No focus sessions yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
