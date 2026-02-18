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

  TaskProvider () {
    _initializeDummyData();
  }

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
    required String category,
    required DateTime deadline,
  }) {
    final task = Task(
      id: _uuid.v4(),
      title: title,
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

  // Initialize dummy data
  void _initializeDummyData() {
    final now = DateTime.now();
    
    _tasks.addAll([
      Task(
        id: _uuid.v4(),
        title: 'Complete Flutter assignment',
        category: '🎓 College',
        deadline: now.add(const Duration(days: 2)),
        isCompleted: false,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      Task(
        id: _uuid.v4(),
        title: 'Buy groceries',
        category: '🛒 Shopping',
        deadline: now.add(const Duration(days: 1)),
        isCompleted: false,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Task(
        id: _uuid.v4(),
        title: 'Prepare presentation slides',
        category: '💼 Work',
        deadline: now.add(const Duration(days: 5)),
        isCompleted: false,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Task(
        id: _uuid.v4(),
        title: 'Call dentist for appointment',
        category: '🏠 Personal',
        deadline: now.add(const Duration(days: 3)),
        isCompleted: true,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      Task(
        id: _uuid.v4(),
        title: 'Study for midterm exam',
        category: '🎓 College',
        deadline: now.add(const Duration(days: 7)),
        isCompleted: false,
        createdAt: now.subtract(const Duration(hours: 12)),
      ),
      Task(
        id: _uuid.v4(),
        title: 'Pick up dry cleaning',
        category: '🏠 Personal',
        deadline: now.add(const Duration(days: 1)),
        isCompleted: true,
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      Task(
        id: _uuid.v4(),
        title: 'Review project proposal',
        category: '💼 Work',
        deadline: now.add(const Duration(days: 4)),
        isCompleted: false,
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
    ]);
  }
}
