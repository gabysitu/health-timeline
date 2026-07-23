import 'health_entry.dart';

class AppointmentSummary {
  final DateTime startDate;
  final DateTime endDate;
  final List<HealthEntry> entries;

  final int moodEntryCount;
  final int symptomEntryCount;
  final int medicationEntryCount;
  final int sleepEntryCount;
  final int waterEntryCount;
  final int noteEntryCount;

  final String mostFrequentSymptom;
  final int mostFrequentSymptomCount;

  final double averageSleepHours;
  final double averageWaterMillilitresPerDay;

  final String mostFrequentMood;
  final String mostRecordedMedication;
  final int mostRecordedMedicationCount;

  final List<String> healthHighlights;

  const AppointmentSummary({
    required this.startDate,
    required this.endDate,
    required this.entries,
    required this.moodEntryCount,
    required this.symptomEntryCount,
    required this.medicationEntryCount,
    required this.sleepEntryCount,
    required this.waterEntryCount,
    required this.noteEntryCount,
    required this.mostFrequentSymptom,
    required this.mostFrequentSymptomCount,
    required this.averageSleepHours,
    required this.averageWaterMillilitresPerDay,
    required this.mostFrequentMood,
    required this.mostRecordedMedication,
    required this.mostRecordedMedicationCount,
    required this.healthHighlights,
  });

  int get totalEntries => entries.length;

  int get reportDayCount {
    final normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    final normalizedEnd = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    );

    return normalizedEnd.difference(normalizedStart).inDays + 1;
  }

  double get averageWaterLitresPerDay {
    return averageWaterMillilitresPerDay / 1000;
  }

  bool get hasSymptoms => symptomEntryCount > 0;

  bool get hasMedication => medicationEntryCount > 0;

  bool get hasSleep => sleepEntryCount > 0;

  bool get hasWater => waterEntryCount > 0;

  bool get hasMood => moodEntryCount > 0;

  bool get hasNotes => noteEntryCount > 0;
}