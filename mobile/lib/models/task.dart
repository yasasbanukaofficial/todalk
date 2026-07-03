class Task {
  final String id;
  final String title;
  final DateTime? dueDate;
  final String priority;
  final bool isDone;
  final String source;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.dueDate,
    this.priority = 'Medium',
    this.isDone = false,
    this.source = 'Voice',
    required this.createdAt,
  });

  Task copyWith({
    String? id,
    String? title,
    DateTime? dueDate,
    String? priority,
    bool? isDone,
    String? source,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      isDone: isDone ?? this.isDone,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'dueDate': dueDate?.toIso8601String(),
    'priority': priority,
    'isDone': isDone,
    'source': source,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String,
    title: json['title'] as String,
    dueDate: json['dueDate'] != null
        ? DateTime.parse(json['dueDate'] as String)
        : null,
    priority: json['priority'] as String? ?? 'Medium',
    isDone: json['isDone'] as bool? ?? false,
    source: json['source'] as String? ?? 'Voice',
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
