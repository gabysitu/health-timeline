import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class WaterEntryScreen extends StatefulWidget {
  const WaterEntryScreen({super.key});

  @override
  State<WaterEntryScreen> createState() => _WaterEntryScreenState();
}

class _WaterEntryScreenState extends State<WaterEntryScreen> {
  final TextEditingController _customAmountController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  int? _selectedAmount;
  bool _isSaving = false;

  final List<int> _waterAmounts = const [
    250,
    500,
    750,
    1000,
  ];

  @override
  void dispose() {
    _customAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveWaterEntry() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('You must be logged in to save water intake.');
      return;
    }

    final customAmount = int.tryParse(
      _customAmountController.text.trim(),
    );

    final amount = customAmount ?? _selectedAmount;

    if (amount == null || amount <= 0) {
      _showMessage('Please choose or enter a valid water amount.');
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
        'type': 'Water',
        'amount': amount,
        'unit': 'ml',
        'notes': _notesController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'userId': user.uid,
      });

      if (!mounted) return;

      _showMessage('Water intake saved successfully.');
      Navigator.pop(context, true);
    } on FirebaseException catch (error) {
      _showMessage(
        error.message ?? 'Unable to save your water intake.',
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
        title: const Text('Water'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.water_drop_outlined,
              size: 72,
              color: AppColors.primary,
            ),
            const SizedBox(height: 18),
            const Text(
              'How much water did you drink?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Choose an amount or enter a custom value.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 30),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: _waterAmounts.map((amount) {
                final isSelected = _selectedAmount == amount;

                return ChoiceChip(
                  label: Text(
                    amount == 1000 ? '1 L' : '$amount ml',
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedAmount = amount;
                      _customAmountController.clear();
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 26),
            TextField(
              controller: _customAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Custom amount',
                hintText: 'Example: 350',
                suffixText: 'ml',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_selectedAmount != null) {
                  setState(() {
                    _selectedAmount = null;
                  });
                }
              },
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Example: After my workout',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _saveWaterEntry,
              child: Text(
                _isSaving ? 'Saving...' : 'Save Water',
              ),
            ),
          ],
        ),
      ),
    );
  }
}