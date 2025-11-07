import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'topic_controller.dart';
import 'topic_model.dart';
import '../../accessibility/focus_outline.dart';

class TopicPicker extends ConsumerWidget {
  const TopicPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTopics = ref.watch(topicsControllerProvider);
    final selected = ref.watch(selectedTopicProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Topic',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        asyncTopics.when(
          data: (userTopics) {
            final topics = [...predefinedTopics, ...userTopics];
            return LayoutBuilder(
              builder: (context, constraints) {
                // Calculate optimal cross axis count based on available width
                final availableWidth = constraints.maxWidth;
                final itemWidth = 120.0; // Minimum item width
                final spacing = 12.0;
                final crossAxisCount =
                    ((availableWidth + spacing) / (itemWidth + spacing))
                        .floor()
                        .clamp(1, 3);

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio: 2.5, // Adjusted for better proportions
                  ),
                  itemCount: topics.length + 1,
                  itemBuilder: (context, index) {
                    if (index == topics.length) {
                      return _AddTopicCard();
                    }
                    final t = topics[index];
                    final isSelected = selected?.id == t.id;
                    return Semantics(
                      label: '${t.name} topic${isSelected ? " selected" : ""}',
                      hint: isSelected
                          ? 'Currently selected topic'
                          : 'Double tap to select ${t.name} topic',
                      button: true,
                      selected: isSelected,
                      child: FocusOutline(
                        child: GestureDetector(
                          onTap: () =>
                              ref.read(selectedTopicProvider.notifier).state =
                                  t,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: 48, // WCAG 2.2 minimum tap target
                              minHeight: 48, // WCAG 2.2 minimum tap target
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary.withValues(
                                        alpha: 0.1,
                                      )
                                    : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outline,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 12,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Color(t.color),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Flexible(
                                    child: Text(
                                      t.name,
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Failed to load topics: $e'),
        ),
      ],
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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outline, width: 1),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 4),
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
              Text(
                'Add Topic',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
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
            height: MediaQuery.of(context).size.height * 0.6, // Limit height
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
                  const SizedBox(height: 20),
                  Text(
                    'Choose Color',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate optimal cross axis count based on available width
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
                          childAspectRatio: 1,
                        ),
                        itemCount: colorOptions.length,
                        itemBuilder: (context, index) {
                          final color = colorOptions[index];
                          final isSelected = selectedColor == color;
                          return GestureDetector(
                            onTap: () => setState(() => selectedColor = color),
                            child: SizedBox(
                              width: itemSize,
                              height: itemSize,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Color(color),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.onSurface
                                        : Colors.transparent,
                                    width: isSelected ? 3 : 0,
                                  ),
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        size: 16,
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
                if (name.isEmpty) return;
                await ref
                    .read(topicsControllerProvider.notifier)
                    .add(Topic(id: 'new', name: name, color: selectedColor));
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
