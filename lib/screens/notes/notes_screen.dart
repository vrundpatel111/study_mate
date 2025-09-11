import 'package:flutter/material.dart';
import 'package:studymate/models/note.dart';
import 'package:studymate/services/note_service.dart';
import 'package:studymate/screens/notes/add_note_screen.dart';
import 'package:studymate/screens/notes/note_detail_screen.dart';
import 'package:intl/intl.dart';

class NotesScreen extends StatefulWidget {
  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> with TickerProviderStateMixin {
  final NoteService _noteService = NoteService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _filterSubject;
  String? _filterCategory;
  bool _showFavoritesOnly = false;
  
  // Grid view mode
  bool _isGridView = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNotes();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  void _loadNotes() {
    setState(() => _isLoading = true);
    try {
      final notes = _noteService.getAllNotes();
      setState(() {
        _notes = notes;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading notes: $e')),
      );
    }
  }
  
  void _applyFilters() {
    _filteredNotes = _notes.where((note) {
      bool matchesSearch = _searchQuery.isEmpty || note.matchesSearch(_searchQuery);
      bool matchesSubject = _filterSubject == null || note.subject == _filterSubject;
      bool matchesCategory = _filterCategory == null || note.category == _filterCategory;
      bool matchesFavorite = !_showFavoritesOnly || note.isFavorite;
      
      return matchesSearch && matchesSubject && matchesCategory && matchesFavorite;
    }).toList();
    
    // Sort by update date (most recent first)
    _filteredNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }
  
  List<Note> _getNotesByTab() {
    switch (_tabController.index) {
      case 0: // All
        return _filteredNotes;
      case 1: // Favorites
        return _filteredNotes.where((note) => note.isFavorite).toList();
      case 2: // Recent
        final recentNotes = _filteredNotes.where((note) {
          final daysSinceUpdate = DateTime.now().difference(note.updatedAt).inDays;
          return daysSinceUpdate <= 7;
        }).toList();
        return recentNotes;
      default:
        return _filteredNotes;
    }
  }
  
  Future<void> _toggleFavorite(Note note) async {
    try {
      final updatedNote = note.copyWith(isFavorite: !note.isFavorite);
      await _noteService.updateNote(updatedNote);
      _loadNotes();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating note: $e')),
      );
    }
  }
  
  Future<void> _deleteNote(Note note) async {
    try {
      await _noteService.deleteNote(note.id);
      _loadNotes();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting note: $e')),
      );
    }
  }
  
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Notes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String?>(
              value: _filterSubject,
              decoration: InputDecoration(labelText: 'Subject'),
              items: [
                DropdownMenuItem(value: null, child: Text('All Subjects')),
                ..._getUniqueSubjects().map((subject) =>
                  DropdownMenuItem(value: subject, child: Text(subject)),
                ),
              ],
              onChanged: (value) => _filterSubject = value,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              value: _filterCategory,
              decoration: InputDecoration(labelText: 'Category'),
              items: [
                DropdownMenuItem(value: null, child: Text('All Categories')),
                ..._getUniqueCategories().map((category) =>
                  DropdownMenuItem(value: category, child: Text(category ?? 'Uncategorized')),
                ),
              ],
              onChanged: (value) => _filterCategory = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _applyFilters());
              Navigator.pop(context);
            },
            child: Text('Apply'),
          ),
        ],
      ),
    );
  }
  
  List<String> _getUniqueSubjects() {
    return _notes.map((note) => note.subject).toSet().toList();
  }
  
  List<String?> _getUniqueCategories() {
    return _notes.map((note) => note.category).toSet().toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search notes...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (query) {
                      setState(() {
                        _searchQuery = query;
                        _applyFilters();
                      });
                    },
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  onPressed: _showFilterDialog,
                  icon: Icon(Icons.filter_list),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _isGridView = !_isGridView),
                  icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: Colors.indigo,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.indigo,
            onTap: (index) => setState(() {}),
            tabs: [
              Tab(text: 'All (${_filteredNotes.length})'),
              Tab(text: 'Favorites (${_filteredNotes.where((n) => n.isFavorite).length})'),
              Tab(text: 'Recent (${_filteredNotes.where((n) => DateTime.now().difference(n.updatedAt).inDays <= 7).length})'),
            ],
          ),
          
          // Notes List/Grid
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: List.generate(3, (index) {
                      final notes = _getNotesByTab();
                      
                      if (notes.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.note_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No notes found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap + to create your first note',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return RefreshIndicator(
                        onRefresh: () async => _loadNotes(),
                        child: _isGridView
                            ? _buildGridView(notes)
                            : _buildListView(notes),
                      );
                    }),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddNote(),
        child: Icon(Icons.add),
        backgroundColor: Colors.indigo,
      ),
    );
  }
  
  Widget _buildListView(List<Note> notes) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return NoteCard(
          note: note,
          onFavoriteToggle: () => _toggleFavorite(note),
          onDelete: () => _showDeleteDialog(note),
          onTap: () => _navigateToNoteDetail(note),
        );
      },
    );
  }
  
  Widget _buildGridView(List<Note> notes) {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return NoteGridCard(
          note: note,
          onFavoriteToggle: () => _toggleFavorite(note),
          onDelete: () => _showDeleteDialog(note),
          onTap: () => _navigateToNoteDetail(note),
        );
      },
    );
  }
  
  void _showDeleteDialog(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteNote(note);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  void _navigateToAddNote() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddNoteScreen()),
    );
    if (result == true) {
      _loadNotes();
    }
  }
  
  void _navigateToNoteDetail(Note note) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteDetailScreen(note: note),
      ),
    );
    if (result == true) {
      _loadNotes();
    }
  }
}

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  
  const NoteCard({
    Key? key,
    required this.note,
    required this.onFavoriteToggle,
    required this.onDelete,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: onFavoriteToggle,
                    icon: Icon(
                      note.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: note.isFavorite ? Colors.red : Colors.grey,
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline, color: Colors.red),
                  ),
                ],
              ),
              if (note.content.isNotEmpty)
                Text(
                  note.content,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      note.subject,
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (note.category != null) ...[
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        note.category!,
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  Spacer(),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        DateFormat('MMM dd').format(note.updatedAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '${note.wordCount} words',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NoteGridCard extends StatelessWidget {
  final Note note;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  
  const NoteGridCard({
    Key? key,
    required this.note,
    required this.onFavoriteToggle,
    required this.onDelete,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'favorite',
                        child: Row(
                          children: [
                            Icon(
                              note.isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: note.isFavorite ? Colors.red : Colors.grey,
                            ),
                            SizedBox(width: 8),
                            Text(note.isFavorite ? 'Remove from favorites' : 'Add to favorites'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'favorite') {
                        onFavoriteToggle();
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                  ),
                ],
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  child: Text(
                    note.content.isEmpty ? 'No content' : note.content,
                    style: TextStyle(
                      color: note.content.isEmpty ? Colors.grey : Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            note.subject,
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        DateFormat('MMM dd').format(note.updatedAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '${note.wordCount}w',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
