import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';
import '../models/journal.dart';

/// Repository for managing Task entities in Firestore
class TaskRepository {
  final FirebaseFirestore _firestore;
  final String collectionName;

  TaskRepository({
    FirebaseFirestore? firestore,
    this.collectionName = 'tasks',
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get reference to the tasks collection
  CollectionReference get _collection => _firestore.collection(collectionName);

  /// Create a new task
  Future<String> createTask(Task task) async {
    try {
      final docRef = await _collection.add(task.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  /// Get a task by ID
  Future<Task?> getTask(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists) {
        return null;
      }
      return Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception('Failed to get task: $e');
    }
  }

  /// Get all tasks as a stream
  Stream<List<Task>> getTasks() {
    return _collection.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) =>
                  Task.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList(),
        );
  }

  /// Get tasks filtered by category
  Stream<List<Task>> getTasksByCategory(String category) {
    return _collection
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) =>
                  Task.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList(),
        );
  }

  /// Get tasks filtered by completion status
  Stream<List<Task>> getTasksByStatus(bool isCompleted) {
    return _collection
        .where('isCompleted', isEqualTo: isCompleted)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) =>
                  Task.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList(),
        );
  }

  /// Update a task
  Future<void> updateTask(Task task) async {
    try {
      await _collection.doc(task.id).update(task.toMap());
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  /// Delete a task
  Future<void> deleteTask(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  /// Toggle task completion status
  Future<void> toggleTaskCompletion(String id, bool isCompleted) async {
    try {
      await _collection.doc(id).update({'isCompleted': isCompleted});
    } catch (e) {
      throw Exception('Failed to toggle task completion: $e');
    }
  }
}

/// Repository for managing Journal entities in Firestore
class JournalRepository {
  final FirebaseFirestore _firestore;
  final String collectionName;

  JournalRepository({
    FirebaseFirestore? firestore,
    this.collectionName = 'journals',
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get reference to the journals collection
  CollectionReference get _collection => _firestore.collection(collectionName);

  /// Create a new journal entry
  Future<String> createJournal(Journal journal) async {
    try {
      final docRef = await _collection.add(journal.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create journal: $e');
    }
  }

  /// Get a journal entry by ID
  Future<Journal?> getJournal(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists) {
        return null;
      }
      return Journal.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception('Failed to get journal: $e');
    }
  }

  /// Get all journal entries as a stream
  Stream<List<Journal>> getJournals() {
    return _collection.orderBy('timestamp', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) =>
                  Journal.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList(),
        );
  }

  /// Get journal entries filtered by date range
  Stream<List<Journal>> getJournalsByDateRange(
      DateTime startDate, DateTime endDate) {
    return _collection
        .where('timestamp',
            isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch)
        .where('timestamp', isLessThanOrEqualTo: endDate.millisecondsSinceEpoch)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) =>
                  Journal.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList(),
        );
  }

  /// Get journal entries filtered by sentiment emoji
  Stream<List<Journal>> getJournalsBySentiment(String sentimentEmoji) {
    return _collection
        .where('sentimentEmoji', isEqualTo: sentimentEmoji)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) =>
                  Journal.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList(),
        );
  }

  /// Update a journal entry
  Future<void> updateJournal(Journal journal) async {
    try {
      await _collection.doc(journal.id).update(journal.toMap());
    } catch (e) {
      throw Exception('Failed to update journal: $e');
    }
  }

  /// Delete a journal entry
  Future<void> deleteJournal(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete journal: $e');
    }
  }
}
