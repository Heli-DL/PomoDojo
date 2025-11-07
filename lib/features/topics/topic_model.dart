class Topic {
  final String id;
  final String name;
  final int color; // store ARGB int
  const Topic({required this.id, required this.name, required this.color});

  factory Topic.fromJson(Map<String, dynamic> json, String id) {
    return Topic(
      id: id,
      name: json['name'] as String,
      color:
          (json['color'] as num?)?.toInt() ?? 0xFF80CBC4, // Default muted teal
    );
  }
  Map<String, dynamic> toJson() => {'name': name, 'color': color};

  /// Check if this topic is a predefined topic (cannot be deleted)
  bool get isPredefined => predefinedTopics.any((topic) => topic.id == id);
}

const predefinedTopics = <Topic>[
  Topic(id: 'study', name: 'Study', color: 0xFFB39DDB), // Muted Lavender
  Topic(id: 'work', name: 'Work', color: 0xFF80CBC4), // Muted Teal
  Topic(id: 'exercise', name: 'Exercise', color: 0xFFEF9A9A), // Muted Rose
  Topic(id: 'reading', name: 'Reading', color: 0xFFA5D6A7), // Muted Sage
  Topic(id: 'writing', name: 'Writing', color: 0xFFFFCC80), // Muted Peach
  Topic(id: 'creative', name: 'Creative', color: 0xFFCE93D8), // Muted Mauve
];
