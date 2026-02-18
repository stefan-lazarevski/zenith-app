import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/journal.dart';

class JournalProvider extends ChangeNotifier {
  final List<Journal> _journals = [];
  final Uuid _uuid = const Uuid();

  JournalProvider() {
    _initializeDummyData();
  }

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

  // Initialize dummy data
  void _initializeDummyData() {
    final now = DateTime.now();

    _journals.addAll([
      Journal(
        id: _uuid.v4(),
        title: 'Productive Day',
        content:
            'Today was incredibly productive! Finished all my assignments early and had time to relax. Feeling grateful and energized.',
        sentimentEmoji: '😊',
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      Journal(
        id: _uuid.v4(),
        title: 'Project Stress',
        content:
            'Had a rough morning with the project deadline looming. Feeling stressed but trying to stay focused. One step at a time.',
        sentimentEmoji: '😰',
        timestamp: now.subtract(const Duration(days: 1, hours: 5)),
      ),
      Journal(
        id: _uuid.v4(),
        title: 'Coffee with a Friend',
        content:
            'Coffee with an old friend today. We talked for hours about everything and nothing. These moments remind me what truly matters.',
        sentimentEmoji: '☕',
        timestamp: now.subtract(const Duration(days: 2, hours: 3)),
      ),
      Journal(
        id: _uuid.v4(),
        title: 'Feeling Overwhelmed',
        content:
            'Feeling overwhelmed by everything on my plate. Need to take a step back and prioritize. Maybe a walk will help clear my head.',
        sentimentEmoji: '😔',
        timestamp: now.subtract(const Duration(days: 3, hours: 7)),
      ),
      Journal(
        id: _uuid.v4(),
        title: 'Work Milestone',
        content:
            'Accomplished a major milestone at work today! The presentation went better than expected. Celebrating the small wins.',
        sentimentEmoji: '🎉',
        timestamp: now.subtract(const Duration(days: 4, hours: 1)),
      ),
      Journal(
        id: _uuid.v4(),
        title: 'Quiet Sunday Morning',
        content:
            'Quiet Sunday morning. Reading a good book with tea. These peaceful moments are rare but so necessary for recharging.',
        sentimentEmoji: '📖',
        timestamp: now.subtract(const Duration(days: 5, hours: 10)),
      ),
      Journal(
        id: _uuid.v4(),
        title: 'Unfocused Day',
        content:
            'Struggled to focus today. Mind keeps wandering. Sometimes it\'s okay to have off days. Tomorrow is a new opportunity.',
        sentimentEmoji: '😐',
        timestamp: now.subtract(const Duration(days: 6, hours: 4)),
      ),
      Journal(
        id: _uuid.v4(),
        title: 'New Workout Routine',
        content:
            'Started a new workout routine. Body is sore but mind feels clear. Excited to build this habit and see where it takes me.',
        sentimentEmoji: '💪',
        timestamp: now.subtract(const Duration(days: 7, hours: 8)),
      ),
    ]);
  }
}
