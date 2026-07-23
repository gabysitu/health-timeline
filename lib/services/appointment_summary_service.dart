import '../models/appointment_summary.dart';
import '../models/health_entry.dart';

class AppointmentSummaryService {
  AppointmentSummary buildSummary({
    required DateTime startDate,
    required DateTime endDate,
    required List<HealthEntry> entries,
  }) {
    final moodEntries =
        entries.where((entry) => entry.type == 'Mood').toList();

    final symptomEntries =
        entries.where((entry) => entry.type == 'Symptom').toList();

    final medicationEntries =
        entries.where((entry) => entry.type == 'Medication').toList();

    final sleepEntries =
        entries.where((entry) => entry.type == 'Sleep').toList();

    final waterEntries =
        entries.where((entry) => entry.type == 'Water').toList();

    final noteEntries =
        entries.where((entry) => entry.type == 'Note').toList();

    final symptomFrequency = _countTextValues(
      symptomEntries,
      'symptom',
    );

    final moodFrequency = _countTextValues(
      moodEntries,
      'mood',
    );

    final medicationFrequency = _countTextValues(
      medicationEntries,
      'medicineName',
    );

    final mostFrequentSymptom =
        _findMostFrequentValue(symptomFrequency);

    final mostFrequentMood =
        _findMostFrequentValue(moodFrequency);

    final mostRecordedMedication =
        _findMostFrequentValue(medicationFrequency);

    final averageSleepHours =
        _calculateAverageSleep(sleepEntries);

    final averageWaterMillilitresPerDay =
        _calculateAverageWaterPerRecordedDay(
      waterEntries,
    );

    final healthHighlights = _buildHealthHighlights(
      symptomEntryCount: symptomEntries.length,
      mostFrequentSymptom: mostFrequentSymptom,
      mostFrequentSymptomCount:
          symptomFrequency[mostFrequentSymptom] ?? 0,
      medicationEntryCount: medicationEntries.length,
      mostRecordedMedication: mostRecordedMedication,
      mostRecordedMedicationCount:
          medicationFrequency[mostRecordedMedication] ?? 0,
      sleepEntryCount: sleepEntries.length,
      averageSleepHours: averageSleepHours,
      waterEntryCount: waterEntries.length,
      averageWaterMillilitresPerDay:
          averageWaterMillilitresPerDay,
      moodEntryCount: moodEntries.length,
      mostFrequentMood: mostFrequentMood,
      noteEntryCount: noteEntries.length,
    );

    return AppointmentSummary(
      startDate: startDate,
      endDate: endDate,
      entries: entries,
      moodEntryCount: moodEntries.length,
      symptomEntryCount: symptomEntries.length,
      medicationEntryCount: medicationEntries.length,
      sleepEntryCount: sleepEntries.length,
      waterEntryCount: waterEntries.length,
      noteEntryCount: noteEntries.length,
      mostFrequentSymptom: mostFrequentSymptom,
      mostFrequentSymptomCount:
          symptomFrequency[mostFrequentSymptom] ?? 0,
      averageSleepHours: averageSleepHours,
      averageWaterMillilitresPerDay:
          averageWaterMillilitresPerDay,
      mostFrequentMood: mostFrequentMood,
      mostRecordedMedication: mostRecordedMedication,
      mostRecordedMedicationCount:
          medicationFrequency[mostRecordedMedication] ?? 0,
      healthHighlights: healthHighlights,
    );
  }

  Map<String, int> _countTextValues(
    List<HealthEntry> entries,
    String fieldName,
  ) {
    final frequency = <String, int>{};

    for (final entry in entries) {
      final value = entry.data[fieldName];

      if (value is! String) {
        continue;
      }

      final cleanedValue = value.trim();

      if (cleanedValue.isEmpty) {
        continue;
      }

      frequency[cleanedValue] =
          (frequency[cleanedValue] ?? 0) + 1;
    }

    return frequency;
  }

  String _findMostFrequentValue(
    Map<String, int> frequency,
  ) {
    if (frequency.isEmpty) {
      return 'No data recorded';
    }

    String mostFrequentValue = frequency.keys.first;
    int highestCount = frequency.values.first;

    frequency.forEach((value, count) {
      if (count > highestCount) {
        mostFrequentValue = value;
        highestCount = count;
      }
    });

    return mostFrequentValue;
  }

  double _calculateAverageSleep(
    List<HealthEntry> entries,
  ) {
    if (entries.isEmpty) {
      return 0.0;
    }

    double totalHours = 0;
    int validEntryCount = 0;

    for (final entry in entries) {
      final value = entry.data['hours'];

      if (value is int) {
        totalHours += value.toDouble();
        validEntryCount++;
      } else if (value is double) {
        totalHours += value;
        validEntryCount++;
      } else if (value is String) {
        final parsedValue = double.tryParse(value);

        if (parsedValue != null) {
          totalHours += parsedValue;
          validEntryCount++;
        }
      }
    }

    if (validEntryCount == 0) {
      return 0.0;
    }

    return totalHours / validEntryCount;
  }

  double _calculateAverageWaterPerRecordedDay(
    List<HealthEntry> entries,
  ) {
    if (entries.isEmpty) {
      return 0.0;
    }

    final totalsByDay = <String, double>{};

    for (final entry in entries) {
      final createdAt = entry.createdAt;

      if (createdAt == null) {
        continue;
      }

      final amount = entry.data['amount'];
      final unit =
          (entry.data['unit'] as String? ?? 'ml')
              .trim()
              .toLowerCase();

      double? parsedAmount;

      if (amount is int) {
        parsedAmount = amount.toDouble();
      } else if (amount is double) {
        parsedAmount = amount;
      } else if (amount is String) {
        parsedAmount = double.tryParse(amount);
      }

      if (parsedAmount == null || parsedAmount <= 0) {
        continue;
      }

      double amountInMillilitres;

      if (unit == 'l' ||
          unit == 'litre' ||
          unit == 'litres' ||
          unit == 'liter' ||
          unit == 'liters') {
        amountInMillilitres = parsedAmount * 1000;
      } else {
        amountInMillilitres = parsedAmount;
      }

      final dayKey =
          '${createdAt.year}-'
          '${createdAt.month.toString().padLeft(2, '0')}-'
          '${createdAt.day.toString().padLeft(2, '0')}';

      totalsByDay[dayKey] =
          (totalsByDay[dayKey] ?? 0) + amountInMillilitres;
    }

    if (totalsByDay.isEmpty) {
      return 0.0;
    }

    final totalMillilitres = totalsByDay.values.fold<double>(
      0.0,
      (total, amount) => total + amount,
    );

    return totalMillilitres / totalsByDay.length;
  }

  List<String> _buildHealthHighlights({
    required int symptomEntryCount,
    required String mostFrequentSymptom,
    required int mostFrequentSymptomCount,
    required int medicationEntryCount,
    required String mostRecordedMedication,
    required int mostRecordedMedicationCount,
    required int sleepEntryCount,
    required double averageSleepHours,
    required int waterEntryCount,
    required double averageWaterMillilitresPerDay,
    required int moodEntryCount,
    required String mostFrequentMood,
    required int noteEntryCount,
  }) {
    final highlights = <String>[];

    if (symptomEntryCount > 0) {
      highlights.add(
        '$mostFrequentSymptom was the most frequently recorded '
        'symptom, with $mostFrequentSymptomCount '
        '${mostFrequentSymptomCount == 1 ? 'entry' : 'entries'}.',
      );
    }

    if (medicationEntryCount > 0) {
      highlights.add(
        '$mostRecordedMedication was the most frequently recorded '
        'medication, with $mostRecordedMedicationCount '
        '${mostRecordedMedicationCount == 1 ? 'entry' : 'entries'}.',
      );
    }

    if (sleepEntryCount > 0) {
      highlights.add(
        'Average recorded sleep was '
        '${averageSleepHours.toStringAsFixed(1)} hours.',
      );
    }

    if (waterEntryCount > 0) {
      final litres =
          averageWaterMillilitresPerDay / 1000;

      highlights.add(
        'Average recorded water intake was '
        '${litres.toStringAsFixed(1)} litres per recorded day.',
      );
    }

    if (moodEntryCount > 0) {
      highlights.add(
        '$mostFrequentMood was the most frequently recorded mood.',
      );
    }

    if (noteEntryCount > 0) {
      highlights.add(
        '$noteEntryCount health '
        '${noteEntryCount == 1 ? 'note was' : 'notes were'} '
        'recorded during the selected period.',
      );
    }

    if (highlights.isEmpty) {
      highlights.add(
        'No health records were available for the selected period.',
      );
    }

    return highlights;
  }
}