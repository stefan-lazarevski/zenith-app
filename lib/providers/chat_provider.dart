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

  /// Send a user message and get AI response
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    _error = null;

    // Add user message
    final userMessage = Message(
      id: _uuid.v4(),
      content: content.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    notifyListeners();

    // Start loading
    _isLoading = true;
    notifyListeners();

    try {
      // Build conversation history for context
      final conversationHistory = _messages
          .where((m) => m.functionCall == null) // Exclude function call messages
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.content,
              })
          .toList();

      // Send to DeepSeek
      final response = await _deepSeekService.sendMessage(
        userMessage: content.trim(),
        conversationHistory: conversationHistory.length > 10
            ? conversationHistory.sublist(conversationHistory.length - 10)
            : conversationHistory,
      );

      if (response['type'] == 'function_call') {
        // AI wants to create a task
        await _handleFunctionCall(response);
      } else {
        // Regular AI response
        _addAIMessage(response['content']);
      }
    } catch (e) {
      _error = 'Failed to get response: ${e.toString()}';
      _addAIMessage('Sorry, I encountered an error: ${e.toString()}\n\nPlease check your internet connection and try again.');
      debugPrint('ChatProvider error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Handle AI function calls (task creation)
  Future<void> _handleFunctionCall(Map<String, dynamic> response) async {
    final functionName = response['function'];
    final arguments = response['arguments'];

    if (functionName == 'create_task') {
      try {
        // Parse deadline
        final deadlineString = arguments['deadline'] as String;
        final deadline = DateTime.parse(deadlineString);

        // Create task via TaskProvider
        _taskProvider.addTask(
          title: arguments['title'] as String,
          category: arguments['category'] as String,
          deadline: deadline,
        );

        // Add success message with function call data
        final taskCreatedMessage = Message(
          id: _uuid.v4(),
          content: "✓ I've created a task: \"${arguments['title']}\" in ${arguments['category']} "
              "with deadline ${_formatDate(deadline)}.",
          isUser: false,
          timestamp: DateTime.now(),
          functionCall: {
            'function': 'create_task',
            'title': arguments['title'],
            'category': arguments['category'],
            'deadline': deadlineString,
          },
        );
        _messages.add(taskCreatedMessage);
      } catch (e) {
        _addAIMessage('I had trouble creating that task. Could you try rephrasing your request?');
      }
    }
  }

  void _addAIMessage(String content) {
    _messages.add(
      Message(
        id: _uuid.v4(),
        content: content,
        isUser: false,
        timestamp: DateTime.now(),
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
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day} at ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
