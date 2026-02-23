import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkOpacity;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _checkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Set initial state
    if (widget.task.isCompleted) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only animate if the completion state actually changed from the outside source of truth
    // AND it matches our local controller state (to avoid fighting with local animation)
    if (widget.task.isCompleted != oldWidget.task.isCompleted) {
      if (widget.task.isCompleted) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  void _handleToggle() {
    // 1. Animate visually immediately
    if (_animationController.status == AnimationStatus.completed) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }

    // 2. Wait for animation to finish before notifying parent
    // This prevents the parent from rebuilding us (and killing our animation) 
    // before we're done.
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        widget.onToggle();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = widget.task.deadline.isBefore(DateTime.now()) && !widget.task.isCompleted;
    
    return Dismissible(
      key: Key(widget.task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.spacingL),
        decoration: BoxDecoration(
          color: AppTheme.error,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) => widget.onDelete(),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          // Calculate values based on controller
          final isChecked = _animationController.value > 0.5;
          
          return Card(
            margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Row(
                  children: [
                    // Animated checkbox
                    GestureDetector(
                      onTap: _handleToggle,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isChecked
                                ? AppTheme.success
                                : Colors.transparent,
                            border: Border.all(
                              color: isChecked
                                  ? AppTheme.success
                                  : Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.4) ?? Colors.grey,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: isChecked
                              ? FadeTransition(
                                  opacity: _checkOpacity,
                                  child: const Icon(
                                    Icons.check,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: AppTheme.spacingM),
                    
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title with animated strikethrough
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                              decoration: isChecked
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isChecked
                                  ? Theme.of(context).textTheme.bodySmall?.color
                                  : Theme.of(context).textTheme.titleMedium?.color,
                            ),
                            child: Text(widget.task.title),
                          ),

                          // Description (optional)
                          if (widget.task.description != null &&
                              widget.task.description!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                color: isChecked
                                    ? Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5)
                                    : Theme.of(context).textTheme.bodySmall?.color,
                              ),
                              child: Text(
                                widget.task.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],

                          const SizedBox(height: AppTheme.spacingXs),

                          // Category
                          Row(
                            children: [
                              Text(
                                widget.task.category,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              
                              const SizedBox(width: AppTheme.spacingM),
                              
                              // Deadline badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingS,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isOverdue
                                      ? AppTheme.error.withOpacity(0.1)
                                      : _getDeadlineColor(widget.task.deadline).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                ),
                                child: Text(
                                  _formatDeadline(widget.task.deadline),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isOverdue
                                        ? AppTheme.error
                                        : _getDeadlineColor(widget.task.deadline),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    
    if (difference.isNegative) {
      return 'Overdue';
    } else if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days';
    } else {
      return DateFormat('MMM d').format(deadline);
    }
  }

  Color _getDeadlineColor(DateTime deadline) {
    final difference = deadline.difference(DateTime.now());
    
    if (difference.inDays <= 1) {
      return AppTheme.warning;
    } else if (difference.inDays <= 3) {
      return AppTheme.info;
    } else {
      return AppTheme.success;
    }
  }
}
