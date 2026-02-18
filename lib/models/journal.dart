class Journal {
  final String id;
  final String title;
  final String content;
  final String sentimentEmoji;
  final DateTime timestamp;

  Journal({
    required this.id,
    required this.title,
    required this.content,
    required this.sentimentEmoji,
    required this.timestamp,
  });

  /// Creates a Journal from a Firestore document map
  factory Journal.fromMap(Map<String, dynamic> map, String documentId) {
    return Journal(
      id: documentId,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      sentimentEmoji: map['sentimentEmoji'] as String? ?? '😐',
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
          : DateTime.now(),
    );
  }

  /// Converts Journal to a Firestore document map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'sentimentEmoji': sentimentEmoji,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  /// Creates a copy of this Journal with the given fields replaced
  Journal copyWith({
    String? id,
    String? title,
    String? content,
    String? sentimentEmoji,
    DateTime? timestamp,
  }) {
    return Journal(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      sentimentEmoji: sentimentEmoji ?? this.sentimentEmoji,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'Journal(id: $id, content: $content, sentimentEmoji: $sentimentEmoji, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Journal &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.sentimentEmoji == sentimentEmoji &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        content.hashCode ^
        sentimentEmoji.hashCode ^
        timestamp.hashCode;
  }
}
