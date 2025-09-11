import 'package:flutter/material.dart';
import 'package:studymate/models/task.dart';
import 'package:studymate/services/task_service.dart';
import 'package:intl/intl.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({Key? key, required this.task}) : super(key: key);

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task _task;
  final TaskService _taskService = TaskService();
  bool _isEditing = false;
  bool _isLoading = false;
  
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subjectController = TextEditingController();
  final _tagsController = TextEditingController();
  
  TaskPriority _selectedPriority = TaskPriority.medium;
  DateTime _selectedDueDate = DateTime.now().add(Duration(days: 1));
  bool _hasReminder = false;
  DateTime? _reminderDateTime;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _initializeForm();
  }

  void _initializeForm() {
    _titleController.text = _task.title;
    _descriptionController.text = _task.description;
    _subjectController.text = _task.subject;
    _tagsController.text = _task.tags.join(', ');
    _selectedPriority = _task.priority;
    _selectedDueDate = _task.dueDate;
    _hasReminder = _task.hasReminder;
    _reminderDateTime = _task.reminderTime;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subjectController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _toggleCompletion() async {
    setState(() => _isLoading = true);
    
    try {
      final updatedTask = _task.copyWith(
        isCompleted: !_task.isCompleted,
        completedAt: !_task.isCompleted ? DateTime.now() : null,
      );
      
      await _taskService.updateTask(updatedTask);
      
      setState(() {
        _task = updatedTask;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_task.isCompleted ? 'Task completed!' : 'Task marked as pending'),
          backgroundColor: _task.isCompleted ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating task: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedTask = _task.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        subject: _subjectController.text.trim(),
        priority: _selectedPriority,
        dueDate: _selectedDueDate,
        tags: _tagsController.text.isEmpty
            ? []
            : _tagsController.text.split(',').map((e) => e.trim()).toList(),
        hasReminder: _hasReminder,
        reminderTime: _hasReminder ? _reminderDateTime : null,
      );

      await _taskService.updateTask(updatedTask);
      
      setState(() {
        _task = updatedTask;
        _isEditing = false;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating task: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Task'),
        content: Text('Are you sure you want to delete "${_task.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      
      try {
        await _taskService.deleteTask(_task.id);
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting task: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _selectDueDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDueDate),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = _task.isOverdue;
    final daysUntilDue = _task.daysUntilDue;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'Task Details'),
        elevation: 0,
        actions: [
          if (!_isEditing) ...[
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: Icon(Icons.edit),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Task'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteTask();
                }
              },
            ),
          ] else ...[
            TextButton(
              onPressed: () => setState(() {
                _isEditing = false;
                _initializeForm();
              }),
              child: Text('CANCEL', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: _isLoading ? null : _saveChanges,
              child: Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task Status Card
              Card(
                elevation: 3,
                color: _task.isCompleted ? Colors.green.shade50 : Colors.orange.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _task.isCompleted ? Icons.check_circle : Icons.pending,
                        color: _task.isCompleted ? Colors.green : Colors.orange,
                        size: 32,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _task.isCompleted ? 'Completed' : 'Pending',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _task.isCompleted ? Colors.green : Colors.orange,
                              ),
                            ),
                            if (_task.isCompleted && _task.completedAt != null)
                              Text(
                                'Completed on ${DateFormat('MMM dd, yyyy').format(_task.completedAt!)}',
                                style: TextStyle(color: Colors.grey[600]),
                              )
                            else
                              Text(
                                isOverdue
                                    ? '${-daysUntilDue} days overdue'
                                    : daysUntilDue == 0
                                        ? 'Due today'
                                        : 'Due in $daysUntilDue days',
                                style: TextStyle(
                                  color: isOverdue ? Colors.red : Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _toggleCompletion,
                        icon: Icon(_task.isCompleted ? Icons.undo : Icons.check),
                        label: Text(_task.isCompleted ? 'Undo' : 'Complete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _task.isCompleted ? Colors.orange : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Title
              _isEditing
                  ? TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Task Title',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) =>
                          value?.trim().isEmpty == true ? 'Please enter a task title' : null,
                    )
                  : Card(
                      child: ListTile(
                        leading: Icon(Icons.title, color: Colors.indigo),
                        title: Text('Title'),
                        subtitle: Text(
                          _task.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            decoration: _task.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ),
              SizedBox(height: 16),

              // Description
              _isEditing
                  ? TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      maxLines: 3,
                    )
                  : Card(
                      child: ListTile(
                        leading: Icon(Icons.description, color: Colors.indigo),
                        title: Text('Description'),
                        subtitle: Text(
                          _task.description.isEmpty ? 'No description' : _task.description,
                          style: TextStyle(
                            color: _task.description.isEmpty ? Colors.grey : null,
                          ),
                        ),
                      ),
                    ),
              SizedBox(height: 16),

              // Subject and Priority Row
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: ListTile(
                        leading: Icon(Icons.school, color: Colors.indigo),
                        title: Text('Subject'),
                        subtitle: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _task.subject,
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      child: ListTile(
                        leading: Icon(Icons.priority_high, color: Colors.indigo),
                        title: Text('Priority'),
                        subtitle: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _task.priorityColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _task.priorityText,
                            style: TextStyle(
                              color: _task.priorityColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Due Date
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.schedule,
                    color: isOverdue ? Colors.red : Colors.indigo,
                  ),
                  title: Text('Due Date'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, MMM dd, yyyy - HH:mm').format(_task.dueDate),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isOverdue ? Colors.red : null,
                        ),
                      ),
                      Text(
                        isOverdue
                            ? '${-daysUntilDue} days overdue'
                            : daysUntilDue == 0
                                ? 'Due today'
                                : daysUntilDue == 1
                                    ? 'Due tomorrow'
                                    : 'Due in $daysUntilDue days',
                        style: TextStyle(
                          color: isOverdue ? Colors.red : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Reminder
              Card(
                child: ListTile(
                  leading: Icon(
                    _task.hasReminder ? Icons.notification_add : Icons.notifications_off,
                    color: _task.hasReminder ? Colors.indigo : Colors.grey,
                  ),
                  title: Text('Reminder'),
                  subtitle: _task.hasReminder && _task.reminderTime != null
                      ? Text(DateFormat('MMM dd, yyyy - HH:mm').format(_task.reminderTime!))
                      : Text('No reminder set', style: TextStyle(color: Colors.grey)),
                ),
              ),
              SizedBox(height: 16),

              // Tags
              if (_task.tags.isNotEmpty)
                Card(
                  child: ListTile(
                    leading: Icon(Icons.label, color: Colors.indigo),
                    title: Text('Tags'),
                    subtitle: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _task.tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          backgroundColor: Colors.indigo.withOpacity(0.1),
                          labelStyle: TextStyle(color: Colors.indigo),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              SizedBox(height: 16),

              // Timestamps
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.add_circle_outline, color: Colors.indigo),
                      title: Text('Created'),
                      subtitle: Text(DateFormat('MMM dd, yyyy - HH:mm').format(_task.createdAt)),
                    ),
                    if (_task.isCompleted && _task.completedAt != null) ...[
                      Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.check_circle_outline, color: Colors.green),
                        title: Text('Completed'),
                        subtitle: Text(DateFormat('MMM dd, yyyy - HH:mm').format(_task.completedAt!)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
