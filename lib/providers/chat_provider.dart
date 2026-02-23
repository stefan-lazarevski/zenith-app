import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../services/deepseek_service.dart';
import 'task_provider.dart';

class ChatProvider extends ChangeNotifier {
  final List<Message> _messages = [];
  final DeepSeekService _deepSeekService = DeepSeekService();
  final TaskProvider _taskProvider;
  final Uuid _uuid = const Uuid();

  bool _isLoading = false;
  String? _error;

  /// Holds a pending task that the AI has summarised but the user hasn't
  /// confirmed yet. When the user confirms we create it client-side,
  /// guaranteeing the task is always actually saved.
  Map<String, dynamic>? _pendingTask;

  ChatProvider(this._taskProvider) {
    _addWelcomeMessage();
  }

  // Getters
  List<Message> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _addWelcomeMessage() {
    _messages.add(
      Message(
        id: _uuid.v4(),
        content: "Hi, I'm Zora, your Zenith assistant. Let's make today count! I'm here to help you organize your week or track how you're doing today."
            "\nTry saying things like:\n\n"
            "• \"Remind me to buy groceries tomorrow\"\n"
            "• \"Add a task to study for midterms next Friday\"\n"
            "• \"Create a work task for the presentation on Monday\"",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Returns true if the user message looks like a confirmation
  bool _isConfirmation(String text) {
    final lower = text.toLowerCase().trim();
    const confirmWords = [
      'yes', 'yeah', 'yep', 'yup', 'sure', 'ok', 'okay', 'fine',
      'correct', 'looks good', 'that\'s fine', 'that is fine',
      'no changes', 'no change', 'proceed', 'go ahead', 'create it',
      'do it', 'confirm', 'confirmed', 'perfect', 'great', 'sounds good',
    ];
    return confirmWords.any((w) => lower == w || lower.startsWith('$w ') || lower.endsWith(' $w'));
  }

  /// Send a user message and get AI response
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    _error = null;

    // Add user message to display
    final userMessage = Message(
      id: _uuid.v4(),
      content: content.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    notifyListeners();

    // ── Client-side confirmation shortcut ──────────────────────────────
    // If there's a pending task and the user just confirmed, create it
    // immediately without another API round-trip.
    if (_pendingTask != null && _isConfirmation(content.trim())) {
      _isLoading = true;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 300)); // feel snappy

      final task = _pendingTask!;
      _pendingTask = null;

      try {
        final deadline = DateTime.parse(task['deadline'] as String);
        _taskProvider.addTask(
          title: task['title'] as String,
          category: task['category'] as String,
          deadline: deadline,
        );

        _addAIMessage(
          "✓ Done! I've added \"${task['title']}\" to your ${task['category']} tasks, due ${_formatDate(deadline)}.",
          functionCall: {
            'function': 'create_task',
            'title': task['title'],
            'category': task['category'],
            'deadline': task['deadline'],
          },
        );
      } catch (e) {
        _addAIMessage('Something went wrong creating that task. Please try again.');
      }

      _isLoading = false;
      notifyListeners();
      return;
    }
    // ──────────────────────────────────────────────────────────────────

    // Normal API path
    _isLoading = true;
    notifyListeners();

    try {
      final conversationHistory = _messages
          .where((m) => m.functionCall == null)
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.content,
              })
          .toList();

      final response = await _deepSeekService.sendMessage(
        userMessage: content.trim(),
        conversationHistory: conversationHistory.length > 10
            ? conversationHistory.sublist(conversationHistory.length - 10)
            : conversationHistory,
      );

      if (response['type'] == 'function_call') {
        await _handleFunctionCall(response);
      } else {
        // Regular message — check if it looks like a task summary so we can
        // pre-parse and store it as a pending task for the next confirmation.
        _addAIMessage(response['content']);
      }
    } catch (e) {
      _error = 'Failed to get response: ${e.toString()}';
      _addAIMessage(
          'Sorry, I encountered an error: ${e.toString()}\n\nPlease check your internet connection and try again.');
      debugPrint('ChatProvider error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Handle AI function calls (task draft or creation)
  Future<void> _handleFunctionCall(Map<String, dynamic> response) async {
    final functionName = response['function'];
    final arguments = response['arguments'];

    if (functionName == 'draft_task') {
      // Store as pending — the user must confirm before we create
      _pendingTask = {
        'title': arguments['title'],
        'category': arguments['category'],
        'deadline': arguments['deadline'],
      };

      try {
        final deadline = DateTime.parse(arguments['deadline'] as String);
        _addAIMessage(
          "Here's what I'll create:\n\n"
          "📝 **${arguments['title']}**\n"
          "📁 ${arguments['category']}\n"
          "📅 Due ${_formatDate(deadline)}\n\n"
          "Shall I go ahead, or would you like to change anything?",
        );
      } catch (_) {
        _addAIMessage(
          "Here's what I'll create:\n\n"
          "📝 **${arguments['title']}**\n"
          "📁 ${arguments['category']}\n"
          "📅 ${arguments['deadline']}\n\n"
          "Shall I go ahead, or would you like to change anything?",
        );
      }
    } else if (functionName == 'create_task') {
      try {
        final deadlineString = arguments['deadline'] as String;
        final deadline = DateTime.parse(deadlineString);

        _taskProvider.addTask(
          title: arguments['title'] as String,
          category: arguments['category'] as String,
          deadline: deadline,
        );

        _pendingTask = null;

        _addAIMessage(
          "✓ I've created a task: \"${arguments['title']}\" in ${arguments['category']} "
          "with deadline ${_formatDate(deadline)}.",
          functionCall: {
            'function': 'create_task',
            'title': arguments['title'],
            'category': arguments['category'],
            'deadline': deadlineString,
          },
        );
      } catch (e) {
        _addAIMessage(
            'I had trouble creating that task. Could you try rephrasing your request?');
      }
    }
  }

  /// Store a pending task extracted from an AI summary message
  void setPendingTask(Map<String, dynamic> taskDetails) {
    _pendingTask = taskDetails;
  }

  void _addAIMessage(String content, {Map<String, dynamic>? functionCall}) {
    _messages.add(
      Message(
        id: _uuid.v4(),
        content: content,
        isUser: false,
        timestamp: DateTime.now(),
        functionCall: functionCall,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return 'today at ${_formatTime(date)}';
    } else if (targetDate == tomorrow) {
      return 'tomorrow at ${_formatTime(date)}';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day} at ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    final hour =
        date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clears the chat history — call this when a user signs out
  void clear() {
    _messages.clear();
    _pendingTask = null;
    _addWelcomeMessage();
    notifyListeners();
  }
}
