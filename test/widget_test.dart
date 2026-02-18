// This is a basic Flutter widget test.
//
// These tests will be expanded once the UI is implemented.

import 'package:flutter_test/flutter_test.dart';
import 'package:zenith_app/models/task.dart';
import 'package:zenith_app/models/journal.dart';

void main() {
  group('Task Model Tests', () {
    test('Task serialization and deserialization', () {
      final now = DateTime.now();
      final task = Task(
        id: 'test-id',
        title: 'Test Task',
        category: 'Work',
        deadline: now,
        isCompleted: false,
        createdAt: now,
      );

      final map = task.toMap();
      final deserializedTask = Task.fromMap(map, 'test-id');

      expect(deserializedTask.id, task.id);
      expect(deserializedTask.title, task.title);
      expect(deserializedTask.category, task.category);
      expect(deserializedTask.isCompleted, task.isCompleted);
    });
  });

  group('Journal Model Tests', () {
    test('Journal serialization and deserialization', () {
      final now = DateTime.now();
      final journal = Journal(
        id: 'test-id',
        content: 'Test journal entry',
        sentimentEmoji: '😊',
        timestamp: now, title: '',
      );

      final map = journal.toMap();
      final deserializedJournal = Journal.fromMap(map, 'test-id');

      expect(deserializedJournal.id, journal.id);
      expect(deserializedJournal.content, journal.content);
      expect(deserializedJournal.sentimentEmoji, journal.sentimentEmoji);
    });
  });
}

