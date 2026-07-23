import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/health_entry.dart';
import '../../services/firestore_service.dart';
import '../../widgets/health_entry_card.dart';
import '../../widgets/summary_card.dart';
import '../appointment_summary/appointment_summary_screen.dart';
import '../authentication/login_screen.dart';
import '../health_entry/add_health_entry_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  String _moodValue = 'Not recorded';
  String _sleepValue = 'Not recorded';
  String _waterValue = '0 ml today';
  String _medicationValue = 'No medication';

  bool _isLoadingSummary = true;

  @override
  void initState() {
    super.initState();
    _loadTodaySummary();
  }

  Future<void> _loadTodaySummary() async {
    try {
      final entries = await _firestoreService.getTodayEntries();

      String mood = 'Not recorded';
      String sleep = 'Not recorded';
      int waterTotal = 0;
      int medicationCount = 0;

      for (final entry in entries) {
        switch (entry.type) {
          case 'Mood':
            mood =
                entry.data['mood'] as String? ??
                entry.data['title'] as String? ??
                'Not recorded';
            break;

          case 'Sleep':
            final hours = entry.data['hours'];

            if (hours != null) {
              sleep = '$hours hours';
            } else {
              sleep =
                  entry.data['title'] as String? ??
                  'Not recorded';
            }
            break;

          case 'Water':
            final amount = entry.data['amount'];

            if (amount is int) {
              waterTotal += amount;
            } else if (amount is double) {
              waterTotal += amount.round();
            } else {
              final oldTitle =
                  entry.data['title'] as String? ?? '';

              waterTotal += _extractNumber(oldTitle);
            }
            break;

          case 'Medication':
            medicationCount++;
            break;
        }
      }

      if (!mounted) return;

      setState(() {
        _moodValue = mood;
        _sleepValue = sleep;
        _waterValue = '$waterTotal ml today';
        _medicationValue = medicationCount == 0
            ? 'No medication'
            : '$medicationCount recorded';
        _isLoadingSummary = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoadingSummary = false;
      });
    }
  }

  int _extractNumber(String text) {
    final match = RegExp(r'\d+').firstMatch(text);

    if (match == null) {
      return 0;
    }

    return int.tryParse(match.group(0) ?? '') ?? 0;
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final displayName =
        user?.displayName?.trim().isNotEmpty == true
            ? user!.displayName!
            : 'Welcome';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('HealthTimeLine'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          24,
          24,
          24,
          110,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Good Morning 👋',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Let's take care of your health today.",
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 30),

            const Text(
              "Today's Summary",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            if (_isLoadingSummary)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      icon: Icons.mood,
                      title: 'Mood',
                      value: _moodValue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SummaryCard(
                      icon: Icons.bedtime,
                      title: 'Sleep',
                      value: _sleepValue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      icon: Icons.water_drop,
                      title: 'Water',
                      value: _waterValue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SummaryCard(
                      icon: Icons.medication,
                      title: 'Medication',
                      value: _medicationValue,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.medical_information_outlined,
                      color: AppColors.primary,
                      size: 29,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Appointment Summary',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Prepare a structured health summary for your next medical appointment.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AppointmentSummaryScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.description_outlined),
                      label: const Text(
                        'Prepare Report',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            StreamBuilder<List<HealthEntry>>(
              stream: _firestoreService.getRecentEntries(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Something went wrong'),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final entries = snapshot.data ?? [];

                if (entries.isEmpty) {
                  return const Card(
                    child: ListTile(
                      title: Text('No health entries yet'),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];

                    return HealthEntryCard(
                      type: entry.type,
                      title: entry.title,
                      description: entry.description,
                      createdAt: entry.createdAt == null
                          ? null
                          : Timestamp.fromDate(entry.createdAt!),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final saved = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const AddHealthEntryScreen(),
            ),
          );

          if (saved == true) {
            await _loadTodaySummary();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
    );
  }
}