import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';
import '../theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final hasFunctionCall = message.functionCall != null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingXs,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) _buildAvatar(false),
          if (!isUser) const SizedBox(width: AppTheme.spacingS),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingM,
                    vertical: AppTheme.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppTheme.primary
                        : (Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.surfaceVariantDark
                            : AppTheme.surfaceVariant),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(AppTheme.radiusM),
                      topRight: const Radius.circular(AppTheme.radiusM),
                      bottomLeft: Radius.circular(isUser ? AppTheme.radiusM : 4),
                      bottomRight: Radius.circular(isUser ? 4 : AppTheme.radiusM),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasFunctionCall) _buildFunctionBadge(),
                      if (hasFunctionCall) const SizedBox(height: AppTheme.spacingXs),
                      Text(
                        message.content,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: isUser ? Colors.white : null,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingS),
                  child: Text(
                    _formatTime(message.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                        ),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: AppTheme.spacingS),
          if (isUser) _buildAvatar(true),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isUser ? AppTheme.primary.withOpacity(0.2) : AppTheme.secondary.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          isUser ? '👤' : '🧠',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildFunctionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingS,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppTheme.success.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            size: 14,
            color: AppTheme.success,
          ),
          const SizedBox(width: 4),
          Text(
            'Task Created',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.success,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(timestamp);
    }
  }
}
