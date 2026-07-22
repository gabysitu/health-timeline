import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class SymptomEntryScreen extends StatefulWidget {
  const SymptomEntryScreen({super.key});

  @override
  State<SymptomEntryScreen> createState() => _SymptomEntryScreenState();
}

class _SymptomEntryScreenState extends State<SymptomEntryScreen> {
  final TextEditingController _symptomController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _selectedSeverity;
  String? _selectedDuration;
  bool _isSaving = false;

  final List<String> _severityOptions = const [
    'Mild',
    'Moderate',
    'Severe',
    'Very severe',
  ];

  final List<String> _durationOptions = const [
    'Less than 1 hour',
    '1–4 hours',
    '4–12 hours',
    'All day',
    'Several days',
  ];

  @override
  void dispose() {
    _symptomController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveSymptom() async {
    final user = FirebaseAuth.instance.currentUser;
    final symptom = _symptomController.text.trim();
    final notes = _notesController.text.trim();

    if (user == null) {
      _showMessage('You must be logged in to save a symptom.');
      return;
    }

    if (symptom.isEmpty) {
      _showMessage('Please enter the symptom.');
      return;
    }

    if (_selectedSeverity == null) {
      _showMessage('Please select the severity.');
      return;
    }

    if (_selectedDuration == null) {
      _showMessage('Please select the duration.');
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
        'type': 'Symptom',
        'symptom': symptom,
        'severity': _selectedSeverity,
        'duration': _selectedDuration,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': user.uid,
      });

      if (!mounted) return;

      _showMessage('Symptom saved successfully.');
      Navigator.pop(context, true);
    } on FirebaseException catch (error) {
      _showMessage(
        error.message ?? 'Unable to save the symptom.',
      );
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
        title: const Text('Symptom'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.health_and_safety_outlined,
              size: 72,
              color: AppColors.primary,
            ),
            const SizedBox(height: 18),
            const Text(
              'Record a symptom',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Add the symptom, severity, duration, and any useful notes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _symptomController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Symptom',
                hintText: 'Example: Headache',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Severity',
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
              children: _severityOptions.map((severity) {
                return ChoiceChip(
                  label: Text(severity),
                  selected: _selectedSeverity == severity,
                  onSelected: (_) {
                    setState(() {
                      _selectedSeverity = severity;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Duration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedDuration,
              decoration: const InputDecoration(
                labelText: 'Select duration',
                border: OutlineInputBorder(),
              ),
              items: _durationOptions.map((duration) {
                return DropdownMenuItem<String>(
                  value: duration,
                  child: Text(duration),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDuration = value;
                });
              },
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Example: Started after lunch',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _saveSymptom,
              child: Text(
                _isSaving ? 'Saving...' : 'Save Symptom',
              ),
            ),
          ],
        ),
      ),
    );
  }
}