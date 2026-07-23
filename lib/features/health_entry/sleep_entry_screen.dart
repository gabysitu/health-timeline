import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/tracker_widgets/tracker_header.dart';
import '../../widgets/tracker_widgets/tracker_save_button.dart';
import '../../widgets/tracker_widgets/tracker_text_field.dart';

class SleepEntryScreen extends StatefulWidget {
  const SleepEntryScreen({super.key});

  @override
  State<SleepEntryScreen> createState() => _SleepEntryScreenState();
}

class _SleepEntryScreenState extends State<SleepEntryScreen> {
  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _selectedQuality;
  bool _isSaving = false;

  final List<String> _qualities = const [
    'Excellent',
    'Good',
    'Fair',
    'Poor',
  ];

  @override
  void dispose() {
    _hoursController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveSleep() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('You must be logged in.');
      return;
    }

    final hours = double.tryParse(_hoursController.text);

    if (hours == null) {
      _showMessage('Please enter the number of hours slept.');
      return;
    }

    if (_selectedQuality == null) {
      _showMessage('Please select your sleep quality.');
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
        'type': 'Sleep',
        'hours': hours,
        'quality': _selectedQuality,
        'notes': _notesController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'userId': user.uid,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sleep entry saved successfully.'),
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
        title: const Text('Sleep'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TrackerHeader(
              icon: Icons.bedtime_outlined,
              title: 'Sleep Tracker',
              subtitle:
                  'Record your sleep duration and quality.',
            ),

            const SizedBox(height: 30),

            TrackerTextField(
              controller: _hoursController,
              label: 'Hours slept',
              hint: 'Example: 7.5',
              icon: Icons.access_time,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Sleep Quality',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _qualities.map((quality) {
                return ChoiceChip(
                  label: Text(quality),
                  selected: _selectedQuality == quality,
                  onSelected: (_) {
                    setState(() {
                      _selectedQuality = quality;
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            TrackerTextField(
              controller: _notesController,
              label: 'Notes',
              hint: 'Optional notes...',
              icon: Icons.notes,
              maxLines: 4,
            ),

            const SizedBox(height: 30),

            TrackerSaveButton(
              isSaving: _isSaving,
              text: 'Save Sleep',
              onPressed: _saveSleep,
            ),
          ],
        ),
      ),
    );
  }
}