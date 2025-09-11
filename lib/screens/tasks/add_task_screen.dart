import 'package:flutter/material.dart';
import 'package:studymate/models/task.dart';
import 'package:studymate/services/task_service.dart';
import 'package:intl/intl.dart';

class AddTaskScreen extends StatefulWidget {
  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subjectController = TextEditingController();
  final _tagsController = TextEditingController();
  final TaskService _taskService = TaskService();
  
  TaskPriority _selectedPriority = TaskPriority.medium;
  DateTime _selectedDueDate = DateTime.now().add(Duration(days: 1));
  TimeOfDay _selectedDueTime = TimeOfDay(hour: 23, minute: 59);
  bool _hasReminder = false;
  DateTime? _reminderDateTime;
  bool _isLoading = false;
  
  final List<String> _commonSubjects = [
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'Computer Science',
    'History',
    'Geography',
    'Literature',
    'Psychology',
    'Economics',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subjectController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.indigo),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: _selectedDueTime,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(primary: Colors.indigo),
            ),
            child: child!,
          );
        },
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
          _selectedDueTime = pickedTime;
        });
      }
    }
  }

  Future<void> _selectReminderDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _reminderDateTime?.subtract(Duration(hours: 1)) ?? 
                  _selectedDueDate.subtract(Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: _selectedDueDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.indigo),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _reminderDateTime ?? _selectedDueDate.subtract(Duration(hours: 1))
        ),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(primary: Colors.indigo),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _reminderDateTime = DateTime(
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

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final task = _taskService.createTask(
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

      await _taskService.addTask(task);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Task'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveTask,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'SAVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Task Title *',
                  hintText: 'Enter task title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.indigo, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Please enter a task title';
                  }
                  return null;
                },
                maxLength: 100,
              ),
              SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter task description (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.indigo, width: 2),
                  ),
                ),
                maxLines: 3,
                maxLength: 500,
              ),
              SizedBox(height: 16),

              // Subject
              DropdownButtonFormField<String>(
                value: _subjectController.text.isEmpty ? null : _subjectController.text,
                decoration: InputDecoration(
                  labelText: 'Subject *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.indigo, width: 2),
                  ),
                ),
                items: _commonSubjects.map((subject) {
                  return DropdownMenuItem(
                    value: subject,
                    child: Text(subject),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _subjectController.text = value;
                  }
                },
                validator: (value) {
                  if (_subjectController.text.trim().isEmpty) {
                    return 'Please select or enter a subject';
                  }
                  return null;
                },
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'Custom Subject',
                  hintText: 'Or enter custom subject',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.indigo, width: 2),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Priority
              Text(
                'Priority *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: TaskPriority.values.map((priority) {
                  Color color;
                  switch (priority) {
                    case TaskPriority.low:
                      color = Colors.green;
                      break;
                    case TaskPriority.medium:
                      color = Colors.orange;
                      break;
                    case TaskPriority.high:
                      color = Colors.red;
                      break;
                  }

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: priority != TaskPriority.high ? 8 : 0),
                      child: ChoiceChip(
                        label: Text(
                          priority.toString().split('.').last.toUpperCase(),
                          style: TextStyle(
                            color: _selectedPriority == priority ? Colors.white : color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        selected: _selectedPriority == priority,
                        selectedColor: color,
                        backgroundColor: color.withOpacity(0.2),
                        onSelected: (selected) {
                          setState(() => _selectedPriority = priority);
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 16),

              // Due Date
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(Icons.calendar_today, color: Colors.indigo),
                  title: Text('Due Date & Time'),
                  subtitle: Text(DateFormat('MMM dd, yyyy - HH:mm').format(_selectedDueDate)),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: _selectDueDate,
                ),
              ),
              SizedBox(height: 16),

              // Reminder
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    SwitchListTile(
                      value: _hasReminder,
                      onChanged: (value) {
                        setState(() {
                          _hasReminder = value;
                          if (value && _reminderDateTime == null) {
                            _reminderDateTime = _selectedDueDate.subtract(Duration(hours: 1));
                          }
                        });
                      },
                      title: Text('Set Reminder'),
                      subtitle: Text('Get notified before due date'),
                      secondary: Icon(Icons.notification_add, color: Colors.indigo),
                      activeColor: Colors.indigo,
                    ),
                    if (_hasReminder) ...[
                      Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.access_time, color: Colors.indigo),
                        title: Text('Reminder Time'),
                        subtitle: _reminderDateTime != null
                            ? Text(DateFormat('MMM dd, yyyy - HH:mm').format(_reminderDateTime!))
                            : Text('Tap to set reminder time'),
                        trailing: Icon(Icons.arrow_forward_ios),
                        onTap: _selectReminderDateTime,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Tags
              TextFormField(
                controller: _tagsController,
                decoration: InputDecoration(
                  labelText: 'Tags',
                  hintText: 'Enter tags separated by commas (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.indigo, width: 2),
                  ),
                  helperText: 'Example: homework, urgent, study',
                ),
              ),
              SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save),
                            SizedBox(width: 8),
                            Text(
                              'Create Task',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
