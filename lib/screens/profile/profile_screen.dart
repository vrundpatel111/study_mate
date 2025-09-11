import 'package:flutter/material.dart';
import 'package:studymate/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sign Out'),
          content: Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Sign Out', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _signOut();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile header
            Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.indigo.shade100,
                      child: Text(
                        _authService.userDisplayName.isNotEmpty
                            ? _authService.userDisplayName[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      _authService.userDisplayName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Profile options
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.person_outline, color: Colors.indigo),
                    title: Text('Edit Profile'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Edit profile feature coming soon!')),
                      );
                    },
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.notifications_outlined, color: Colors.indigo),
                    title: Text('Notifications'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Notification settings coming soon!')),
                      );
                    },
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.security_outlined, color: Colors.indigo),
                    title: Text('Privacy & Security'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Privacy settings coming soon!')),
                      );
                    },
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.backup_outlined, color: Colors.indigo),
                    title: Text('Data & Storage'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Data settings coming soon!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            
            // App info
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.help_outline, color: Colors.indigo),
                    title: Text('Help & Support'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Help section coming soon!')),
                      );
                    },
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.info_outline, color: Colors.indigo),
                    title: Text('About StudyMate'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'StudyMate',
                        applicationVersion: '1.0.0',
                        applicationIcon: Icon(Icons.school, color: Colors.indigo),
                        children: [
                          Text('A collaborative study organizer app for college students to manage tasks, plan study routines, and share notes.'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            
            // Sign out button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showSignOutDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text(
                      'Sign Out',
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
    );
  }
}
