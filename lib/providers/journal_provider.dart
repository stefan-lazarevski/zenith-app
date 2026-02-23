import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/journal.dart';

class JournalProvider extends ChangeNotifier {
  final List<Journal> _journals = [];
  final Uuid _uuid = const Uuid();

  JournalProvider();

  // Getters
  List<Journal> get journals {
    // Return sorted by timestamp, newest first
    final sortedJournals = List<Journal>.from(_journals);
    sortedJournals.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sortedJournals;
  }

  List<Journal> getJournalsByDateRange(DateTime startDate, DateTime endDate) {
    return _journals
        .where((journal) =>
            journal.timestamp.isAfter(startDate) &&
            journal.timestamp.isBefore(endDate))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Map<String, int> get sentimentDistribution {
    final Map<String, int> distribution = {};
    for (var journal in _journals) {
      distribution[journal.sentimentEmoji] =
          (distribution[journal.sentimentEmoji] ?? 0) + 1;
    }
    return distribution;
  }

  int get totalEntries => _journals.length;

  // CRUD Operations
  void addJournal({
    required String title,
    required String content,
    required String sentimentEmoji,
  }) {
    final journal = Journal(
      id: _uuid.v4(),
      title: title,
      content: content,
      sentimentEmoji: sentimentEmoji,
      timestamp: DateTime.now(),
    );
    _journals.add(journal);
    notifyListeners();
  }

  void updateJournal(Journal updatedJournal) {
    final index = _journals.indexWhere((j) => j.id == updatedJournal.id);
    if (index != -1) {
      _journals[index] = updatedJournal;
      notifyListeners();
    }
  }

  void deleteJournal(String id) {
    _journals.removeWhere((j) => j.id == id);
    notifyListeners();
  }

  /// Clears all data — call this when a user signs out
  void clear() {
    _journals.clear();
    notifyListeners();
  }
}
