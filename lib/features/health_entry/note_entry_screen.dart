import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/tracker_widgets/tracker_header.dart';
import '../../widgets/tracker_widgets/tracker_save_button.dart';
import '../../widgets/tracker_widgets/tracker_text_field.dart';

class NoteEntryScreen extends StatefulWidget {
  const NoteEntryScreen({super.key});

  @override
  State<NoteEntryScreen> createState() => _NoteEntryScreenState();
}

class _NoteEntryScreenState extends State<NoteEntryScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('You must be logged in.');
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      _showMessage('Please enter a title.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('health_entries')
          .add({
        'type': 'Note',
        'title': _titleController.text.trim(),
        'notes': _notesController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'userId': user.uid,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note saved successfully.'),
        ),
      );

      Navigator.pop(context, true);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Health Note'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TrackerHeader(
              icon: Icons.note_alt_outlined,
              title: 'Health Note',
              subtitle:
                  'Write down anything important you want to remember before your appointment.',
            ),

            const SizedBox(height: 30),

            TrackerTextField(
              controller: _titleController,
              label: 'Title',
              hint: 'Example: GP appointment',
              icon: Icons.title,
            ),

            const SizedBox(height: 20),

            TrackerTextField(
              controller: _notesController,
              label: 'Notes',
              hint: 'Write your notes here...',
              icon: Icons.notes,
              maxLines: 6,
            ),

            const SizedBox(height: 30),

            TrackerSaveButton(
              isSaving: _isSaving,
              text: 'Save Note',
              onPressed: _saveNote,
            ),
          ],
        ),
      ),
    );
  }
}