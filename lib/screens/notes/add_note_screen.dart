import 'package:flutter/material.dart';
import 'package:studymate/services/note_service.dart';

class AddNoteScreen extends StatefulWidget {
  @override
  _AddNoteScreenState createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _subjectController = TextEditingController();
  final _categoryController = TextEditingController();
  final _tagsController = TextEditingController();
  final NoteService _noteService = NoteService();
  
  bool _isFavorite = false;
  bool _isLoading = false;
  
  final List<String> _commonSubjects = [
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'Computer Science',
    'History',
    'Geography',
    'Literature',
    'Psychology',
    'Economics',
    'Art',
    'Philosophy',
    'Music',
  ];
  
  final List<String> _commonCategories = [
    'Lecture Notes',
    'Study Guide',
    'Research',
    'Summary',
    'Ideas',
    'Meeting Notes',
    'Project Notes',
    'Personal',
    'Important',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _subjectController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final note = _noteService.createNote(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        subject: _subjectController.text.trim(),
        category: _categoryController.text.trim().isEmpty 
            ? null 
            : _categoryController.text.trim(),
        tags: _tagsController.text.isEmpty
            ? []
            : _tagsController.text.split(',').map((e) => e.trim()).toList(),
        isFavorite: _isFavorite,
      );

      await _noteService.addNote(note);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Note created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating note: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Note'),
        elevation: 0,
        actions: [
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
            onPressed: _isLoading ? null : _saveNote,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'SAVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
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
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) {
                        return 'Please enter a note title';
                      }
                      return null;
                    },
                    maxLength: 100,
                  ),
                  
                  // Subject and Category Row
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _subjectController.text.isEmpty 
                              ? null 
                              : _subjectController.text,
                          decoration: InputDecoration(
                            labelText: 'Subject',
                            prefixIcon: Icon(Icons.school, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, 
                              vertical: 8,
                            ),
                          ),
                          items: _commonSubjects.map((subject) {
                            return DropdownMenuItem(
                              value: subject,
                              child: Text(subject, style: TextStyle(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              _subjectController.text = value;
                            }
                          },
                          validator: (value) {
                            if (_subjectController.text.trim().isEmpty) {
                              return 'Please select a subject';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _categoryController.text.isEmpty 
                              ? null 
                              : _categoryController.text,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            prefixIcon: Icon(Icons.category, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, 
                              vertical: 8,
                            ),
                          ),
                          items: _commonCategories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category, style: TextStyle(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              _categoryController.text = value;
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  
                  // Custom Subject/Category inputs
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _subjectController,
                          decoration: InputDecoration(
                            labelText: 'Custom Subject',
                            hintText: 'Or enter custom subject',
                            prefixIcon: Icon(Icons.edit, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, 
                              vertical: 8,
                            ),
                          ),
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _categoryController,
                          decoration: InputDecoration(
                            labelText: 'Custom Category',
                            hintText: 'Or enter custom category',
                            prefixIcon: Icon(Icons.label, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, 
                              vertical: 8,
                            ),
                          ),
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Content Area
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Content',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _contentController,
                        decoration: InputDecoration(
                          hintText: 'Start writing your note...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.indigo, width: 2),
                          ),
                          contentPadding: EdgeInsets.all(16),
                          hintStyle: TextStyle(color: Colors.grey[400]),
                        ),
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Tags and Actions
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
              child: Column(
                children: [
                  // Tags
                  TextFormField(
                    controller: _tagsController,
                    decoration: InputDecoration(
                      labelText: 'Tags',
                      hintText: 'Enter tags separated by commas (optional)',
                      prefixIcon: Icon(Icons.tag),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.indigo, width: 2),
                      ),
                      helperText: 'Example: important, exam, chapter1',
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveNote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save),
                                SizedBox(width: 8),
                                Text(
                                  'Save Note',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
