import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/health_entry.dart';
import '../../services/firestore_service.dart';
import '../../widgets/health_entry_card.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Timeline'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<HealthEntry>>(
        stream: firestoreService.getRecentEntries(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Something went wrong while loading your timeline.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final entries = snapshot.data ?? [];

          if (entries.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No health entries yet.\nYour saved records will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
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
    );
  }
}