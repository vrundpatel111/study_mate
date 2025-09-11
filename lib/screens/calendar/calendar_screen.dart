import 'package:flutter/material.dart';
import 'package:studymate/models/task.dart';
import 'package:studymate/services/task_service.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final TaskService _taskService = TaskService();
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  List<Task> _tasksForSelectedDate = [];
  
  @override
  void initState() {
    super.initState();
    _loadTasksForDate(_selectedDate);
  }
  
  void _loadTasksForDate(DateTime date) {
    final tasks = _taskService.getTasksForDate(date);
    setState(() {
      _tasksForSelectedDate = tasks;
    });
  }
  
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDate = selectedDay;
      _focusedDate = focusedDay;
    });
    _loadTasksForDate(selectedDay);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Month navigation
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _focusedDate = DateTime(
                        _focusedDate.year,
                        _focusedDate.month - 1,
                        _focusedDate.day,
                      );
                    });
                  },
                  icon: Icon(Icons.chevron_left),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_focusedDate),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _focusedDate = DateTime(
                        _focusedDate.year,
                        _focusedDate.month + 1,
                        _focusedDate.day,
                      );
                    });
                  },
                  icon: Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          
          // Calendar Grid
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildCalendarGrid(),
                  
                  // Tasks for selected date
                  Container(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.event, color: Colors.indigo),
                            SizedBox(width: 8),
                            Text(
                              'Tasks for ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        
                        if (_tasksForSelectedDate.isEmpty)
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.event_available,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No tasks for this date',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ..._tasksForSelectedDate.map((task) => _buildTaskCard(task)).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final startingWeekday = firstDayOfMonth.weekday;
    
    final days = <Widget>[];
    
    // Add day headers
    final dayHeaders = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    days.addAll(dayHeaders.map((day) => Container(
      padding: EdgeInsets.all(8),
      child: Text(
        day,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
        textAlign: TextAlign.center,
      ),
    )));
    
    // Add empty cells for days before the first day of the month
    for (int i = 1; i < startingWeekday; i++) {
      days.add(Container());
    }
    
    // Add days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedDate.year, _focusedDate.month, day);
      final isSelected = _selectedDate.year == date.year &&
          _selectedDate.month == date.month &&
          _selectedDate.day == date.day;
      final isToday = DateTime.now().year == date.year &&
          DateTime.now().month == date.month &&
          DateTime.now().day == date.day;
      
      final tasksForDay = _taskService.getTasksForDate(date);
      final hasOverdueTasks = tasksForDay.any((task) => task.isOverdue);
      
      days.add(
        GestureDetector(
          onTap: () => _onDaySelected(date, date),
          child: Container(
            margin: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.indigo
                  : isToday
                      ? Colors.indigo.shade100
                      : null,
              borderRadius: BorderRadius.circular(8),
              border: hasOverdueTasks
                  ? Border.all(color: Colors.red, width: 2)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : isToday
                            ? Colors.indigo
                            : Colors.black,
                  ),
                ),
                if (tasksForDay.isNotEmpty)
                  Container(
                    width: 6,
                    height: 6,
                    margin: EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: hasOverdueTasks
                          ? Colors.red
                          : isSelected
                              ? Colors.white
                              : Colors.indigo,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Container(
      padding: EdgeInsets.all(16),
      child: GridView.count(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        crossAxisCount: 7,
        childAspectRatio: 1,
        children: days,
      ),
    );
  }
  
  Widget _buildTaskCard(Task task) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 4,
          height: double.infinity,
          decoration: BoxDecoration(
            color: task.priorityColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.subject),
            Text(
              DateFormat('HH:mm').format(task.dueDate),
              style: TextStyle(
                color: task.isOverdue ? Colors.red : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: task.priorityColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                task.priorityText,
                style: TextStyle(
                  color: task.priorityColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 8),
            Icon(
              task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
              color: task.isCompleted ? Colors.green : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
