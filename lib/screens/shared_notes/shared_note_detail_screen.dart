import 'package:flutter/material.dart';
import 'package:studymate/models/shared_note.dart';
import 'package:studymate/models/note_review.dart';
import 'package:studymate/models/note.dart';
import 'package:studymate/services/shared_note_service.dart';
import 'package:studymate/services/review_service.dart';
import 'package:studymate/services/note_service.dart';
import 'package:studymate/services/auth_service.dart';

class SharedNoteDetailScreen extends StatefulWidget {
  final SharedNote note;

  const SharedNoteDetailScreen({Key? key, required this.note}) : super(key: key);

  @override
  _SharedNoteDetailScreenState createState() => _SharedNoteDetailScreenState();
}

class _SharedNoteDetailScreenState extends State<SharedNoteDetailScreen> {
  final SharedNoteService _sharedNoteService = SharedNoteService();
  final ReviewService _reviewService = ReviewService();
  final NoteService _noteService = NoteService();
  final AuthService _authService = AuthService();
  
  bool _hasLiked = false;
  bool _isLoading = false;
  NoteReview? _userReview;

  @override
  void initState() {
    super.initState();
    _loadUserInteractions();
    _incrementViewCount();
  }

  Future<void> _loadUserInteractions() async {
    if (_authService.currentUser == null) return;

    try {
      final hasLiked = await _reviewService.hasUserLikedNote(widget.note.id);
      final userReview = await _reviewService.getUserReviewForNote(widget.note.id);
      
      if (mounted) {
        setState(() {
          _hasLiked = hasLiked;
          _userReview = userReview;
        });
      }
    } catch (e) {
      print('Failed to load user interactions: ${e.toString()}');
    }
  }

  Future<void> _incrementViewCount() async {
    await _sharedNoteService.incrementViewCount(widget.note.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shared Note'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              if (_authService.currentUser != null) ...[
                PopupMenuItem(
                  value: 'download',
                  child: Row(
                    children: [
                      Icon(Icons.download),
                      SizedBox(width: 8),
                      Text('Save to My Notes'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share),
                      SizedBox(width: 8),
                      Text('Share'),
                    ],
                  ),
                ),
              ],
              if (widget.note.isAuthor(_authService.currentUser?.uid ?? '')) ...[
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNoteHeader(),
                  SizedBox(height: 16),
                  _buildNoteContent(),
                  SizedBox(height: 24),
                  _buildEngagementSection(),
                  SizedBox(height: 24),
                  _buildReviewsSection(),
                ],
              ),
            ),
          ),
          _buildBottomActionBar(),
        ],
      ),
    );
  }

  Widget _buildNoteHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.note.title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: widget.note.authorPhotoURL != null
                  ? NetworkImage(widget.note.authorPhotoURL!)
                  : null,
              child: widget.note.authorPhotoURL == null
                  ? Icon(Icons.person)
                  : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.note.authorName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _formatDate(widget.note.sharedAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                widget.note.subject,
                style: TextStyle(
                  color: Colors.indigo,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (widget.note.tags.isNotEmpty) ...[
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.note.tags.map((tag) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Text(
                  '#$tag',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildNoteContent() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.note.content,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              SizedBox(width: 4),
              Text(
                '${widget.note.readingTimeMinutes} min read',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(width: 16),
              Icon(Icons.text_fields, size: 16, color: Colors.grey[600]),
              SizedBox(width: 4),
              Text(
                '${widget.note.wordCount} words',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatColumn(
          Icons.favorite,
          widget.note.likesCount,
          'Likes',
          Colors.red,
        ),
        _buildStatColumn(
          Icons.star,
          widget.note.reviewsCount,
          'Reviews',
          Colors.amber,
        ),
        _buildStatColumn(
          Icons.visibility,
          widget.note.viewsCount,
          'Views',
          Colors.blue,
        ),
        _buildStatColumn(
          Icons.download,
          widget.note.downloadsCount,
          'Downloads',
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatColumn(IconData icon, int count, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reviews & Ratings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_authService.currentUser != null && _userReview == null)
              TextButton.icon(
                onPressed: _showReviewDialog,
                icon: Icon(Icons.rate_review),
                label: Text('Add Review'),
              ),
          ],
        ),
        if (widget.note.reviewsCount > 0) ...[
          SizedBox(height: 8),
          _buildRatingOverview(),
          SizedBox(height: 16),
        ],
        StreamBuilder<List<NoteReview>>(
          stream: _reviewService.getReviewsForNoteStream(widget.note.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final reviews = snapshot.data ?? [];
            if (reviews.isEmpty) {
              return Center(
                child: Column(
                  children: [
                    Icon(Icons.rate_review, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No reviews yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    if (_authService.currentUser != null) ...[
                      SizedBox(height: 8),
                      Text(
                        'Be the first to review this note!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                return _buildReviewCard(reviews[index]);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildRatingOverview() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            widget.note.averageRating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.amber[800],
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < widget.note.averageRating.floor()
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                ),
                SizedBox(height: 4),
                Text(
                  'Based on ${widget.note.reviewsCount} reviews',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(NoteReview review) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: review.userPhotoURL != null
                      ? NetworkImage(review.userPhotoURL!)
                      : null,
                  child: review.userPhotoURL == null
                      ? Icon(Icons.person, size: 16)
                      : null,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            review.starDisplay,
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            review.timeAgo,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (review.isOwner(_authService.currentUser?.uid ?? ''))
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleReviewAction(value, review),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
              ],
            ),
            if (review.comment.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(review.comment),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    if (_authService.currentUser == null) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border(top: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Text(
          'Please log in to like and review notes',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _toggleLike,
              icon: Icon(
                _hasLiked ? Icons.favorite : Icons.favorite_border,
                color: _hasLiked ? Colors.red : null,
              ),
              label: Text(_hasLiked ? 'Unlike' : 'Like'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasLiked ? Colors.red[50] : null,
                foregroundColor: _hasLiked ? Colors.red : null,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _downloadNote,
              icon: Icon(Icons.download),
              label: Text('Save Note'),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'download':
        _downloadNote();
        break;
      case 'share':
        _shareNote();
        break;
      case 'edit':
        _editNote();
        break;
      case 'delete':
        _deleteNote();
        break;
    }
  }

  void _handleReviewAction(String action, NoteReview review) {
    switch (action) {
      case 'edit':
        _editReview(review);
        break;
      case 'delete':
        _deleteReview(review);
        break;
    }
  }

  Future<void> _toggleLike() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      if (_hasLiked) {
        await _reviewService.unlikeNote(widget.note.id);
      } else {
        await _reviewService.likeNote(widget.note.id);
      }

      setState(() {
        _hasLiked = !_hasLiked;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadNote() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final localNote = _sharedNoteService.convertToLocalNote(widget.note);
      await _noteService.addNote(localNote);
      await _sharedNoteService.incrementDownloadCount(widget.note.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note saved to your collection!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving note: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _shareNote() {
    // Implement share functionality (platform sharing)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share functionality coming soon!')),
    );
  }

  void _editNote() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit functionality coming soon!')),
    );
  }

  Future<void> _deleteNote() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Note'),
        content: Text('Are you sure you want to delete this shared note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _sharedNoteService.deleteSharedNote(widget.note.id);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Note deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting note: ${e.toString()}')),
        );
      }
    }
  }

  void _showReviewDialog() {
    int rating = 5;
    String comment = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Rate this note:'),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () => setState(() => rating = index + 1),
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  );
                }),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Comment (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) => comment = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _submitReview(rating, comment),
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReview(int rating, String comment) async {
    Navigator.pop(context);

    try {
      await _reviewService.addReview(
        noteId: widget.note.id,
        rating: rating,
        comment: comment,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Review added successfully!')),
      );

      _loadUserInteractions();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding review: ${e.toString()}')),
      );
    }
  }

  void _editReview(NoteReview review) {
    // Implement edit review functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit review functionality coming soon!')),
    );
  }

  Future<void> _deleteReview(NoteReview review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Review'),
        content: Text('Are you sure you want to delete your review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _reviewService.deleteReview(review.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Review deleted successfully')),
        );
        _loadUserInteractions();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting review: ${e.toString()}')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
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
