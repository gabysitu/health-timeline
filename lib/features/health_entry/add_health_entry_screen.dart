import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AddHealthEntryScreen extends StatefulWidget {
  const AddHealthEntryScreen({super.key});

  @override
  State<AddHealthEntryScreen> createState() => _AddHealthEntryScreenState();
}

class _AddHealthEntryScreenState extends State<AddHealthEntryScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedType = 'Mood';
  bool _isSaving = false;

  final List<String> _entryTypes = [
    'Mood',
    'Symptom',
    'Medication',
    'Sleep',
    'Water',
    'Note',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    final user = FirebaseAuth.instance.currentUser;
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (user == null) {
      _showMessage('You must be logged in to save an entry.');
      return;
    }

    if (title.isEmpty) {
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
        'type': _selectedType,
        'title': title,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': user.uid,
      });

      if (!mounted) return;

      _showMessage('Health entry saved successfully.');

      Navigator.pop(context);
    } on FirebaseException catch (error) {
      _showMessage(error.message ?? 'Unable to save the health entry.');
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
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Health Entry'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'What would you like to record?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Entry type',
                border: OutlineInputBorder(),
              ),
              items: _entryTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedType = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _saveEntry,
              child: Text(
                _isSaving ? 'Saving...' : 'Save Entry',
              ),
            ),
          ],
        ),
      ),
    );
  }
}