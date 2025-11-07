import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id; // doc id
  final String title;
  final String? note;
  final String priority; // 'low' | 'med' | 'high'
  final List<String> tags; // e.g., ['Coding','Reading']
  final bool completed;
  final DateTime createdAt;
  final DateTime? dueAt; // optional
  final int
  pomodorosDone; // count of completed focus sessions tied to this task
  final int minutesLogged; // total minutes from tied sessions
  final int pomodorosRequired; // threshold to auto-complete

  const Task({
    required this.id,
    required this.title,
    this.note,
    required this.priority,
    required this.tags,
    required this.completed,
    required this.createdAt,
    this.dueAt,
    required this.pomodorosDone,
    required this.minutesLogged,
    required this.pomodorosRequired,
  });

  factory Task.fromJson(Map<String, dynamic> json, String id) {
    return Task(
      id: id,
      title: json['title'] as String,
      note: json['note'] as String?,
      priority: json['priority'] as String,
      tags: List<String>.from(json['tags'] ?? []),
      completed: json['completed'] as bool? ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      dueAt: json['dueAt'] != null
          ? (json['dueAt'] as Timestamp).toDate()
          : null,
      pomodorosDone: json['pomodorosDone'] as int? ?? 0,
      minutesLogged: json['minutesLogged'] as int? ?? 0,
      pomodorosRequired: json['pomodorosRequired'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'note': note,
      'priority': priority,
      'tags': tags,
      'completed': completed,
      'createdAt': Timestamp.fromDate(createdAt),
      'dueAt': dueAt != null ? Timestamp.fromDate(dueAt!) : null,
      'pomodorosDone': pomodorosDone,
      'minutesLogged': minutesLogged,
      'pomodorosRequired': pomodorosRequired,
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? note,
    String? priority,
    List<String>? tags,
    bool? completed,
    DateTime? createdAt,
    DateTime? dueAt,
    int? pomodorosDone,
    int? minutesLogged,
    int? pomodorosRequired,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      dueAt: dueAt ?? this.dueAt,
      pomodorosDone: pomodorosDone ?? this.pomodorosDone,
      minutesLogged: minutesLogged ?? this.minutesLogged,
      pomodorosRequired: pomodorosRequired ?? this.pomodorosRequired,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task &&
        other.id == id &&
        other.title == title &&
        other.note == note &&
        other.priority == priority &&
        other.tags.toString() == tags.toString() &&
        other.completed == completed &&
        other.createdAt == createdAt &&
        other.dueAt == dueAt &&
        other.pomodorosDone == pomodorosDone &&
        other.minutesLogged == minutesLogged &&
        other.pomodorosRequired == pomodorosRequired;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      note,
      priority,
      tags,
      completed,
      createdAt,
      dueAt,
      pomodorosDone,
      minutesLogged,
      pomodorosRequired,
    );
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, priority: $priority, completed: $completed, pomodorosDone: $pomodorosDone, minutesLogged: $minutesLogged, pomodorosRequired: $pomodorosRequired)';
  }
}
