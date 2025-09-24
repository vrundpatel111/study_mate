import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:studymate/models/note_review.dart';
import 'package:studymate/services/auth_service.dart';
import 'package:studymate/services/shared_note_service.dart';
import 'package:uuid/uuid.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final SharedNoteService _sharedNoteService = SharedNoteService();
  final _uuid = Uuid();

  static const String _reviewsCollection = 'note_reviews';
  static const String _likesCollection = 'note_likes';
  static const String _reviewLikesCollection = 'review_likes';

  // Add a review to a shared note
  Future<void> addReview({
    required String noteId,
    required int rating,
    required String comment,
  }) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('User must be logged in to add review');

    final reviewId = _uuid.v4();
    final now = DateTime.now();

    final review = NoteReview(
      id: reviewId,
      noteId: noteId,
      userId: user.uid,
      userName: _authService.userDisplayName,
      userPhotoURL: user.photoURL,
      rating: rating,
      comment: comment,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _firestore
          .collection(_reviewsCollection)
          .doc(reviewId)
          .set(review.toJson());

      // Update note's engagement metrics
      await _updateNoteEngagementMetrics(noteId);
    } catch (e) {
      throw Exception('Failed to add review: ${e.toString()}');
    }
  }

  // Update a review
  Future<void> updateReview({
    required String reviewId,
    int? rating,
    String? comment,
  }) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('User must be logged in');

    try {
      final reviewDoc = await _firestore
          .collection(_reviewsCollection)
          .doc(reviewId)
          .get();

      if (!reviewDoc.exists) throw Exception('Review not found');

      final review = NoteReview.fromJson(reviewDoc.data()!);
      if (!review.isOwner(user.uid)) {
        throw Exception('Only the review author can update this review');
      }

      final updatedReview = review.copyWith(
        rating: rating,
        comment: comment,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_reviewsCollection)
          .doc(reviewId)
          .update(updatedReview.toJson());

      // Update note's engagement metrics
      await _updateNoteEngagementMetrics(review.noteId);
    } catch (e) {
      throw Exception('Failed to update review: ${e.toString()}');
    }
  }

  // Delete a review
  Future<void> deleteReview(String reviewId) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('User must be logged in');

    try {
      final reviewDoc = await _firestore
          .collection(_reviewsCollection)
          .doc(reviewId)
          .get();

      if (!reviewDoc.exists) throw Exception('Review not found');

      final review = NoteReview.fromJson(reviewDoc.data()!);
      if (!review.isOwner(user.uid)) {
        throw Exception('Only the review author can delete this review');
      }

      await _firestore
          .collection(_reviewsCollection)
          .doc(reviewId)
          .delete();

      // Delete all likes on this review
      final reviewLikes = await _firestore
          .collection(_reviewLikesCollection)
          .where('reviewId', isEqualTo: reviewId)
          .get();

      for (final doc in reviewLikes.docs) {
        await doc.reference.delete();
      }

      // Update note's engagement metrics
      await _updateNoteEngagementMetrics(review.noteId);
    } catch (e) {
      throw Exception('Failed to delete review: ${e.toString()}');
    }
  }

  // Get reviews for a note
  Stream<List<NoteReview>> getReviewsForNoteStream(String noteId, {int limit = 20}) {
    return _firestore
        .collection(_reviewsCollection)
        .where('noteId', isEqualTo: noteId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return NoteReview.fromJson(doc.data());
      }).toList();
    });
  }

  // Check if user has already reviewed this note
  Future<NoteReview?> getUserReviewForNote(String noteId) async {
    final user = _authService.currentUser;
    if (user == null) return null;

    try {
      final snapshot = await _firestore
          .collection(_reviewsCollection)
          .where('noteId', isEqualTo: noteId)
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return NoteReview.fromJson(snapshot.docs.first.data());
    } catch (e) {
      print('Failed to get user review: ${e.toString()}');
      return null;
    }
  }

  // Like a note
  Future<void> likeNote(String noteId) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('User must be logged in to like notes');

    final likeId = _uuid.v4();

    final like = NoteLike(
      id: likeId,
      noteId: noteId,
      userId: user.uid,
      userName: _authService.userDisplayName,
      createdAt: DateTime.now(),
    );

    try {
      await _firestore
          .collection(_likesCollection)
          .doc(likeId)
          .set(like.toJson());

      // Update note's like count
      await _updateNoteEngagementMetrics(noteId);
    } catch (e) {
      throw Exception('Failed to like note: ${e.toString()}');
    }
  }

  // Unlike a note
  Future<void> unlikeNote(String noteId) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('User must be logged in');

    try {
      final likeSnapshot = await _firestore
          .collection(_likesCollection)
          .where('noteId', isEqualTo: noteId)
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (likeSnapshot.docs.isNotEmpty) {
        await likeSnapshot.docs.first.reference.delete();

        // Update note's like count
        await _updateNoteEngagementMetrics(noteId);
      }
    } catch (e) {
      throw Exception('Failed to unlike note: ${e.toString()}');
    }
  }

  // Check if user has liked this note
  Future<bool> hasUserLikedNote(String noteId) async {
    final user = _authService.currentUser;
    if (user == null) return false;

    try {
      final likeSnapshot = await _firestore
          .collection(_likesCollection)
          .where('noteId', isEqualTo: noteId)
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      return likeSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Failed to check if user liked note: ${e.toString()}');
      return false;
    }
  }

  // Get likes for a note
  Stream<List<NoteLike>> getLikesForNoteStream(String noteId) {
    return _firestore
        .collection(_likesCollection)
        .where('noteId', isEqualTo: noteId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return NoteLike.fromJson(doc.data());
      }).toList();
    });
  }

  // Like a review
  Future<void> likeReview(String reviewId) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('User must be logged in to like reviews');

    final likeId = _uuid.v4();

    final reviewLike = ReviewLike(
      id: likeId,
      reviewId: reviewId,
      userId: user.uid,
      userName: _authService.userDisplayName,
      createdAt: DateTime.now(),
    );

    try {
      await _firestore
          .collection(_reviewLikesCollection)
          .doc(likeId)
          .set(reviewLike.toJson());

      // Update review's like count
      await _updateReviewLikeCount(reviewId);
    } catch (e) {
      throw Exception('Failed to like review: ${e.toString()}');
    }
  }

  // Unlike a review
  Future<void> unlikeReview(String reviewId) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('User must be logged in');

    try {
      final likeSnapshot = await _firestore
          .collection(_reviewLikesCollection)
          .where('reviewId', isEqualTo: reviewId)
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (likeSnapshot.docs.isNotEmpty) {
        await likeSnapshot.docs.first.reference.delete();

        // Update review's like count
        await _updateReviewLikeCount(reviewId);
      }
    } catch (e) {
      throw Exception('Failed to unlike review: ${e.toString()}');
    }
  }

  // Check if user has liked this review
  Future<bool> hasUserLikedReview(String reviewId) async {
    final user = _authService.currentUser;
    if (user == null) return false;

    try {
      final likeSnapshot = await _firestore
          .collection(_reviewLikesCollection)
          .where('reviewId', isEqualTo: reviewId)
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      return likeSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Failed to check if user liked review: ${e.toString()}');
      return false;
    }
  }

  // Get review statistics for a note
  Future<Map<String, dynamic>> getReviewStats(String noteId) async {
    try {
      final reviewsSnapshot = await _firestore
          .collection(_reviewsCollection)
          .where('noteId', isEqualTo: noteId)
          .get();

      final reviews = reviewsSnapshot.docs.map((doc) {
        return NoteReview.fromJson(doc.data());
      }).toList();

      if (reviews.isEmpty) {
        return {
          'count': 0,
          'averageRating': 0.0,
          'ratingDistribution': [0, 0, 0, 0, 0], // 1-5 stars
        };
      }

      final totalRating = reviews.fold(0, (sum, review) => sum + review.rating);
      final averageRating = totalRating / reviews.length;

      final ratingDistribution = [0, 0, 0, 0, 0];
      for (final review in reviews) {
        ratingDistribution[review.rating - 1]++;
      }

      return {
        'count': reviews.length,
        'averageRating': averageRating,
        'ratingDistribution': ratingDistribution,
      };
    } catch (e) {
      throw Exception('Failed to get review stats: ${e.toString()}');
    }
  }

  // Get like count for a note
  Future<int> getLikeCount(String noteId) async {
    try {
      final likesSnapshot = await _firestore
          .collection(_likesCollection)
          .where('noteId', isEqualTo: noteId)
          .get();

      return likesSnapshot.docs.length;
    } catch (e) {
      print('Failed to get like count: ${e.toString()}');
      return 0;
    }
  }

  // Update note's engagement metrics
  Future<void> _updateNoteEngagementMetrics(String noteId) async {
    try {
      final reviewStats = await getReviewStats(noteId);
      final likeCount = await getLikeCount(noteId);

      await _sharedNoteService.updateEngagementMetrics(
        noteId,
        likesCount: likeCount,
        reviewsCount: reviewStats['count'],
        averageRating: reviewStats['averageRating'],
      );
    } catch (e) {
      print('Failed to update note engagement metrics: ${e.toString()}');
    }
  }

  // Update review's like count
  Future<void> _updateReviewLikeCount(String reviewId) async {
    try {
      final likesSnapshot = await _firestore
          .collection(_reviewLikesCollection)
          .where('reviewId', isEqualTo: reviewId)
          .get();

      final likeCount = likesSnapshot.docs.length;

      await _firestore
          .collection(_reviewsCollection)
          .doc(reviewId)
          .update({'likesCount': likeCount});
    } catch (e) {
      print('Failed to update review like count: ${e.toString()}');
    }
  }

  // Get user's reviews
  Stream<List<NoteReview>> getUserReviewsStream() {
    final user = _authService.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection(_reviewsCollection)
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return NoteReview.fromJson(doc.data());
      }).toList();
    });
  }

  // Get user's liked notes
  Stream<List<NoteLike>> getUserLikesStream() {
    final user = _authService.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection(_likesCollection)
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return NoteLike.fromJson(doc.data());
      }).toList();
    });
  }
}
