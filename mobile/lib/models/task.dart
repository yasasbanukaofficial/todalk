class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String priority;
  final bool isDone;
  final String source;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.priority = 'Medium',
    this.isDone = false,
    this.source = 'Voice',
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? priority,
    bool? isDone,
    String? source,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      isDone: isDone ?? this.isDone,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'dueDate': dueDate?.toIso8601String(),
    'priority': priority,
    'isDone': isDone,
    'source': source,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  Map<String, dynamic> toCreateJson() => {
    'title': title,
    'description': description,
    'dueDate': dueDate?.toIso8601String(),
    'priority': priority.toUpperCase(),
    'isCompleted': isDone,
  };

  Map<String, dynamic> toUpdateJson() => {
    'title': title,
    'description': description,
    'dueDate': dueDate?.toIso8601String(),
    'priority': priority.toUpperCase(),
    'isCompleted': isDone,
  };

  factory Task.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final title = json['title'] as String;
    final description = json['description'] as String?;

    DateTime? dueDate;
    if (json['dueDate'] != null) {
      dueDate = DateTime.parse(json['dueDate'] as String);
    }

    bool isDone;
    if (json.containsKey('isDone')) {
      isDone = json['isDone'] as bool? ?? false;
    } else {
      isDone = json['isCompleted'] as bool? ?? false;
    }

    String priority;
    if (json['priority'] is String) {
      final raw = json['priority'] as String;
      priority = raw.length == 3 ? '${raw[0]}${raw.substring(1).toLowerCase()}' : raw;
    } else {
      priority = 'Medium';
    }

    final source = json['source'] as String? ?? 'Voice';
    final createdAt = DateTime.parse(json['createdAt'] as String);

    DateTime updatedAt;
    if (json['updatedAt'] != null) {
      updatedAt = DateTime.parse(json['updatedAt'] as String);
    } else {
      updatedAt = createdAt;
    }

    return Task(
      id: id,
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
      isDone: isDone,
      source: source,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
