import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'topic_controller.dart';
import 'topic_model.dart';
import '../timer/timer_mode_screen.dart';

class TopicSelectionScreen extends ConsumerStatefulWidget {
  const TopicSelectionScreen({super.key});

  @override
  ConsumerState<TopicSelectionScreen> createState() =>
      _TopicSelectionScreenState();
}

class _TopicSelectionScreenState extends ConsumerState<TopicSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = ref.watch(selectedTopicProvider);
    final asyncTopics = ref.watch(topicsControllerProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => context.go('/'),
        ),
        title: Text(
          'Select Topic',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [],
      ),
      body: Column(
        children: [
          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subtitle
                  Text(
                    'Choose a topic for your focus session',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Topics Grid
                  Expanded(
                    child: asyncTopics.when(
                      data: (userTopics) {
                        final topics = [...predefinedTopics, ...userTopics];
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            // Calculate optimal cross axis count based on available width
                            final availableWidth = constraints.maxWidth;
                            final spacing = 12.0;
                            // Responsive item width: min 100px on small screens, max 140px on large screens
                            final itemWidth = (availableWidth / 4).clamp(
                              100.0,
                              140.0,
                            );
                            final crossAxisCount =
                                ((availableWidth + spacing) /
                                        (itemWidth + spacing))
                                    .floor()
                                    .clamp(
                                      2,
                                      5,
                                    ); // Allow 2-5 columns for better responsiveness

                            return GridView.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: spacing,
                                    mainAxisSpacing: spacing,
                                    childAspectRatio:
                                        0.85, // Slightly taller for better text display
                                  ),
                              itemCount: topics.length + 1,
                              itemBuilder: (context, index) {
                                if (index == topics.length) {
                                  return _AddTopicCard();
                                }
                                final t = topics[index];
                                final isSelected = selected?.id == t.id;
                                return GestureDetector(
                                  onTap: () {
                                    ref
                                            .read(
                                              selectedTopicProvider.notifier,
                                            )
                                            .state =
                                        t;
                                  },
                                  onLongPress: t.isPredefined
                                      ? null
                                      : () =>
                                            _showDeleteDialog(context, ref, t),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minWidth:
                                          48, // WCAG 2.2 minimum tap target
                                      minHeight:
                                          48, // WCAG 2.2 minimum tap target
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                                  .withValues(alpha: 0.1)
                                            : theme.colorScheme.surface,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.outline,
                                          width: isSelected ? 2 : 1,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: theme
                                                      .colorScheme
                                                      .primary
                                                      .withValues(alpha: 0.2),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          // Centered color ball
                                          Center(
                                            child: Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: Color(t.color),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Color(
                                                      t.color,
                                                    ).withValues(alpha: 0.3),
                                                    blurRadius: 3,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Expanded(
                                            child: Center(
                                              child: Text(
                                                t.name,
                                                style: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: isSelected
                                                          ? theme
                                                                .colorScheme
                                                                .primary
                                                          : theme
                                                                .colorScheme
                                                                .onSurface,
                                                    ),
                                                textAlign: TextAlign.center,
                                                overflow: TextOverflow.visible,
                                                maxLines: 3,
                                              ),
                                            ),
                                          ),
                                          if (isSelected) ...[
                                            const SizedBox(height: 4),
                                            Icon(
                                              Icons.check_circle,
                                              color: theme.colorScheme.primary,
                                              size: 16,
                                            ),
                                          ] else if (!t.isPredefined) ...[
                                            const SizedBox(height: 4),
                                            Icon(
                                              Icons.delete_outline,
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.4),
                                              size: 14,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load topics',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              e.toString(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Start Timer Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: selected != null
                      ? () => _startTimerWithTopic(context, ref)
                      : null,
                  style: FilledButton.styleFrom(
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    selected != null
                        ? 'Start Timer with ${selected.name}'
                        : 'Select a topic to start',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startTimerWithTopic(BuildContext context, WidgetRef ref) {
    // Get the timer mode selection notifier
    final selectionNotifier = ref.read(timerModeSelectionProvider.notifier);

    // Start the selected timer
    selectionNotifier.startSelectedTimer(ref);

    // Navigate back to home screen
    context.go('/');
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Topic topic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Topic'),
        content: Text(
          'Are you sure you want to delete "${topic.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              // Clear selection if this topic is currently selected
              final currentSelected = ref.read(selectedTopicProvider);
              if (currentSelected?.id == topic.id) {
                ref.read(selectedTopicProvider.notifier).state = null;
              }

              // Delete the topic
              await ref
                  .read(topicsControllerProvider.notifier)
                  .remove(topic.id);

              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${topic.name} deleted'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _AddTopicCard extends ConsumerWidget {
  const _AddTopicCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _showAddTopicDialog(context, ref),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 48, // WCAG 2.2 minimum tap target
          minHeight: 48, // WCAG 2.2 minimum tap target
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline,
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Slight top offset to align with color indicators on other cards
              const SizedBox(height: 4),
              // Centered add icon
              Center(
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    color: theme.colorScheme.primary,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Add Topic',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Create new',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                          fontSize: 9,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddTopicDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    int selectedColor = 0xFF80CBC4; // Default muted teal

    // Muted/pastel color palette that matches the app's theme
    final colorOptions = [
      // Teals & Blues (matching app primary)
      0xFF80CBC4, // Muted Teal
      0xFF4DB6AC, // Soft Teal
      0xFF26A69A, // Light Teal
      0xFF0097A7, // Muted Cyan
      0xFF81D4FA, // Light Blue
      0xFF90CAF9, // Soft Blue
      0xFF64B5F6, // Pastel Blue
      // Greens & Sages
      0xFFA5D6A7, // Muted Sage
      0xFF81C784, // Soft Green
      0xFF66BB6A, // Light Green
      0xFFAED581, // Pastel Green
      0xFFC5E1A5, // Mint
      // Purples & Lavenders
      0xFFB39DDB, // Muted Lavender
      0xFF9FA8DA, // Muted Indigo
      0xFFCE93D8, // Muted Mauve
      0xFFBA68C8, // Soft Purple
      0xFFE1BEE7, // Very Light Purple
      // Pinks & Roses
      0xFFF48FB1, // Muted Pink
      0xFFEF9A9A, // Muted Rose
      0xFFF8BBD9, // Soft Pink
      0xFFE1BEE7, // Lavender Pink
      0xFFCE93D8, // Rose Mauve
      // Peaches & Oranges
      0xFFFFCC80, // Muted Peach
      0xFFFFB74D, // Soft Orange
      0xFFFFA726, // Pastel Orange
      0xFFFFE082, // Light Amber
      0xFFFFD54F, // Soft Yellow
      // Warm Neutrals
      0xFFBCAAA4, // Muted Taupe
      0xFFA1887F, // Soft Brown
      0xFF90A4AE, // Blue Gray
      0xFF78909C, // Muted Slate
      0xFFB0BEC5, // Light Gray Blue
    ];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Topic'),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.5,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Topic Name',
                      hintText: 'Enter topic name...',
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Choose Color',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // WCAG 2.2: Minimum tap target is 48x48dp
                      final availableWidth = constraints.maxWidth;
                      final itemSize = 48.0; // WCAG 2.2 minimum tap target size
                      final spacing = 12.0; // Adequate spacing between targets
                      final crossAxisCount =
                          ((availableWidth + spacing) / (itemSize + spacing))
                              .floor()
                              .clamp(4, 8);

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: spacing,
                          mainAxisSpacing: spacing,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: colorOptions.length,
                        itemBuilder: (context, index) {
                          final color = colorOptions[index];
                          final isSelected = selectedColor == color;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedColor = color;
                              });
                            },
                            child: SizedBox(
                              width: itemSize,
                              height: itemSize,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Color(color),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 20,
                                      )
                                    : null,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  await ref
                      .read(topicsControllerProvider.notifier)
                      .add(Topic(id: 'new', name: name, color: selectedColor));
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
              style: FilledButton.styleFrom(
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 56),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
