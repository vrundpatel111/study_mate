import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:studymate/models/note.dart';
import 'package:studymate/models/shared_note.dart';
import 'package:studymate/services/auth_service.dart';
import 'package:uuid/uuid.dart';

class SharedNoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final _uuid = Uuid();

  static const String _sharedNotesCollection = 'shared_notes';
  static const String _userInteractionsCollection = 'user_interactions';

  // Share a local note to the public collection
  Future<String> shareNote(Note localNote, {bool isPublic = true}) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('User must be logged in to share notes');

    final sharedNoteId = _uuid.v4();
    final now = DateTime.now();

    final sharedNote = SharedNote(
      id: sharedNoteId,
      title: localNote.title,
      content: localNote.content,
      subject: localNote.subject,
      authorId: user.uid,
      authorName: _authService.userDisplayName,
      authorPhotoURL: user.photoURL,
      createdAt: localNote.createdAt,
      updatedAt: localNote.updatedAt,
      sharedAt: now,
      tags: localNote.tags,
      category: localNote.category,
      isPublic: isPublic,
      imagePath: localNote.imagePath,
    );

    try {
      await _firestore
          .collection(_sharedNotesCollection)
          .doc(sharedNoteId)
          .set(sharedNote.toJson());

      return sharedNoteId;
    } catch (e) {
      throw Exception('Failed to share note: ${e.toString()}');
    }
  }

  // Update a shared note
  Future<void> updateSharedNote(SharedNote note) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('User must be logged in');
    if (!note.isAuthor(user.uid)) throw Exception('Only the author can update this note');

    try {
      await _firestore
          .collection(_sharedNotesCollection)
          .doc(note.id)
          .update(note.copyWith(updatedAt: DateTime.now()).toJson());
    } catch (e) {
      throw Exception('Failed to update shared note: ${e.toString()}');
    }
  }

  // Delete a shared note
  Future<void> deleteSharedNote(String noteId) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('User must be logged in');

    try {
      final noteDoc = await _firestore
          .collection(_sharedNotesCollection)
          .doc(noteId)
          .get();

      if (!noteDoc.exists) throw Exception('Note not found');

      final note = SharedNote.fromJson(noteDoc.data()!);
      if (!note.isAuthor(user.uid)) {
        throw Exception('Only the author can delete this note');
      }

      await _firestore
          .collection(_sharedNotesCollection)
          .doc(noteId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete shared note: ${e.toString()}');
    }
  }

  // Get all public shared notes
  Stream<List<SharedNote>> getPublicNotesStream({
    int limit = 20,
    String? orderBy = 'sharedAt',
    bool descending = true,
  }) {
    Query query = _firestore
        .collection(_sharedNotesCollection)
        .where('isPublic', isEqualTo: true)
        .orderBy(orderBy!, descending: descending);

    if (limit > 0) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return SharedNote.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Get shared notes by subject
  Stream<List<SharedNote>> getNotesBySubjectStream(String subject, {int limit = 20}) {
    return _firestore
        .collection(_sharedNotesCollection)
        .where('isPublic', isEqualTo: true)
        .where('subject', isEqualTo: subject)
        .orderBy('sharedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return SharedNote.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Get shared notes by author
  Stream<List<SharedNote>> getNotesByAuthorStream(String authorId, {int limit = 20}) {
    return _firestore
        .collection(_sharedNotesCollection)
        .where('authorId', isEqualTo: authorId)
        .orderBy('sharedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return SharedNote.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Get user's own shared notes
  Stream<List<SharedNote>> getMySharedNotesStream() {
    final user = _authService.currentUser;
    if (user == null) return Stream.value([]);

    return getNotesByAuthorStream(user.uid);
  }

  // Search shared notes
  Future<List<SharedNote>> searchNotes(String query, {int limit = 50}) async {
    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a basic implementation - for production, consider using Algolia or similar
      final snapshot = await _firestore
          .collection(_sharedNotesCollection)
          .where('isPublic', isEqualTo: true)
          .limit(limit)
          .get();

      final allNotes = snapshot.docs.map((doc) {
        return SharedNote.fromJson(doc.data());
      }).toList();

      // Filter notes that match the search query
      return allNotes.where((note) => note.matchesSearch(query)).toList();
    } catch (e) {
      throw Exception('Failed to search notes: ${e.toString()}');
    }
  }

  // Get trending notes (based on popularity score)
  Future<List<SharedNote>> getTrendingNotes({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(_sharedNotesCollection)
          .where('isPublic', isEqualTo: true)
          .orderBy('likesCount', descending: true)
          .limit(limit * 2) // Get more to calculate popularity
          .get();

      final notes = snapshot.docs.map((doc) {
        return SharedNote.fromJson(doc.data());
      }).toList();

      // Sort by popularity score
      notes.sort((a, b) => b.popularityScore.compareTo(a.popularityScore));
      
      return notes.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to get trending notes: ${e.toString()}');
    }
  }

  // Get a specific shared note by ID
  Future<SharedNote?> getSharedNote(String noteId) async {
    try {
      final doc = await _firestore
          .collection(_sharedNotesCollection)
          .doc(noteId)
          .get();

      if (!doc.exists) return null;

      return SharedNote.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get shared note: ${e.toString()}');
    }
  }

  // Increment view count
  Future<void> incrementViewCount(String noteId) async {
    try {
      await _firestore
          .collection(_sharedNotesCollection)
          .doc(noteId)
          .update({
        'viewsCount': FieldValue.increment(1),
      });
    } catch (e) {
      // Don't throw error for view count - it's not critical
      print('Failed to increment view count: ${e.toString()}');
    }
  }

  // Increment download count
  Future<void> incrementDownloadCount(String noteId) async {
    try {
      await _firestore
          .collection(_sharedNotesCollection)
          .doc(noteId)
          .update({
        'downloadsCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Failed to increment download count: ${e.toString()}');
    }
  }

  // Download/save a shared note to local storage
  Note convertToLocalNote(SharedNote sharedNote, {String? localId}) {
    return Note(
      id: localId ?? _uuid.v4(),
      title: sharedNote.title,
      content: sharedNote.content,
      subject: sharedNote.subject,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: sharedNote.tags,
      category: sharedNote.category,
      imagePath: sharedNote.imagePath,
      isShared: false, // This is a downloaded copy
      sharedNoteId: sharedNote.id,
      sharedAt: null,
    );
  }

  // Get subjects with note counts
  Future<Map<String, int>> getSubjectsWithCounts() async {
    try {
      final snapshot = await _firestore
          .collection(_sharedNotesCollection)
          .where('isPublic', isEqualTo: true)
          .get();

      final subjects = <String, int>{};
      for (final doc in snapshot.docs) {
        final subject = doc.data()['subject'] as String? ?? 'Other';
        subjects[subject] = (subjects[subject] ?? 0) + 1;
      }

      return subjects;
    } catch (e) {
      throw Exception('Failed to get subjects: ${e.toString()}');
    }
  }

  // Get popular tags
  Future<List<String>> getPopularTags({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(_sharedNotesCollection)
          .where('isPublic', isEqualTo: true)
          .get();

      final tagCounts = <String, int>{};
      for (final doc in snapshot.docs) {
        final tags = List<String>.from(doc.data()['tags'] ?? []);
        for (final tag in tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }

      // Sort by count and return top tags
      final sortedTags = tagCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedTags.take(limit).map((e) => e.key).toList();
    } catch (e) {
      throw Exception('Failed to get popular tags: ${e.toString()}');
    }
  }

  // Update engagement metrics (to be called by review/like services)
  Future<void> updateEngagementMetrics(
    String noteId, {
    int? likesCount,
    int? reviewsCount,
    double? averageRating,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (likesCount != null) updateData['likesCount'] = likesCount;
      if (reviewsCount != null) updateData['reviewsCount'] = reviewsCount;
      if (averageRating != null) updateData['averageRating'] = averageRating;

      if (updateData.isNotEmpty) {
        await _firestore
            .collection(_sharedNotesCollection)
            .doc(noteId)
            .update(updateData);
      }
    } catch (e) {
      print('Failed to update engagement metrics: ${e.toString()}');
    }
  }
}
