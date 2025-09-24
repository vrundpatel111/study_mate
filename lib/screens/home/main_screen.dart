import 'package:flutter/material.dart';
import 'package:studymate/screens/tasks/tasks_screen.dart';
import 'package:studymate/screens/notes/notes_screen.dart';
import 'package:studymate/screens/calendar/calendar_screen.dart';
import 'package:studymate/screens/profile/profile_screen.dart';
import 'package:studymate/screens/shared_notes/shared_notes_screen.dart';
import 'package:studymate/screens/notes/add_note_screen.dart';
import 'package:studymate/screens/tasks/add_task_screen.dart';
import 'package:studymate/services/auth_service.dart';
import 'package:studymate/services/task_service.dart';
import 'package:studymate/services/note_service.dart';
import 'package:studymate/services/notification_service.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    DashboardScreen(),
    TasksScreen(),
    NotesScreen(),
    CalendarScreen(),
    ProfileScreen(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Tasks',
    'Notes',
    'Calendar',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        elevation: 0,
        actions: [
          if (_currentIndex == 0) // Dashboard
            IconButton(
              icon: Icon(Icons.notifications_outlined),
              onPressed: () => _showNotificationDemo(),
            ),
          if (_currentIndex == 1) // Tasks
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddTaskScreen()),
              ).then((_) => _refreshDashboardIfVisible()),
            ),
          if (_currentIndex == 2) // Notes
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddNoteScreen()),
              ).then((_) => _refreshDashboardIfVisible()),
            ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_outlined),
            activeIcon: Icon(Icons.task),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note_outlined),
            activeIcon: Icon(Icons.note),
            label: 'Notes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _showNotificationDemo() async {
    final notificationService = NotificationService();
    await notificationService.showInstantNotification(
      id: 1,
      title: 'StudyMate Notification',
      body: 'Notifications are working! You can receive reminders for tasks and other updates.',
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notification sent! Check your notification bar.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _refreshDashboardIfVisible() {
    // Refresh dashboard data if currently on dashboard tab
    if (_currentIndex == 0) {
      // Find the dashboard screen in the screens list and refresh it
      final dashboardScreen = _screens[0] as DashboardScreen;
      // Since we can't directly call methods on StatefulWidget, we'll use a key refresh approach
      setState(() {
        _screens[0] = DashboardScreen();
      });
    }
  }
}

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  final TaskService _taskService = TaskService();
  final NoteService _noteService = NoteService();
  
  int _pendingTasksCount = 0;
  int _totalNotesCount = 0;
  int _completedTasksCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final taskStats = _taskService.getCompletionStats();
      final notesStats = _noteService.getNotesStats();
      
      if (mounted) {
        setState(() {
          _pendingTasksCount = taskStats['pending'] ?? 0;
          _completedTasksCount = taskStats['completed'] ?? 0;
          _totalNotesCount = notesStats['total'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${_authService.userDisplayName}!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Ready to organize your studies today?',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Quick stats
            _isLoading 
                ? _buildLoadingStats()
                : _buildStatsCards(),
            SizedBox(height: 16),
            
            // Quick Actions
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionButton(
                            context,
                            'Shared Notes',
                            'Discover and share notes',
                            Icons.share,
                            Colors.purple,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SharedNotesScreen()),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickActionButton(
                            context,
                            'Create Note',
                            'Start writing a new note',
                            Icons.add_circle_outline,
                            Colors.green,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => AddNoteScreen()),
                            ).then((_) => _loadDashboardData()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Recent activities placeholder
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Activities',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No recent activities',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Start by creating your first task or note!',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ],
        ),
      ),
    );
  }

  Widget _buildLoadingStats() {
    return Row(
      children: [
        Expanded(
          child: Card(
            color: Colors.indigo.shade50,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.task, color: Colors.indigo, size: 30),
                  SizedBox(height: 8),
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                  ),
                  SizedBox(height: 8),
                  Text('Pending Tasks'),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.note, color: Colors.green, size: 30),
                  SizedBox(height: 8),
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  SizedBox(height: 8),
                  Text('Total Notes'),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.check_circle, color: Colors.orange, size: 30),
                  SizedBox(height: 8),
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                  SizedBox(height: 8),
                  Text('Completed'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: Card(
            color: Colors.indigo.shade50,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.task, color: Colors.indigo, size: 30),
                  SizedBox(height: 8),
                  Text(
                    '$_pendingTasksCount',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  Text('Pending Tasks'),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.note, color: Colors.green, size: 30),
                  SizedBox(height: 8),
                  Text(
                    '$_totalNotesCount',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text('Total Notes'),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.check_circle, color: Colors.orange, size: 30),
                  SizedBox(height: 8),
                  Text(
                    '$_completedTasksCount',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  Text('Completed'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
