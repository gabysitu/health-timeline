import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/firestore_service.dart';
import '../../widgets/health_entry_card.dart';
import '../../widgets/summary_card.dart';
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
        final data = entry.data() as Map<String, dynamic>;

        final type = data['type'] ?? '';
        final title = data['title'] ?? '';

        switch (type) {
          case 'Mood':
            mood = title;
            break;

          case 'Sleep':
            sleep = title;
            break;

          case 'Water':
            waterTotal += _extractNumber(title);
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

    if (match == null) return 0;

    return int.tryParse(match.group(0)!) ?? 0;
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
        (user?.displayName != null && user!.displayName!.trim().isNotEmpty)
            ? user.displayName!
            : 'Welcome';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('HealthTimeLine'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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

            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            StreamBuilder<QuerySnapshot>(
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

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
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
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data =
                        docs[index].data() as Map<String, dynamic>;

                    return HealthEntryCard(
                      type: data['type'] ?? '',
                      title: data['title'] ?? '',
                      description:
                          data['description'] ?? '',
                      createdAt:
                          data['createdAt'] as Timestamp?,
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
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const AddHealthEntryScreen(),
            ),
          );

          await _loadTodaySummary();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
    );
  }
}