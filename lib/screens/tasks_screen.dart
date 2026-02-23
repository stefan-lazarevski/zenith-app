import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import '../theme/app_theme.dart';
import 'add_edit_task_screen.dart';
import 'profile_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          // Profile icon (top-right)
          IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              child: Icon(
                Icons.account_circle,
                color: AppTheme.primary,
                size: 24,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, _) {
          final allTasks = taskProvider.tasks;
          final activeTasks = allTasks.where((task) => !task.isCompleted).toList();
          final completedTasks = allTasks.where((task) => task.isCompleted).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "What needs to be done?" bar — always visible
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                  vertical: AppTheme.spacingS,
                ),
                child: InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddEditTaskScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.primary.withOpacity(0.3)
                            : AppTheme.primary.withOpacity(0.2),
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Text(
                          'What needs to be done?',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Sort/Filter button (only shown when there are tasks)
              if (allTasks.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingM,
                    vertical: AppTheme.spacingS,
                  ),
                  child: InkWell(
                    onTap: () => _showSortFilterSheet(context, taskProvider),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingM,
                        vertical: AppTheme.spacingS,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.surfaceVariantDark
                            : AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tune,
                            size: 18,
                            color: taskProvider.filterCategory != null
                                ? AppTheme.primary
                                : null,
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                          Text(
                            taskProvider.filterCategory != null
                                ? taskProvider.filterCategory!
                                : 'Sort & Filter',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: taskProvider.filterCategory != null
                                  ? AppTheme.primary
                                  : null,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                          Icon(
                            Icons.expand_more,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Empty state or task list
              if (allTasks.isEmpty)
                Expanded(child: _buildEmptyState(context))
              else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  itemCount: activeTasks.length + (completedTasks.isNotEmpty ? 1 : 0) + (completedTasks.isNotEmpty ? 1 : 0) + (_showCompleted ? completedTasks.length : 0),
                  itemBuilder: (context, index) {
                    // 1. Active Tasks
                    if (index < activeTasks.length) {
                      final task = activeTasks[index];
                      return TaskCard(
                        key: ValueKey(task.id),
                        task: task,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddEditTaskScreen(task: task),
                            ),
                          );
                        },
                        onToggle: () {
                          taskProvider.toggleTaskCompletion(task.id);
                        },
                        onDelete: () {
                          taskProvider.deleteTask(task.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Task deleted'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      );
                    }
                    
                    int currentIndex = activeTasks.length;
                    
                    // 2. Divider (if needed)
                    if (completedTasks.isNotEmpty) {
                      if (index == currentIndex) {
                        return Column(
                          children: [
                            const SizedBox(height: AppTheme.spacingL),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                              child: Divider(
                                height: 1,
                                thickness: 2,
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingS),
                          ],
                        );
                      }
                      currentIndex++;
                      
                      // 3. Completed Header
                      if (index == currentIndex) {
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _showCompleted = !_showCompleted;
                            });
                          },
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingM,
                              vertical: AppTheme.spacingS,
                            ),
                            margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppTheme.surfaceVariantDark
                                  : AppTheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _showCompleted ? Icons.expand_less : Icons.expand_more,
                                  size: 20,
                                ),
                                const SizedBox(width: AppTheme.spacingS),
                                Text(
                                  'Completed',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingS),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.success.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                  ),
                                  child: Text(
                                    '${completedTasks.length}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.success,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      currentIndex++;
                      
                      // 4. Completed Tasks
                      if (_showCompleted) {
                        final completedIndex = index - currentIndex;
                        final task = completedTasks[completedIndex];
                        return TaskCard(
                          key: ValueKey(task.id),
                          task: task,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddEditTaskScreen(task: task),
                              ),
                            );
                          },
                          onToggle: () {
                            taskProvider.toggleTaskCompletion(task.id);
                          },
                          onDelete: () {
                            taskProvider.deleteTask(task.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Task deleted'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        );
                      }
                    }
                    
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              'No tasks yet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Tap + to create your first task',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  void _showSortFilterSheet(BuildContext context, TaskProvider taskProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusL)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort & Filter',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingL),
            
            // Sort options
            Text(
              'Sort by',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Wrap(
              spacing: AppTheme.spacingS,
              children: [
                ChoiceChip(
                  label: const Text('Created'),
                  selected: taskProvider.sortOption == TaskSortOption.createdDate,
                  onSelected: (_) {
                    taskProvider.setSortOption(TaskSortOption.createdDate);
                    Navigator.pop(context);
                  },
                ),
                ChoiceChip(
                  label: const Text('Deadline'),
                  selected: taskProvider.sortOption == TaskSortOption.deadline,
                  onSelected: (_) {
                    taskProvider.setSortOption(TaskSortOption.deadline);
                    Navigator.pop(context);
                  },
                ),
                ChoiceChip(
                  label: const Text('Category'),
                  selected: taskProvider.sortOption == TaskSortOption.category,
                  onSelected: (_) {
                    taskProvider.setSortOption(TaskSortOption.category);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingL),
            
            // Filter options
            Text(
              'Filter by category',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Wrap(
              spacing: AppTheme.spacingS,
              children: [
                ...taskProvider.categories.map((category) {
                  return ChoiceChip(
                    label: Text(category),
                    selected: taskProvider.filterCategory == category,
                    onSelected: (_) {
                      taskProvider.setFilterCategory(category);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
          ],
        ),
      ),
    );
  }
}
