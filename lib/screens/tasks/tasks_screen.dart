import 'package:flutter/material.dart';
import 'package:studymate/models/task.dart';
import 'package:studymate/services/task_service.dart';
import 'package:studymate/screens/tasks/add_task_screen.dart';
import 'package:studymate/screens/tasks/task_detail_screen.dart';

class TasksScreen extends StatefulWidget {
  @override
  _TasksScreenState createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with TickerProviderStateMixin {
  final TaskService _taskService = TaskService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  bool _isLoading = true;
  String _searchQuery = '';
  TaskPriority? _filterPriority;
  String? _filterSubject;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTasks();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = _taskService.getAllTasks();
      setState(() {
        _tasks = tasks;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading tasks: $e')),
      );
    }
  }
  
  void _applyFilters() {
    _filteredTasks = _tasks.where((task) {
      bool matchesSearch = _searchQuery.isEmpty ||
          task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          task.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          task.subject.toLowerCase().contains(_searchQuery.toLowerCase());
      
      bool matchesPriority = _filterPriority == null || task.priority == _filterPriority;
      bool matchesSubject = _filterSubject == null || task.subject == _filterSubject;
      
      return matchesSearch && matchesPriority && matchesSubject;
    }).toList();
    
    // Sort by due date
    _filteredTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }
  
  List<Task> _getTasksByStatus() {
    switch (_tabController.index) {
      case 0: // All
        return _filteredTasks;
      case 1: // Pending
        return _filteredTasks.where((task) => !task.isCompleted).toList();
      case 2: // Completed
        return _filteredTasks.where((task) => task.isCompleted).toList();
      case 3: // Overdue
        return _filteredTasks.where((task) => task.isOverdue).toList();
      default:
        return _filteredTasks;
    }
  }
  
  Future<void> _toggleTaskCompletion(Task task) async {
    try {
      final updatedTask = task.copyWith(
        isCompleted: !task.isCompleted,
        completedAt: !task.isCompleted ? DateTime.now() : null,
      );
      await _taskService.updateTask(updatedTask);
      _loadTasks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating task: $e')),
      );
    }
  }
  
  Future<void> _deleteTask(Task task) async {
    try {
      await _taskService.deleteTask(task.id);
      _loadTasks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting task: $e')),
      );
    }
  }
  
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Tasks'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<TaskPriority?>(
              value: _filterPriority,
              decoration: InputDecoration(labelText: 'Priority'),
              items: [
                DropdownMenuItem(value: null, child: Text('All Priorities')),
                ...TaskPriority.values.map((priority) =>
                  DropdownMenuItem(
                    value: priority,
                    child: Text(priority.toString().split('.').last.toUpperCase()),
                  ),
                ),
              ],
              onChanged: (value) => _filterPriority = value,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              value: _filterSubject,
              decoration: InputDecoration(labelText: 'Subject'),
              items: [
                DropdownMenuItem(value: null, child: Text('All Subjects')),
                ..._getUniqueSubjects().map((subject) =>
                  DropdownMenuItem(value: subject, child: Text(subject)),
                ),
              ],
              onChanged: (value) => _filterSubject = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _applyFilters());
              Navigator.pop(context);
            },
            child: Text('Apply'),
          ),
        ],
      ),
    );
  }
  
  List<String> _getUniqueSubjects() {
    return _tasks.map((task) => task.subject).toSet().toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search tasks...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (query) {
                      setState(() {
                        _searchQuery = query;
                        _applyFilters();
                      });
                    },
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  onPressed: _showFilterDialog,
                  icon: Icon(Icons.filter_list),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: Colors.indigo,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.indigo,
            onTap: (index) => setState(() {}),
            tabs: [
              Tab(text: 'All (${_filteredTasks.length})'),
              Tab(text: 'Pending (${_filteredTasks.where((t) => !t.isCompleted).length})'),
              Tab(text: 'Completed (${_filteredTasks.where((t) => t.isCompleted).length})'),
              Tab(text: 'Overdue (${_filteredTasks.where((t) => t.isOverdue).length})'),
            ],
          ),
          
          // Tasks List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: List.generate(4, (index) {
                      final tasks = _getTasksByStatus();
                      
                      if (tasks.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.task_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No tasks found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap + to create your first task',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return RefreshIndicator(
                        onRefresh: _loadTasks,
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            return TaskCard(
                              task: task,
                              onToggleComplete: () => _toggleTaskCompletion(task),
                              onDelete: () => _showDeleteDialog(task),
                              onTap: () => _navigateToTaskDetail(task),
                            );
                          },
                        ),
                      );
                    }),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddTask(),
        child: Icon(Icons.add),
        backgroundColor: Colors.indigo,
      ),
    );
  }
  
  void _showDeleteDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTask(task);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  void _navigateToAddTask() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddTaskScreen()),
    );
    if (result == true) {
      _loadTasks();
    }
  }
  
  void _navigateToTaskDetail(Task task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(task: task),
      ),
    );
    if (result == true) {
      _loadTasks();
    }
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  
  const TaskCard({
    Key? key,
    required this.task,
    required this.onToggleComplete,
    required this.onDelete,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isOverdue = task.isOverdue;
    final daysUntilDue = task.daysUntilDue;
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: task.isCompleted,
                    onChanged: (value) => onToggleComplete(),
                    activeColor: Colors.indigo,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: task.isCompleted
                                ? Colors.grey[600]
                                : Colors.black87,
                          ),
                        ),
                        if (task.description.isNotEmpty)
                          Text(
                            task.description,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline, color: Colors.red),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: task.priorityColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      task.priorityText,
                      style: TextStyle(
                        color: task.priorityColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      task.subject,
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Spacer(),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: isOverdue ? Colors.red : Colors.grey[600],
                      ),
                      SizedBox(width: 4),
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
