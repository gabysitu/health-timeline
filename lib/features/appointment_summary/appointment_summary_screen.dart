import '../../services/pdf_report_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/appointment_summary.dart';
import '../../services/appointment_summary_service.dart';
import '../../services/firestore_service.dart';

class AppointmentSummaryScreen extends StatefulWidget {
  const AppointmentSummaryScreen({super.key});

  @override
  State<AppointmentSummaryScreen> createState() =>
      _AppointmentSummaryScreenState();
}

class _AppointmentSummaryScreenState
    extends State<AppointmentSummaryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AppointmentSummaryService _summaryService =
      AppointmentSummaryService();
      final PdfReportService _pdfReportService = PdfReportService();

  late DateTime _startDate;
  late DateTime _endDate;

  AppointmentSummary? _summary;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    final today = DateTime.now();

    _endDate = DateTime(
      today.year,
      today.month,
      today.day,
    );

    _startDate = _endDate.subtract(
      const Duration(days: 29),
    );

    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final entries = await _firestoreService.getEntriesBetween(
        startDate: _startDate,
        endDate: _endDate,
      );

      final summary = _summaryService.buildSummary(
        startDate: _startDate,
        endDate: _endDate,
        entries: entries,
      );

      if (!mounted) return;

      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'The appointment summary could not be loaded. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectStartDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
      helpText: 'Select report start date',
    );

    if (selectedDate == null) return;

    setState(() {
      _startDate = selectedDate;
    });

    await _loadSummary();
  }

  Future<void> _selectEndDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
      helpText: 'Select report end date',
    );

    if (selectedDate == null) return;

    setState(() {
      _endDate = selectedDate;
    });

    await _loadSummary();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];

    return '$day $month ${date.year}';
  }

  String _formatDecimal(double value) {
    if (value == 0) {
      return 'No data';
    }

    return value.toStringAsFixed(1);
  }

  String _entryLabel(int count) {
    return count == 1 ? 'entry' : 'entries';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final patientName =
        user?.displayName?.trim().isNotEmpty == true
            ? user!.displayName!
            : user?.email ?? 'HealthTimeLine user';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Appointment Summary'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadSummary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            _ReportHeaderCard(
              patientName: patientName,
              startDate: _formatDate(_startDate),
              endDate: _formatDate(_endDate),
            ),

            const SizedBox(height: 20),

            const _SectionTitle(
              title: 'Report Period',
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _DateCard(
                    label: 'Start Date',
                    date: _formatDate(_startDate),
                    onTap: _selectStartDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateCard(
                    label: 'End Date',
                    date: _formatDate(_endDate),
                    onTap: _selectEndDate,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 26),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              _ErrorCard(
                message: _errorMessage!,
                onRetry: _loadSummary,
              )
            else if (_summary != null)
              _buildSummaryContent(
                context,
                _summary!,
                patientName,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryContent(
    BuildContext context,
    AppointmentSummary summary,
    String patientName,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TotalEntriesCard(
          totalEntries: summary.totalEntries,
          dayCount: summary.reportDayCount,
        ),

        const SizedBox(height: 26),

        const _SectionTitle(
          title: 'Health Overview',
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _OverviewCard(
                icon: Icons.health_and_safety_outlined,
                title: 'Symptoms',
                value: summary.symptomEntryCount.toString(),
                subtitle: _entryLabel(
                  summary.symptomEntryCount,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OverviewCard(
                icon: Icons.medication_outlined,
                title: 'Medication',
                value: summary.medicationEntryCount.toString(),
                subtitle: _entryLabel(
                  summary.medicationEntryCount,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OverviewCard(
                icon: Icons.bedtime_outlined,
                title: 'Sleep',
                value: summary.sleepEntryCount.toString(),
                subtitle: _entryLabel(
                  summary.sleepEntryCount,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _OverviewCard(
                icon: Icons.mood_outlined,
                title: 'Mood',
                value: summary.moodEntryCount.toString(),
                subtitle: _entryLabel(
                  summary.moodEntryCount,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OverviewCard(
                icon: Icons.water_drop_outlined,
                title: 'Water',
                value: summary.waterEntryCount.toString(),
                subtitle: _entryLabel(
                  summary.waterEntryCount,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OverviewCard(
                icon: Icons.note_alt_outlined,
                title: 'Notes',
                value: summary.noteEntryCount.toString(),
                subtitle: _entryLabel(
                  summary.noteEntryCount,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        const _SectionTitle(
          title: 'Health Summary',
        ),

        const SizedBox(height: 12),

        _SummaryCard(
          icon: Icons.health_and_safety_outlined,
          title: 'Most frequent symptom',
          value: summary.hasSymptoms
              ? summary.mostFrequentSymptom
              : 'No symptoms recorded',
          badge: summary.hasSymptoms
              ? '${summary.mostFrequentSymptomCount} '
                    '${_entryLabel(summary.mostFrequentSymptomCount)}'
              : null,
        ),

        const SizedBox(height: 10),

        _SummaryCard(
          icon: Icons.bedtime_outlined,
          title: 'Average sleep',
          value: summary.hasSleep
              ? '${_formatDecimal(summary.averageSleepHours)} hours'
              : 'No sleep recorded',
        ),

        const SizedBox(height: 10),

        _SummaryCard(
          icon: Icons.water_drop_outlined,
          title: 'Average water intake',
          value: summary.hasWater
              ? '${_formatDecimal(summary.averageWaterLitresPerDay)} L per day'
              : 'No water recorded',
        ),

        const SizedBox(height: 10),

        _SummaryCard(
          icon: Icons.medication_outlined,
          title: 'Most recorded medication',
          value: summary.hasMedication
              ? summary.mostRecordedMedication
              : 'No medication recorded',
          badge: summary.hasMedication
              ? '${summary.mostRecordedMedicationCount} '
                    '${_entryLabel(summary.mostRecordedMedicationCount)}'
              : null,
        ),

        const SizedBox(height: 10),

        _SummaryCard(
          icon: Icons.mood_outlined,
          title: 'Most recorded mood',
          value: summary.hasMood
              ? summary.mostFrequentMood
              : 'No mood recorded',
        ),

        const SizedBox(height: 28),

        const _SectionTitle(
          title: 'Health Highlights',
        ),

        const SizedBox(height: 12),

        _HighlightsCard(
          highlights: summary.healthHighlights,
        ),

        const SizedBox(height: 20),

        const _DisclaimerCard(),

        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.green.withValues(alpha: 0.25),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.green,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your appointment summary preview is ready.',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton.icon(
            onPressed: summary.totalEntries == 0
                ? null
                : () async {
                  try {
                    await _pdfReportService.previewAppointmentSummaryPdf(
                      summary: summary,
                      patientName: patientName,
                    );
                  } catch (e){
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to generate PDF: $e',
                        ),
                      ),
                    );
                  }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'PDF generation will be connected next.',
                        ),
                      ),
                    );
                  },
            icon: const Icon(
              Icons.picture_as_pdf_outlined,
            ),
            label: const Text(
              'Export PDF',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportHeaderCard extends StatelessWidget {
  final String patientName;
  final String startDate;
  final String endDate;

  const _ReportHeaderCard({
    required this.patientName,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary,
            child: Icon(
              Icons.person_outline,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Prepared for',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  patientName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$startDate to $endDate',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  final String label;
  final String date;
  final VoidCallback onTap;

  const _DateCard({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.22),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      date,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalEntriesCard extends StatelessWidget {
  final int totalEntries;
  final int dayCount;

  const _TotalEntriesCard({
    required this.totalEntries,
    required this.dayCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.analytics_outlined,
            size: 32,
            color: AppColors.primary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              totalEntries == 0
                  ? 'No records were found for this period.'
                  : '$totalEntries health records were analysed across '
                        '$dayCount ${dayCount == 1 ? 'day' : 'days'}.',
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const _OverviewCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 27,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? badge;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HighlightsCard extends StatelessWidget {
  final List<String> highlights;

  const _HighlightsCard({
    required this.highlights,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        children: highlights.map((highlight) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    highlight,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.25),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_outlined,
            color: Colors.orange,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'This report supports communication with healthcare '
              'professionals. It does not diagnose, treat or replace '
              'professional medical advice.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 40,
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}