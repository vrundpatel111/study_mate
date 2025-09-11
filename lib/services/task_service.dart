import 'package:hive/hive.dart';
import 'package:studymate/models/task.dart';
import 'package:studymate/services/notification_service.dart';
import 'package:uuid/uuid.dart';

class TaskService {
  static const String _boxName = 'tasks';
  final _uuid = Uuid();
  final _notificationService = NotificationService();

  Box<Task> get _box => Hive.box<Task>(_boxName);

  // Get all tasks sorted by due date
  List<Task> getAllTasks() {
    return _box.values.toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  // Get tasks by subject
  List<Task> getTasksBySubject(String subject) {
    return _box.values
        .where((task) => task.subject.toLowerCase() == subject.toLowerCase())
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  // Get tasks by priority
  List<Task> getTasksByPriority(TaskPriority priority) {
    return _box.values
        .where((task) => task.priority == priority)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  // Get completed tasks
  List<Task> getCompletedTasks() {
    return _box.values
        .where((task) => task.isCompleted)
        .toList()
      ..sort((a, b) => (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt));
  }

  // Get pending tasks
  List<Task> getPendingTasks() {
    return _box.values
        .where((task) => !task.isCompleted)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  // Get overdue tasks
  List<Task> getOverdueTasks() {
    final now = DateTime.now();
    return _box.values
        .where((task) => !task.isCompleted && task.dueDate.isBefore(now))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  // Get tasks for today
  List<Task> getTodayTasks() {
    final today = DateTime.now();
    return _box.values.where((task) {
      return task.dueDate.year == today.year &&
          task.dueDate.month == today.month &&
          task.dueDate.day == today.day;
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  // Get tasks for this week
  List<Task> getThisWeekTasks() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(Duration(days: 6));
    
    return _box.values.where((task) {
      return task.dueDate.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
          task.dueDate.isBefore(endOfWeek.add(Duration(days: 1)));
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  // Get tasks for a specific date
  List<Task> getTasksForDate(DateTime date) {
    return _box.values.where((task) {
      return task.dueDate.year == date.year &&
          task.dueDate.month == date.month &&
          task.dueDate.day == date.day;
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  // Search tasks
  List<Task> searchTasks(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _box.values.where((task) {
      return task.title.toLowerCase().contains(lowercaseQuery) ||
          task.description.toLowerCase().contains(lowercaseQuery) ||
          task.subject.toLowerCase().contains(lowercaseQuery) ||
          task.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  // Add task
  Future<void> addTask(Task task) async {
    await _box.put(task.id, task);
    
    // Schedule notification if reminder is set
    if (task.hasReminder && task.reminderTime != null) {
      await _scheduleTaskNotification(task);
    }
  }

  // Update task
  Future<void> updateTask(Task task) async {
    await _box.put(task.id, task);
    
    // Update notification
    await _notificationService.cancelNotification(task.id.hashCode);
    if (task.hasReminder && task.reminderTime != null && !task.isCompleted) {
      await _scheduleTaskNotification(task);
    }
  }

  // Delete task
  Future<void> deleteTask(String taskId) async {
    await _box.delete(taskId);
    await _notificationService.cancelNotification(taskId.hashCode);
  }

  // Toggle task completion
  Future<void> toggleTaskCompletion(String taskId) async {
    final task = _box.get(taskId);
    if (task != null) {
      task.isCompleted = !task.isCompleted;
      task.completedAt = task.isCompleted ? DateTime.now() : null;
      await _box.put(taskId, task);
      
      // Cancel notification if task is completed
      if (task.isCompleted) {
        await _notificationService.cancelNotification(taskId.hashCode);
      } else if (task.hasReminder && task.reminderTime != null) {
        await _scheduleTaskNotification(task);
      }
    }
  }

  // Get unique subjects
  List<String> getUniqueSubjects() {
    final subjects = _box.values.map((task) => task.subject).toSet().toList();
    subjects.sort();
    return subjects;
  }

  // Get completion statistics
  Map<String, dynamic> getCompletionStats() {
    final allTasks = getAllTasks();
    final completedTasks = getCompletedTasks();
    final overdueTasks = getOverdueTasks();
    
    return {
      'total': allTasks.length,
      'completed': completedTasks.length,
      'pending': allTasks.length - completedTasks.length,
      'overdue': overdueTasks.length,
      'completionRate': allTasks.isNotEmpty 
          ? (completedTasks.length / allTasks.length * 100).round() 
          : 0,
    };
  }

  // Schedule task notification
  Future<void> _scheduleTaskNotification(Task task) async {
    if (task.reminderTime != null && task.reminderTime!.isAfter(DateTime.now())) {
      await _notificationService.scheduleTaskReminder(
        id: task.id.hashCode,
        title: 'Task Reminder: ${task.title}',
        body: 'Due: ${task.dueDate.toString().split(' ')[0]}',
        scheduledTime: task.reminderTime!,
      );
    }
  }

  // Create a new task with generated ID
  Task createTask({
    required String title,
    required String description,
    required String subject,
    required TaskPriority priority,
    required DateTime dueDate,
    List<String> tags = const [],
    bool hasReminder = false,
    DateTime? reminderTime,
  }) {
    return Task(
      id: _uuid.v4(),
      title: title,
      description: description,
      subject: subject,
      priority: priority,
      dueDate: dueDate,
      createdAt: DateTime.now(),
      tags: tags,
      hasReminder: hasReminder,
      reminderTime: reminderTime,
    );
  }
}