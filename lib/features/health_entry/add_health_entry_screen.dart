import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'medication_entry_screen.dart';
import 'mood_entry_screen.dart';
import 'sleep_entry_screen.dart';
import 'symptom_entry_screen.dart';
import 'water_entry_screen.dart';

class AddHealthEntryScreen extends StatelessWidget {
  const AddHealthEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entryTypes = [
      const _EntryTypeData(
        title: 'Mood',
        subtitle: 'Record how you feel today',
        icon: Icons.mood,
        isAvailable: true,
      ),
      const _EntryTypeData(
        title: 'Symptom',
        subtitle: 'Track a symptom or discomfort',
        icon: Icons.health_and_safety_outlined,
        isAvailable: true,
      ),
      const _EntryTypeData(
        title: 'Medication',
        subtitle: 'Record a medication or dose',
        icon: Icons.medication_outlined,
        isAvailable: true,
      ),
      const _EntryTypeData(
        title: 'Sleep',
        subtitle: 'Track your sleep',
        icon: Icons.bedtime_outlined,
        isAvailable: true,
      ),
      const _EntryTypeData(
        title: 'Water',
        subtitle: 'Track your water intake',
        icon: Icons.water_drop_outlined,
        isAvailable: true,
      ),
      const _EntryTypeData(
        title: 'Note',
        subtitle: 'Save a general health note',
        icon: Icons.note_alt_outlined,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Health Entry'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        children: [
          const Text(
            'What would you like to record?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose a health category to continue.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entryTypes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, index) {
              final entryType = entryTypes[index];

              return _EntryTypeCard(
                data: entryType,
                onTap: () async {
                  bool? saved;

                  switch (entryType.title) {
                    case 'Mood':
                      saved = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MoodEntryScreen(),
                        ),
                      );
                      break;

                    case 'Water':
                      saved = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WaterEntryScreen(),
                        ),
                      );
                      break;

                    case 'Medication':
                      saved = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const MedicationEntryScreen(),
                        ),
                      );
                      break;

                    case 'Symptom':
                      saved = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const SymptomEntryScreen(),
                        ),
                      );
                      break;

                    case 'Sleep':
                      saved = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const SleepEntryScreen(),
                        ),
                      );
                      break;

                    default:
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${entryType.title} tracking is coming soon.',
                          ),
                        ),
                      );
                      return;
                  }

                  if (saved == true && context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EntryTypeCard extends StatelessWidget {
  final _EntryTypeData data;
  final VoidCallback onTap;

  const _EntryTypeCard({
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: data.isAvailable
                ? AppColors.primary.withValues(alpha: 0.45)
                : Colors.transparent,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  data.icon,
                  size: 30,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                data.subtitle,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryTypeData {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isAvailable;

  const _EntryTypeData({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isAvailable = false,
  });
}