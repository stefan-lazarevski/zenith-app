import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';

enum TaskSortOption {
  category,
  deadline,
  createdDate,
}

class TaskProvider extends ChangeNotifier {
  final List<Task> _tasks = [];
  final Uuid _uuid = const Uuid();
  TaskSortOption _sortOption = TaskSortOption.createdDate;
  String? _filterCategory;

  TaskProvider();

  // Getters
  List<Task> get tasks {
    var filteredTasks = _tasks;
    
    // Apply category filter
    if (_filterCategory != null) {
      filteredTasks = filteredTasks
          .where((task) => task.category == _filterCategory)
          .toList();
    }
    
    // Apply sorting
    switch (_sortOption) {
      case TaskSortOption.category:
        filteredTasks.sort((a, b) => a.category.compareTo(b.category));
        break;
      case TaskSortOption.deadline:
        filteredTasks.sort((a, b) => a.deadline.compareTo(b.deadline));
        break;
      case TaskSortOption.createdDate:
        filteredTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    
    return filteredTasks;
  }

  TaskSortOption get sortOption => _sortOption;
  String? get filterCategory => _filterCategory;

  List<String> get categories {
    return _tasks.map((task) => task.category).toSet().toList()..sort();
  }

  int get completedCount {
    return _tasks.where((task) => task.isCompleted).length;
  }

  int get pendingCount {
    return _tasks.where((task) => !task.isCompleted).length;
  }

  // CRUD Operations
  void addTask({
    required String title,
    String? description,
    required String category,
    required DateTime deadline,
  }) {
    final task = Task(
      id: _uuid.v4(),
      title: title,
      description: description?.trim().isEmpty == true ? null : description?.trim(),
      category: category,
      deadline: deadline,
      isCompleted: false,
      createdAt: DateTime.now(),
    );
    _tasks.add(task);
    notifyListeners();
  }

  void updateTask(Task updatedTask) {
    final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      notifyListeners();
    }
  }

  void deleteTask(String id) {
    _tasks.removeWhere((task) => task.id == id);
    notifyListeners();
  }

  void toggleTaskCompletion(String id) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        isCompleted: !_tasks[index].isCompleted,
      );
      notifyListeners();
    }
  }

  // Filtering and Sorting
  void setSortOption(TaskSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void setFilterCategory(String? category) {
    _filterCategory = category;
    notifyListeners();
  }

  void clearFilter() {
    _filterCategory = null;
    notifyListeners();
  }

  /// Clears all data — call this when a user signs out
  void clear() {
    _tasks.clear();
    _sortOption = TaskSortOption.createdDate;
    _filterCategory = null;
    notifyListeners();
  }

}
