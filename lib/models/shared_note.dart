class SharedNote {
  final String id;
  final String title;
  final String content;
  final String subject;
  final String authorId;
  final String authorName;
  final String? authorPhotoURL;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime sharedAt;
  final List<String> tags;
  final String? category;
  final bool isPublic;
  final String? imagePath;
  
  // Engagement metrics
  final int likesCount;
  final int reviewsCount;
  final double averageRating;
  final int viewsCount;
  final int downloadsCount;
  
  // Metadata
  final Map<String, dynamic>? metadata;

  SharedNote({
    required this.id,
    required this.title,
    required this.content,
    required this.subject,
    required this.authorId,
    required this.authorName,
    this.authorPhotoURL,
    required this.createdAt,
    required this.updatedAt,
    required this.sharedAt,
    this.tags = const [],
    this.category,
    this.isPublic = true,
    this.imagePath,
    this.likesCount = 0,
    this.reviewsCount = 0,
    this.averageRating = 0.0,
    this.viewsCount = 0,
    this.downloadsCount = 0,
    this.metadata,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'subject': subject,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoURL': authorPhotoURL,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'sharedAt': sharedAt.toIso8601String(),
      'tags': tags,
      'category': category,
      'isPublic': isPublic,
      'imagePath': imagePath,
      'likesCount': likesCount,
      'reviewsCount': reviewsCount,
      'averageRating': averageRating,
      'viewsCount': viewsCount,
      'downloadsCount': downloadsCount,
      'metadata': metadata ?? {},
    };
  }

  // Create SharedNote from Firestore document
  factory SharedNote.fromJson(Map<String, dynamic> json) {
    return SharedNote(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      subject: json['subject'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? '',
      authorPhotoURL: json['authorPhotoURL'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      sharedAt: DateTime.parse(json['sharedAt'] ?? DateTime.now().toIso8601String()),
      tags: List<String>.from(json['tags'] ?? []),
      category: json['category'],
      isPublic: json['isPublic'] ?? true,
      imagePath: json['imagePath'],
      likesCount: json['likesCount'] ?? 0,
      reviewsCount: json['reviewsCount'] ?? 0,
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      viewsCount: json['viewsCount'] ?? 0,
      downloadsCount: json['downloadsCount'] ?? 0,
      metadata: json['metadata'] ?? {},
    );
  }

  // Get word count for the note content
  int get wordCount {
    if (content.isEmpty) return 0;
    return content.trim().split(RegExp(r'\s+')).length;
  }

  // Get reading time estimate (average 200 words per minute)
  int get readingTimeMinutes {
    return (wordCount / 200).ceil();
  }

  // Check if note matches search query
  bool matchesSearch(String query) {
    final lowercaseQuery = query.toLowerCase();
    return title.toLowerCase().contains(lowercaseQuery) ||
        content.toLowerCase().contains(lowercaseQuery) ||
        subject.toLowerCase().contains(lowercaseQuery) ||
        authorName.toLowerCase().contains(lowercaseQuery) ||
        tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
  }

  // Create a copy with updated fields
  SharedNote copyWith({
    String? title,
    String? content,
    String? subject,
    String? authorName,
    String? authorPhotoURL,
    DateTime? updatedAt,
    List<String>? tags,
    String? category,
    bool? isPublic,
    String? imagePath,
    int? likesCount,
    int? reviewsCount,
    double? averageRating,
    int? viewsCount,
    int? downloadsCount,
    Map<String, dynamic>? metadata,
  }) {
    return SharedNote(
      id: this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      subject: subject ?? this.subject,
      authorId: this.authorId,
      authorName: authorName ?? this.authorName,
      authorPhotoURL: authorPhotoURL ?? this.authorPhotoURL,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sharedAt: this.sharedAt,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      isPublic: isPublic ?? this.isPublic,
      imagePath: imagePath ?? this.imagePath,
      likesCount: likesCount ?? this.likesCount,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      averageRating: averageRating ?? this.averageRating,
      viewsCount: viewsCount ?? this.viewsCount,
      downloadsCount: downloadsCount ?? this.downloadsCount,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper method to check if current user is the author
  bool isAuthor(String currentUserId) {
    return authorId == currentUserId;
  }

  // Get popularity score based on engagement
  double get popularityScore {
    return (likesCount * 2.0) + (reviewsCount * 3.0) + (viewsCount * 0.1) + (averageRating * 10.0);
  }
}
