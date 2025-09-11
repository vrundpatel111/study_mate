import 'package:hive/hive.dart';
import 'package:studymate/models/note.dart';
import 'package:uuid/uuid.dart';

class NoteService {
  static const String _boxName = 'notes';
  final _uuid = Uuid();

  Box<Note> get _box => Hive.box<Note>(_boxName);

  // Get all notes sorted by updated date
  List<Note> getAllNotes() {
    return _box.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  // Get notes by subject
  List<Note> getNotesBySubject(String subject) {
    return _box.values
        .where((note) => note.subject.toLowerCase() == subject.toLowerCase())
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  // Get favorite notes
  List<Note> getFavoriteNotes() {
    return _box.values
        .where((note) => note.isFavorite)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  // Get notes by category
  List<Note> getNotesByCategory(String category) {
    return _box.values
        .where((note) => note.category?.toLowerCase() == category.toLowerCase())
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  // Search notes
  List<Note> searchNotes(String query) {
    return _box.values.where((note) {
      return note.matchesSearch(query);
    }).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  // Get notes by tag
  List<Note> getNotesByTag(String tag) {
    return _box.values
        .where((note) => note.tags.any((t) => t.toLowerCase() == tag.toLowerCase()))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  // Get recent notes (last 7 days)
  List<Note> getRecentNotes() {
    final weekAgo = DateTime.now().subtract(Duration(days: 7));
    return _box.values
        .where((note) => note.updatedAt.isAfter(weekAgo))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  // Add note
  Future<void> addNote(Note note) async {
    await _box.put(note.id, note);
  }

  // Update note
  Future<void> updateNote(Note note) async {
    note.updatedAt = DateTime.now();
    await _box.put(note.id, note);
  }

  // Delete note
  Future<void> deleteNote(String noteId) async {
    await _box.delete(noteId);
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String noteId) async {
    final note = _box.get(noteId);
    if (note != null) {
      note.isFavorite = !note.isFavorite;
      note.updatedAt = DateTime.now();
      await _box.put(noteId, note);
    }
  }

  // Get unique subjects
  List<String> getUniqueSubjects() {
    final subjects = _box.values.map((note) => note.subject).toSet().toList();
    subjects.sort();
    return subjects;
  }

  // Get unique categories
  List<String> getUniqueCategories() {
    final categories = _box.values
        .where((note) => note.category != null && note.category!.isNotEmpty)
        .map((note) => note.category!)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  // Get all unique tags
  List<String> getAllTags() {
    final tags = <String>{};
    for (final note in _box.values) {
      tags.addAll(note.tags);
    }
    return tags.toList()..sort();
  }

  // Get notes statistics
  Map<String, dynamic> getNotesStats() {
    final allNotes = getAllNotes();
    final favoriteNotes = getFavoriteNotes();
    final recentNotes = getRecentNotes();
    
    int totalWords = 0;
    for (final note in allNotes) {
      totalWords += note.wordCount;
    }
    
    return {
      'total': allNotes.length,
      'favorites': favoriteNotes.length,
      'recent': recentNotes.length,
      'totalWords': totalWords,
      'averageWords': allNotes.isNotEmpty ? (totalWords / allNotes.length).round() : 0,
    };
  }

  // Create a new note with generated ID
  Note createNote({
    required String title,
    required String content,
    required String subject,
    List<String> tags = const [],
    String? imagePath,
    String? category,
    bool isFavorite = false,
  }) {
    final now = DateTime.now();
    return Note(
      id: _uuid.v4(),
      title: title,
      content: content,
      subject: subject,
      createdAt: now,
      updatedAt: now,
      tags: tags,
      imagePath: imagePath,
      category: category,
      isFavorite: isFavorite,
    );
  }

  // Duplicate a note
  Future<Note> duplicateNote(String noteId) async {
    final originalNote = _box.get(noteId);
    if (originalNote != null) {
      final duplicatedNote = createNote(
        title: '${originalNote.title} (Copy)',
        content: originalNote.content,
        subject: originalNote.subject,
        tags: List.from(originalNote.tags),
        imagePath: originalNote.imagePath,
        category: originalNote.category,
      );
      await addNote(duplicatedNote);
      return duplicatedNote;
    }
    throw Exception('Note not found');
  }
}