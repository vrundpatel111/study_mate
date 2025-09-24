class NoteReview {
  final String id;
  final String noteId;
  final String userId;
  final String userName;
  final String? userPhotoURL;
  final int rating; // 1-5 star rating
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likesCount; // Reviews can also be liked
  final Map<String, dynamic>? metadata;

  NoteReview({
    required this.id,
    required this.noteId,
    required this.userId,
    required this.userName,
    this.userPhotoURL,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.likesCount = 0,
    this.metadata,
  }) : assert(rating >= 1 && rating <= 5, 'Rating must be between 1 and 5');

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'noteId': noteId,
      'userId': userId,
      'userName': userName,
      'userPhotoURL': userPhotoURL,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'likesCount': likesCount,
      'metadata': metadata ?? {},
    };
  }

  // Create NoteReview from Firestore document
  factory NoteReview.fromJson(Map<String, dynamic> json) {
    return NoteReview(
      id: json['id'] ?? '',
      noteId: json['noteId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userPhotoURL: json['userPhotoURL'],
      rating: json['rating'] ?? 1,
      comment: json['comment'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      likesCount: json['likesCount'] ?? 0,
      metadata: json['metadata'] ?? {},
    );
  }

  // Create a copy with updated fields
  NoteReview copyWith({
    String? userName,
    String? userPhotoURL,
    int? rating,
    String? comment,
    DateTime? updatedAt,
    int? likesCount,
    Map<String, dynamic>? metadata,
  }) {
    return NoteReview(
      id: this.id,
      noteId: this.noteId,
      userId: this.userId,
      userName: userName ?? this.userName,
      userPhotoURL: userPhotoURL ?? this.userPhotoURL,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likesCount: likesCount ?? this.likesCount,
      metadata: metadata ?? this.metadata,
    );
  }

  // Check if this review belongs to the current user
  bool isOwner(String currentUserId) {
    return userId == currentUserId;
  }

  // Get star display string
  String get starDisplay {
    return '★' * rating + '☆' * (5 - rating);
  }

  // Get formatted time ago
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}

class NoteLike {
  final String id;
  final String noteId;
  final String userId;
  final String userName;
  final DateTime createdAt;
  final LikeType type; // like or dislike (for future use)

  NoteLike({
    required this.id,
    required this.noteId,
    required this.userId,
    required this.userName,
    required this.createdAt,
    this.type = LikeType.like,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'noteId': noteId,
      'userId': userId,
      'userName': userName,
      'createdAt': createdAt.toIso8601String(),
      'type': type.toString().split('.').last,
    };
  }

  // Create NoteLike from Firestore document
  factory NoteLike.fromJson(Map<String, dynamic> json) {
    return NoteLike(
      id: json['id'] ?? '',
      noteId: json['noteId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      type: _likeTypeFromString(json['type'] ?? 'like'),
    );
  }

  static LikeType _likeTypeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'like':
        return LikeType.like;
      case 'dislike':
        return LikeType.dislike;
      default:
        return LikeType.like;
    }
  }

  // Check if this like belongs to the current user
  bool isOwner(String currentUserId) {
    return userId == currentUserId;
  }
}

enum LikeType {
  like,
  dislike,
}

class ReviewLike {
  final String id;
  final String reviewId;
  final String userId;
  final String userName;
  final DateTime createdAt;

  ReviewLike({
    required this.id,
    required this.reviewId,
    required this.userId,
    required this.userName,
    required this.createdAt,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reviewId': reviewId,
      'userId': userId,
      'userName': userName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create ReviewLike from Firestore document
  factory ReviewLike.fromJson(Map<String, dynamic> json) {
    return ReviewLike(
      id: json['id'] ?? '',
      reviewId: json['reviewId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Check if this like belongs to the current user
  bool isOwner(String currentUserId) {
    return userId == currentUserId;
  }
}
