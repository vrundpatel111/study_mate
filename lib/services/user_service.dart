import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studymate/models/user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Create user document in Firestore when registering
  Future<AppUser> createUser({
    required String email,
    required String displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      final now = DateTime.now();
      final appUser = AppUser(
        id: user.uid,
        email: email,
        displayName: displayName,
        photoURL: photoURL,
        createdAt: now,
        updatedAt: now,
        preferences: {
          'theme': 'system',
          'notifications': true,
          'language': 'en',
        },
      );

      // Save to Firestore
      await _usersCollection.doc(user.uid).set(appUser.toJson());
      
      return appUser;
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

  // Get user by ID
  Future<AppUser?> getUserById(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return AppUser.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }

  // Get current authenticated user
  Future<AppUser?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return await getUserById(user.uid);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting current user: $e');
    }
  }

  // Update user profile
  Future<void> updateUser(AppUser appUser) async {
    try {
      final updatedUser = appUser.copyWith(updatedAt: DateTime.now());
      await _usersCollection.doc(appUser.id).update(updatedUser.toJson());
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  // Update user preferences
  Future<void> updateUserPreferences(String userId, Map<String, dynamic> preferences) async {
    try {
      await _usersCollection.doc(userId).update({
        'preferences': preferences,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error updating preferences: $e');
    }
  }

  // Delete user (optional - for account deletion)
  Future<void> deleteUser(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }

  // Check if user document exists
  Future<bool> userExists(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Get all users (admin function)
  Future<List<AppUser>> getAllUsers() async {
    try {
      final snapshot = await _usersCollection.get();
      return snapshot.docs
          .map((doc) => AppUser.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error fetching all users: $e');
    }
  }

  // Stream of current user data
  Stream<AppUser?> get currentUserStream {
    final user = _auth.currentUser;
    if (user != null) {
      return _usersCollection.doc(user.uid).snapshots().map((doc) {
        if (doc.exists) {
          return AppUser.fromJson(doc.data() as Map<String, dynamic>);
        }
        return null;
      });
    }
    return Stream.value(null);
  }
}
