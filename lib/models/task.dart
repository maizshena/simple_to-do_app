import 'dart:convert';

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime? due;
  final String? priority;
  final bool isDone;

  const Task({
    required this.id,
    required this.title,
    this.description,
    this.due,
    this.priority,
    this.isDone = false,
  }) : assert(title != '');

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? due,
    String? priority,
    bool? isDone,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      due: due ?? this.due,
      priority: priority ?? this.priority,
      isDone: isDone ?? this.isDone,
    );
    }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'due': due?.toIso8601String(),
        'priority': priority,           // gunakan key "priority"
        'isDone': isDone,
      };

  factory Task.fromMap(Map<String, dynamic> map) => Task(
        id: (map['id']?.toString()) ?? generateId(),
        // pastikan tidak kosong agar lolos assert
        title: (() {
          final t = (map['title'] as String?)?.trim();
          return (t == null || t.isEmpty) ? 'Untitled' : t;
        })(),
        description: map['description'] as String?,
        due: map['due'] == null
            ? null
            : (map['due'] is String
                ? DateTime.tryParse(map['due'])
                : (map['due'] is int
                    ? DateTime.fromMillisecondsSinceEpoch(map['due'])
                    : null)),
        // backward-compat: baca "priority" dulu, kalau null coba "category"
        priority: (map['priority'] ?? map['category']) as String?,
        isDone: (map['isDone'] as bool?) ?? false,
      );

  String toJson() => json.encode(toMap());

  factory Task.fromJson(String source) =>
      Task.fromMap(json.decode(source) as Map<String, dynamic>);

  bool get isOverdue =>
      (due != null) && !isDone && due!.isBefore(DateTime.now());

  @override
  String toString() =>
      'Task(id: $id, title: $title, due: $due, priority: $priority, isDone: $isDone)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Task && other.id == id);

  @override
  int get hashCode => id.hashCode;

  static String generateId() =>
      DateTime.now().microsecondsSinceEpoch.toString();
}
