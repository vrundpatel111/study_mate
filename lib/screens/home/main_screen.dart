import 'package:flutter/material.dart';
import 'package:studymate/screens/tasks/tasks_screen.dart';
import 'package:studymate/screens/notes/notes_screen.dart';
import 'package:studymate/screens/calendar/calendar_screen.dart';
import 'package:studymate/screens/profile/profile_screen.dart';
import 'package:studymate/services/auth_service.dart';

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
              onPressed: () {
                // TODO: Navigate to notifications screen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Notifications feature coming soon!')),
                );
              },
            ),
          if (_currentIndex == 1) // Tasks
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                // TODO: Navigate to add task screen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Add task feature coming soon!')),
                );
              },
            ),
          if (_currentIndex == 2) // Notes
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                // TODO: Navigate to add note screen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Add note feature coming soon!')),
                );
              },
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
}

// Temporary Dashboard screen
class DashboardScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
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
          Row(
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
                          '0',
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
                          '0',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text('Notes'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
    );
  }
}
