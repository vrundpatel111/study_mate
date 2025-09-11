import 'package:hive/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 2)
class Note extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content;

  @HiveField(3)
  String subject;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  @HiveField(6)
  List<String> tags;

  @HiveField(7)
  String? imagePath;

  @HiveField(8)
  bool isFavorite;

  @HiveField(9)
  String? category;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.subject,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.imagePath,
    this.isFavorite = false,
    this.category,
  });

  // Get word count for the note content
  int get wordCount {
    if (content.isEmpty) return 0;
    return content.trim().split(RegExp(r'\s+')).length;
  }

  // Get reading time estimate (average 200 words per minute)
  int get readingTimeMinutes {
    return (wordCount / 200).ceil();
  }

  // Create a copy of the note with updated fields
  Note copyWith({
    String? title,
    String? content,
    String? subject,
    DateTime? updatedAt,
    List<String>? tags,
    String? imagePath,
    bool? isFavorite,
    String? category,
  }) {
    return Note(
      id: this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      subject: subject ?? this.subject,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      imagePath: imagePath ?? this.imagePath,
      isFavorite: isFavorite ?? this.isFavorite,
      category: category ?? this.category,
    );
  }

  // Check if note matches search query
  bool matchesSearch(String query) {
    final lowercaseQuery = query.toLowerCase();
    return title.toLowerCase().contains(lowercaseQuery) ||
        content.toLowerCase().contains(lowercaseQuery) ||
        subject.toLowerCase().contains(lowercaseQuery) ||
        tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
  }
}