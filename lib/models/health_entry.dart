import 'package:cloud_firestore/cloud_firestore.dart';

class HealthEntry {
  final String id;
  final String type;
  final DateTime? createdAt;
  final String userId;
  final Map<String, dynamic> data;

  const HealthEntry({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.userId,
    required this.data,
  });

  factory HealthEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final documentData = document.data() ?? {};
    final timestamp = documentData['createdAt'];

    return HealthEntry(
      id: document.id,
      type: documentData['type'] as String? ?? 'Unknown',
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
      userId: documentData['userId'] as String? ?? '',
      data: documentData,
    );
  }

  String get title {
    switch (type) {
      case 'Mood':
        return data['mood'] as String? ??
            data['title'] as String? ??
            'Mood entry';

      case 'Water':
        final amount = data['amount'];
        final unit = data['unit'] as String? ?? 'ml';
        return amount == null ? 'Water entry' : '$amount $unit';

      case 'Medication':
        return data['medicineName'] as String? ??
            data['title'] as String? ??
            'Medication entry';

      case 'Symptom':
        return data['symptom'] as String? ??
            data['title'] as String? ??
            'Symptom entry';

      case 'Sleep':
        final hours = data['hours'];
        return hours == null ? 'Sleep entry' : '$hours hours';

      case 'Note':
        return data['title'] as String? ?? 'Health note';

      default:
        return data['title'] as String? ?? 'Health entry';
    }
  }

  String get description {
    switch (type) {
      case 'Mood':
        return data['notes'] as String? ??
            data['description'] as String? ??
            '';

      case 'Water':
        return data['notes'] as String? ?? '';

      case 'Medication':
        final dose = data['dose'] as String? ?? '';
        final notes = data['notes'] as String? ?? '';

        if (dose.isNotEmpty && notes.isNotEmpty) {
          return '$dose • $notes';
        }

        return dose.isNotEmpty ? dose : notes;

      case 'Symptom':
        final severity = data['severity'] as String? ?? '';
        final duration = data['duration'] as String? ?? '';
        final notes = data['notes'] as String? ?? '';

        final details = [
          if (severity.isNotEmpty) 'Severity: $severity',
          if (duration.isNotEmpty) 'Duration: $duration',
          if (notes.isNotEmpty) notes,
        ];

        return details.join(' • ');

      case 'Sleep':
        return data['notes'] as String? ??
            data['description'] as String? ??
            '';

      case 'Note':
        return data['notes'] as String? ??
            data['description'] as String? ??
            '';

      default:
        return data['description'] as String? ?? '';
    }
  }
}