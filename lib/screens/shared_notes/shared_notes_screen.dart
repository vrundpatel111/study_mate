import 'package:flutter/material.dart';
import 'package:studymate/models/shared_note.dart';
import 'package:studymate/services/shared_note_service.dart';
import 'package:studymate/screens/shared_notes/shared_note_detail_screen.dart';

class SharedNotesScreen extends StatefulWidget {
  @override
  _SharedNotesScreenState createState() => _SharedNotesScreenState();
}

class _SharedNotesScreenState extends State<SharedNotesScreen>
    with TickerProviderStateMixin {
  final SharedNoteService _sharedNoteService = SharedNoteService();
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<SharedNote> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shared Notes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Recent', icon: Icon(Icons.access_time)),
            Tab(text: 'Trending', icon: Icon(Icons.trending_up)),
            Tab(text: 'My Notes', icon: Icon(Icons.person)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isSearching
                ? _buildSearchResults()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRecentNotes(),
                      _buildTrendingNotes(),
                      _buildMyNotes(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search shared notes...',
          prefixIcon: Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: _clearSearch,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildRecentNotes() {
    return StreamBuilder<List<SharedNote>>(
      stream: _sharedNoteService.getPublicNotesStream(limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Error loading notes: ${snapshot.error}'),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        final notes = snapshot.data ?? [];
        if (notes.isEmpty) {
          return _buildEmptyState('No shared notes yet', Icons.note_add);
        }

        return _buildNotesList(notes);
      },
    );
  }

  Widget _buildTrendingNotes() {
    return FutureBuilder<List<SharedNote>>(
      future: _sharedNoteService.getTrendingNotes(limit: 30),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Error loading trending notes: ${snapshot.error}'),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        final notes = snapshot.data ?? [];
        if (notes.isEmpty) {
          return _buildEmptyState('No trending notes', Icons.trending_up);
        }

        return _buildNotesList(notes);
      },
    );
  }

  Widget _buildMyNotes() {
    return StreamBuilder<List<SharedNote>>(
      stream: _sharedNoteService.getMySharedNotesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Error loading your notes: ${snapshot.error}'),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        final notes = snapshot.data ?? [];
        if (notes.isEmpty) {
          return _buildEmptyState(
            'You haven\'t shared any notes yet',
            Icons.share,
            action: () => Navigator.pop(context),
            actionText: 'Share a Note',
          );
        }

        return _buildNotesList(notes);
      },
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty && _searchQuery.isNotEmpty) {
      return _buildEmptyState('No notes found for "$_searchQuery"', Icons.search_off);
    }

    return _buildNotesList(_searchResults);
  }

  Widget _buildNotesList(List<SharedNote> notes) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return _buildNoteCard(note);
      },
    );
  }

  Widget _buildNoteCard(SharedNote note) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _openNoteDetails(note),
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildRatingBadge(note.averageRating, note.reviewsCount),
                ],
              ),
              SizedBox(height: 8),
              Text(
                note.content,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: note.authorPhotoURL != null
                        ? NetworkImage(note.authorPhotoURL!)
                        : null,
                    child: note.authorPhotoURL == null
                        ? Icon(Icons.person, size: 16)
                        : null,
                  ),
                  SizedBox(width: 8),
                  Text(
                    note.authorName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      note.subject,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.indigo,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  _buildStatChip(Icons.favorite, note.likesCount.toString()),
                  SizedBox(width: 8),
                  _buildStatChip(Icons.visibility, note.viewsCount.toString()),
                  SizedBox(width: 8),
                  _buildStatChip(Icons.download, note.downloadsCount.toString()),
                  Spacer(),
                  Text(
                    _formatDate(note.sharedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBadge(double rating, int reviewCount) {
    if (reviewCount == 0) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 16, color: Colors.amber),
          SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.amber[800],
            ),
          ),
          SizedBox(width: 2),
          Text(
            '($reviewCount)',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    String message,
    IconData icon, {
    VoidCallback? action,
    String? actionText,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          if (action != null && actionText != null) ...[
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: action,
              child: Text(actionText),
            ),
          ],
        ],
      ),
    );
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;
    });

    if (query.isNotEmpty) {
      _performSearch(query);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
      _searchResults.clear();
    });
  }

  Future<void> _performSearch(String query) async {
    try {
      final results = await _sharedNoteService.searchNotes(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: ${e.toString()}')),
        );
      }
    }
  }

  void _openNoteDetails(SharedNote note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SharedNoteDetailScreen(note: note),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
