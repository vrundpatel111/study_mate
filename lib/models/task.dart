import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
enum TaskPriority {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
}

@HiveType(typeId: 1)
class Task extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  String subject;

  @HiveField(4)
  TaskPriority priority;

  @HiveField(5)
  DateTime dueDate;

  @HiveField(6)
  bool isCompleted;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime? completedAt;

  @HiveField(9)
  List<String> tags;

  @HiveField(10)
  bool hasReminder;

  @HiveField(11)
  DateTime? reminderTime;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.priority,
    required this.dueDate,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
    this.tags = const [],
    this.hasReminder = false,
    this.reminderTime,
  });

  String get priorityText {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }

  Color get priorityColor {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
    }
  }

  bool get isOverdue {
    return dueDate.isBefore(DateTime.now()) && !isCompleted;
  }

  int get daysUntilDue {
    final now = DateTime.now();
    final difference = dueDate.difference(DateTime(now.year, now.month, now.day));
    return difference.inDays;
  }

  // Create a copy of the task with updated fields
  Task copyWith({
    String? title,
    String? description,
    String? subject,
    TaskPriority? priority,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? completedAt,
    List<String>? tags,
    bool? hasReminder,
    DateTime? reminderTime,
  }) {
    return Task(
      id: this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      tags: tags ?? this.tags,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }
}