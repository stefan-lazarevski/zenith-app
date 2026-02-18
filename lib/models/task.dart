class Task {
  final String id;
  final String title;
  final String category;
  final DateTime deadline;
  final bool isCompleted;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    required this.category,
    required this.deadline,
    required this.isCompleted,
    required this.createdAt,
  });

  /// Creates a Task from a Firestore document map
  factory Task.fromMap(Map<String, dynamic> map, String documentId) {
    return Task(
      id: documentId,
      title: map['title'] as String? ?? '',
      category: map['category'] as String? ?? '',
      deadline: map['deadline'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['deadline'] as int)
          : DateTime.now(),
      isCompleted: map['isCompleted'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
    );
  }

  /// Converts Task to a Firestore document map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'deadline': deadline.millisecondsSinceEpoch,
      'isCompleted': isCompleted,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Creates a copy of this Task with the given fields replaced
  Task copyWith({
    String? id,
    String? title,
    String? category,
    DateTime? deadline,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, category: $category, deadline: $deadline, isCompleted: $isCompleted, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Task &&
        other.id == id &&
        other.title == title &&
        other.category == category &&
        other.deadline == deadline &&
        other.isCompleted == isCompleted &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        category.hashCode ^
        deadline.hashCode ^
        isCompleted.hashCode ^
        createdAt.hashCode;
  }
}
