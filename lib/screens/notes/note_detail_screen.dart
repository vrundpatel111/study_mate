import 'package:flutter/material.dart';
import 'package:studymate/models/note.dart';
import 'package:studymate/services/note_service.dart';
import 'package:studymate/services/shared_note_service.dart';
import 'package:studymate/services/auth_service.dart';
import 'package:intl/intl.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note note;

  const NoteDetailScreen({Key? key, required this.note}) : super(key: key);

  @override
  _NoteDetailScreenState createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late Note _note;
  final NoteService _noteService = NoteService();
  final SharedNoteService _sharedNoteService = SharedNoteService();
  final AuthService _authService = AuthService();
  bool _isEditing = false;
  bool _isLoading = false;
  
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _subjectController = TextEditingController();
  final _categoryController = TextEditingController();
  final _tagsController = TextEditingController();
  
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _note = widget.note;
    _initializeForm();
  }

  void _initializeForm() {
    _titleController.text = _note.title;
    _contentController.text = _note.content;
    _subjectController.text = _note.subject;
    _categoryController.text = _note.category ?? '';
    _tagsController.text = _note.tags.join(', ');
    _isFavorite = _note.isFavorite;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _subjectController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isLoading = true);
    
    try {
      final updatedNote = _note.copyWith(isFavorite: !_note.isFavorite);
      await _noteService.updateNote(updatedNote);
      
      setState(() {
        _note = updatedNote;
        _isFavorite = updatedNote.isFavorite;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_note.isFavorite 
              ? 'Added to favorites!' 
              : 'Removed from favorites'),
          backgroundColor: _note.isFavorite ? Colors.red : Colors.grey,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating note: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedNote = _note.copyWith(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        subject: _subjectController.text.trim(),
        category: _categoryController.text.trim().isEmpty 
            ? null 
            : _categoryController.text.trim(),
        tags: _tagsController.text.isEmpty
            ? []
            : _tagsController.text.split(',').map((e) => e.trim()).toList(),
        updatedAt: DateTime.now(),
        isFavorite: _isFavorite,
      );

      await _noteService.updateNote(updatedNote);
      
      setState(() {
        _note = updatedNote;
        _isEditing = false;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Note updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating note: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _shareNote() async {
    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please log in to share notes'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show sharing options dialog
    final shouldShare = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Share Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share "${_note.title}" with other students?'),
            SizedBox(height: 16),
            Text(
              'Your note will be visible to all users and they can like and review it.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            if (_note.isShared) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This note is already shared',
                        style: TextStyle(color: Colors.blue[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_note.isShared ? 'View Shared' : 'Share'),
          ),
        ],
      ),
    );

    if (shouldShare == true) {
      if (_note.isShared) {
        // Note is already shared, show shared notes or navigate to shared version
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note is already shared! Check the Shared Notes section.'),
            backgroundColor: Colors.blue,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final sharedNoteId = await _sharedNoteService.shareNote(_note);
        
        // Update local note to mark as shared
        final updatedNote = _note.copyWith(
          isShared: true,
          sharedNoteId: sharedNoteId,
          sharedAt: DateTime.now(),
        );
        await _noteService.updateNote(updatedNote);
        
        setState(() {
          _note = updatedNote;
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note shared successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing note: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteNote() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Note'),
        content: Text('Are you sure you want to delete "${_note.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      
      try {
        await _noteService.deleteNote(_note.id);
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting note: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Note' : 'Note Details'),
        elevation: 0,
        actions: [
          if (!_isEditing) ...[
            IconButton(
              onPressed: _toggleFavorite,
              icon: Icon(
                _note.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _note.isFavorite ? Colors.red : Colors.white,
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: Icon(Icons.edit),
            ),
            IconButton(
              onPressed: _shareNote,
              icon: Icon(
                _note.isShared ? Icons.share : Icons.share_outlined,
                color: _note.isShared ? Colors.blue : Colors.white,
              ),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Note'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteNote();
                }
              },
            ),
          ] else ...[
            IconButton(
              onPressed: () {
                setState(() => _isFavorite = !_isFavorite);
              },
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : Colors.white,
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                _isEditing = false;
                _initializeForm();
              }),
              child: Text('CANCEL', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: _isLoading ? null : _saveChanges,
              child: Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
      body: Form(
        key: _formKey,
        child: _isEditing ? _buildEditView() : _buildViewMode(),
      ),
    );
  }
  
  Widget _buildViewMode() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _note.title,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade800,
                  ),
                ),
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _note.subject,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_note.category != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _note.category!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      'Updated ${DateFormat('MMM dd, yyyy - HH:mm').format(_note.updatedAt)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    Spacer(),
                    Text(
                      '${_note.wordCount} words • ${_note.readingTimeMinutes} min read',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Content
          Container(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_note.content.isNotEmpty)
                  Text(
                    _note.content,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.grey[800],
                    ),
                  )
                else
                  Container(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.note_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No content',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap edit to add content to this note',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Tags
          if (_note.tags.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tags',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _note.tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        backgroundColor: Colors.indigo.withOpacity(0.1),
                        labelStyle: TextStyle(color: Colors.indigo),
                        side: BorderSide(color: Colors.indigo.withOpacity(0.3)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          
          // Metadata
          Container(
            padding: EdgeInsets.all(24),
            margin: EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Note Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 16),
                _buildInfoRow(Icons.add_circle_outline, 'Created', 
                    DateFormat('MMM dd, yyyy - HH:mm').format(_note.createdAt)),
                _buildInfoRow(Icons.edit, 'Last Modified', 
                    DateFormat('MMM dd, yyyy - HH:mm').format(_note.updatedAt)),
                _buildInfoRow(Icons.text_fields, 'Word Count', '${_note.wordCount} words'),
                _buildInfoRow(Icons.access_time, 'Reading Time', 
                    '${_note.readingTimeMinutes} minute${_note.readingTimeMinutes != 1 ? 's' : ''}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEditView() {
    return Column(
      children: [
        // Title and Meta Info
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
          child: Column(
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Note title...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  labelText: 'Title',
                ),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                validator: (value) =>
                    value?.trim().isEmpty == true ? 'Please enter a note title' : null,
              ),
              SizedBox(height: 16),
              
              // Subject and Category
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _subjectController,
                      decoration: InputDecoration(
                        labelText: 'Subject',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) =>
                          value?.trim().isEmpty == true ? 'Please enter a subject' : null,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _categoryController,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Content
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16),
            child: TextFormField(
              controller: _contentController,
              decoration: InputDecoration(
                hintText: 'Start writing your note...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.indigo, width: 2),
                ),
                contentPadding: EdgeInsets.all(16),
              ),
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ),
        
        // Tags
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _tagsController,
            decoration: InputDecoration(
              labelText: 'Tags',
              hintText: 'Enter tags separated by commas',
              prefixIcon: Icon(Icons.tag),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
