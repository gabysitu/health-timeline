import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class MedicationEntryScreen extends StatefulWidget {
  const MedicationEntryScreen({super.key});

  @override
  State<MedicationEntryScreen> createState() =>
      _MedicationEntryScreenState();
}

class _MedicationEntryScreenState extends State<MedicationEntryScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _doseController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (selectedTime == null) return;

    setState(() {
      _selectedTime = selectedTime;
    });
  }

  Future<void> _saveMedication() async {
    final user = FirebaseAuth.instance.currentUser;
    final medicationName = _nameController.text.trim();
    final dose = _doseController.text.trim();
    final notes = _notesController.text.trim();

    if (user == null) {
      _showMessage('You must be logged in to save medication.');
      return;
    }

    if (medicationName.isEmpty) {
      _showMessage('Please enter the medication name.');
      return;
    }

    if (dose.isEmpty) {
      _showMessage('Please enter the dose.');
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
        'type': 'Medication',
        'medicineName': medicationName,
        'dose': dose,
        'time': {
          'hour': _selectedTime.hour,
          'minute': _selectedTime.minute,
        },
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': user.uid,
      });

      if (!mounted) return;

      _showMessage('Medication saved successfully.');
      Navigator.pop(context, true);
    } on FirebaseException catch (error) {
      _showMessage(
        error.message ?? 'Unable to save the medication.',
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

  String _formatTime(BuildContext context) {
    return _selectedTime.format(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Medication'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.medication_outlined,
              size: 72,
              color: AppColors.primary,
            ),
            const SizedBox(height: 18),
            const Text(
              'Record your medication',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Add the medication name, dose, and time taken.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Medication name',
                hintText: 'Example: Ibuprofen',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _doseController,
              decoration: const InputDecoration(
                labelText: 'Dose',
                hintText: 'Example: 400 mg',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _selectTime,
              icon: const Icon(Icons.access_time),
              label: Text(
                'Time: ${_formatTime(context)}',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Example: Taken after breakfast',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _saveMedication,
              child: Text(
                _isSaving ? 'Saving...' : 'Save Medication',
              ),
            ),
          ],
        ),
      ),
    );
  }
}