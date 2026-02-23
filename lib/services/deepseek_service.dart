import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class DeepSeekService {
  static String get _apiKey => dotenv.env['DEEPSEEK_API_KEY'] ?? '';
  static const String _baseUrl = 'https://openrouter.ai/api/v1';
  static const String _model = 'deepseek/deepseek-chat';

  static const List<Map<String, dynamic>> _taskCreationTools = [
    {
      "type": "function",
      "function": {
        "name": "draft_task",
        "description":
            "Show the user a structured confirmation summary of a task before creating it. Call this FIRST when the user asks to create a task, so they can review and confirm the details.",
        "parameters": {
          "type": "object",
          "properties": {
            "title": {
              "type": "string",
              "description": "The title or main action of the task"
            },
            "category": {
              "type": "string",
              "enum": ["🎓 College", "🛒 Shopping", "💼 Work", "🏠 Personal"],
              "description": "The category that best fits this task"
            },
            "deadline": {
              "type": "string",
              "description":
                  "The deadline in ISO 8601 format (YYYY-MM-DDTHH:mm:ss). If only a day is mentioned, use noon (12:00:00). If no time is specified, default to 09:00:00."
            }
          },
          "required": ["title", "category", "deadline"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "create_task",
        "description":
            "Actually create and save the task. Call this ONLY after the user has confirmed the draft details.",
        "parameters": {
          "type": "object",
          "properties": {
            "title": {
              "type": "string",
              "description": "The title or main action of the task"
            },
            "category": {
              "type": "string",
              "enum": ["🎓 College", "🛒 Shopping", "💼 Work", "🏠 Personal"],
              "description": "The category that best fits this task"
            },
            "deadline": {
              "type": "string",
              "description":
                  "The deadline in ISO 8601 format (YYYY-MM-DDTHH:mm:ss). If only a day is mentioned, use noon (12:00:00). If no time is specified, default to 09:00:00."
            }
          },
          "required": ["title", "category", "deadline"]
        }
      }
    }
  ];

  /// Send a chat message and get AI response with optional task creation
  Future<Map<String, dynamic>> sendMessage({
    required String userMessage,
    List<Map<String, dynamic>>? conversationHistory,
  }) async {
    try {
      final messages = [
        {
          "role": "system",
          "content":
              "You are Zora, Zenith's AI assistant for task management. Today's date is ${DateTime.now().toIso8601String().split('T')[0]}.\n\n"
              "TASK CREATION RULES — follow these exactly:\n"
              "1. When the user asks to create a task, first reply with a short confirmation summary (title, category, deadline) and ask if they would like any changes.\n"
              "2. When the user confirms (says yes, looks good, no changes, proceed, that is fine, etc.) you MUST immediately call the create_task function. Do NOT describe the creation in text — CALL THE FUNCTION. The function call IS the creation.\n"
              "3. If you write 'task created' or 'I have created' in text without calling create_task, the task will NOT be saved. This is an error — always use the function.\n"
              "4. For any edits the user requests before confirming, update your summary and ask again.\n\n"
              "CATEGORIES: only use these exact values: 🎓 College, 🛒 Shopping, 💼 Work, 🏠 Personal.\n"
              "DEADLINES: parse natural language (tomorrow, next Monday, etc.) relative to today. Default time is 09:00 if not specified.\n\n"
              "For non-task questions, be concise and helpful."
        },
        ...?conversationHistory,
        {"role": "user", "content": userMessage}
      ];

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'tools': _taskCreationTools,
          'temperature': 0.7,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out after 30 seconds');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final choice = data['choices'][0];
        final message = choice['message'];

        // Check if AI wants to call a function
        if (message['tool_calls'] != null && message['tool_calls'].isNotEmpty) {
          final toolCall = message['tool_calls'][0];
          final functionName = toolCall['function']['name'];
          final arguments = jsonDecode(toolCall['function']['arguments']);

          return {
            'type': 'function_call',
            'function': functionName,
            'arguments': arguments,
            'content': null,
          };
        }

        // Regular message response
        return {
          'type': 'message',
          'content': message['content'],
          'function': null,
          'arguments': null,
        };
      } else {
        throw Exception('API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Analyze journal content and suggest sentiment emoji
  Future<String> analyzeSentiment(String journalContent) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              "role": "system",
              "content": "You are a sentiment analyzer. Analyze the emotional tone of journal entries and respond with a SINGLE emoji that best represents the mood. "
                  "Only respond with the emoji character, nothing else. "
                  "Examples: 😊 (happy), 😔 (sad), 😰 (stressed), 😤 (angry), 🤔 (thoughtful), 😴 (tired), 🎉 (excited), ☕ (peaceful)"
            },
            {"role": "user", "content": journalContent}
          ],
          'temperature': 0.3,
          'max_tokens': 10,
        }),
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw Exception('Sentiment analysis timed out');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final emoji = data['choices'][0]['message']['content'].trim();
        
        // Validate it's a single emoji (basic check)
        if (emoji.length <= 4) {
          return emoji;
        }
        
        return '😐'; // Fallback if response is invalid
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to neutral emoji on error
      return '😐';
    }
  }
  
  Future<bool> testConnection() async {
    try {
      final response = await sendMessage(
        userMessage: 'Hello',
      );
      return response['type'] == 'message';
    } catch (e) {
      return false;
    }
  }
}
