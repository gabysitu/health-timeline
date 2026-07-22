import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/entry_widgets/emoji_option_card.dart';

class MoodEntryScreen extends StatefulWidget {
  const MoodEntryScreen({super.key});

  @override
  State<MoodEntryScreen> createState() => _MoodEntryScreenState();
}

class _MoodEntryScreenState extends State<MoodEntryScreen> {
  final TextEditingController _notesController = TextEditingController();

  String? _selectedMood;
  bool _isSaving = false;

  final List<Map<String, String>> _moods = const [
    {
      'label': 'Amazing',
      'emoji': '😁',
    },
    {
      'label': 'Happy',
      'emoji': '😊',
    },
    {
      'label': 'Neutral',
      'emoji': '😐',
    },
    {
      'label': 'Sad',
      'emoji': '🙁',
    },
    {
      'label': 'Terrible',
      'emoji': '😭',
    },
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveMood() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('You must be logged in to save your mood.');
      return;
    }

    if (_selectedMood == null) {
      _showMessage('Please select how you are feeling.');
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
        'type': 'Mood',
        'mood': _selectedMood,
        'notes': _notesController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'userId': user.uid,
      });

      if (!mounted) return;

      _showMessage('Mood saved successfully.');
      Navigator.pop(context, true);
    } on FirebaseException catch (error) {
      _showMessage(error.message ?? 'Unable to save your mood.');
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
        title: const Text('Mood'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'How are you feeling today?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Choose the option that best matches your mood.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: _moods.map((mood) {
                final label = mood['label']!;
                final emoji = mood['emoji']!;

                return EmojiOptionCard(
                  emoji: emoji,
                  label: label,
                  isSelected: _selectedMood == label,
                  onTap: () {
                    setState(() {
                      _selectedMood = label;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _notesController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Add a note about your mood...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _saveMood,
              child: Text(
                _isSaving ? 'Saving...' : 'Save Mood',
              ),
            ),
          ],
        ),
      ),
    );
  }
}