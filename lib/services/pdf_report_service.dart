import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/appointment_summary.dart';

class PdfReportService {
  Future<Uint8List> generateAppointmentSummaryPdf({
    required AppointmentSummary summary,
    required String patientName,
  }) async {
    final document = pw.Document(
      title: 'HealthTimeLine Appointment Summary',
      author: 'HealthTimeLine',
      subject: 'Health appointment summary',
      creator: 'HealthTimeLine',
    );

    final generatedDate = DateTime.now();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (context) {
          return _buildHeader();
        },
        footer: (context) {
          return _buildFooter(
            pageNumber: context.pageNumber,
            totalPages: context.pagesCount,
          );
        },
        build: (context) {
          return [
            pw.SizedBox(height: 12),

            _buildReportInformation(
              patientName: patientName,
              startDate: summary.startDate,
              endDate: summary.endDate,
              generatedDate: generatedDate,
              totalEntries: summary.totalEntries,
              reportDayCount: summary.reportDayCount,
            ),

            pw.SizedBox(height: 24),

            _buildSectionTitle('Health Overview'),

            pw.SizedBox(height: 10),

            _buildOverviewTable(summary),

            pw.SizedBox(height: 24),

            _buildSectionTitle('Health Summary'),

            pw.SizedBox(height: 10),

            _buildSummaryTable(summary),

            pw.SizedBox(height: 24),

            _buildSectionTitle('Health Highlights'),

            pw.SizedBox(height: 10),

            _buildHighlights(summary.healthHighlights),

            if (summary.noteEntryCount > 0) ...[
              pw.SizedBox(height: 24),
              _buildSectionTitle('Recorded Notes'),
              pw.SizedBox(height: 10),
              _buildNotes(summary),
            ],

            pw.SizedBox(height: 24),

            _buildDisclaimer(),
          ];
        },
      ),
    );

    return document.save();
  }

  Future<void> shareAppointmentSummaryPdf({
    required AppointmentSummary summary,
    required String patientName,
  }) async {
    final pdfBytes = await generateAppointmentSummaryPdf(
      summary: summary,
      patientName: patientName,
    );

    final safePatientName = patientName
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    final fileName =
        'HealthTimeLine_Appointment_Summary_$safePatientName.pdf';

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: fileName,
    );
  }

  Future<void> previewAppointmentSummaryPdf({
    required AppointmentSummary summary,
    required String patientName,
  }) async {
    final pdfBytes = await generateAppointmentSummaryPdf(
      summary: summary,
      patientName: patientName,
    );

    await Printing.layoutPdf(
      name: 'HealthTimeLine Appointment Summary',
      onLayout: (_) async => pdfBytes,
    );
  }

  pw.Widget _buildHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(
        bottom: 12,
      ),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColors.blue300,
            width: 1.5,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'HealthTimeLine',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'Appointment Summary',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Container(
            width: 38,
            height: 38,
            decoration: pw.BoxDecoration(
              color: PdfColors.blue100,
              borderRadius: pw.BorderRadius.circular(19),
            ),
            alignment: pw.Alignment.center,
            child: pw.Text(
              '+',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter({
    required int pageNumber,
    required int totalPages,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(
        top: 10,
      ),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(
            color: PdfColors.grey300,
            width: 0.8,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by HealthTimeLine',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            'Page $pageNumber of $totalPages',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildReportInformation({
    required String patientName,
    required DateTime startDate,
    required DateTime endDate,
    required DateTime generatedDate,
    required int totalEntries,
    required int reportDayCount,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(
          color: PdfColors.blue200,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildInformationRow(
            label: 'Prepared for',
            value: patientName,
          ),
          pw.SizedBox(height: 8),
          _buildInformationRow(
            label: 'Report period',
            value:
                '${_formatDate(startDate)} to ${_formatDate(endDate)}',
          ),
          pw.SizedBox(height: 8),
          _buildInformationRow(
            label: 'Generated',
            value: _formatDate(generatedDate),
          ),
          pw.SizedBox(height: 8),
          _buildInformationRow(
            label: 'Records analysed',
            value:
                '$totalEntries ${totalEntries == 1 ? 'entry' : 'entries'} '
                'across $reportDayCount '
                '${reportDayCount == 1 ? 'day' : 'days'}',
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInformationRow({
    required String label,
    required String value,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 110,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey900,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title.toUpperCase(),
      style: pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blue800,
        letterSpacing: 0.6,
      ),
    );
  }

  pw.Widget _buildOverviewTable(
    AppointmentSummary summary,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.grey300,
        width: 0.7,
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(1),
      },
      children: [
        _buildTableHeaderRow(
          firstColumn: 'Category',
          secondColumn: 'Entries',
        ),
        _buildOverviewRow(
          label: 'Symptoms',
          value: summary.symptomEntryCount.toString(),
        ),
        _buildOverviewRow(
          label: 'Medication',
          value: summary.medicationEntryCount.toString(),
        ),
        _buildOverviewRow(
          label: 'Sleep',
          value: summary.sleepEntryCount.toString(),
        ),
        _buildOverviewRow(
          label: 'Mood',
          value: summary.moodEntryCount.toString(),
        ),
        _buildOverviewRow(
          label: 'Water',
          value: summary.waterEntryCount.toString(),
        ),
        _buildOverviewRow(
          label: 'Notes',
          value: summary.noteEntryCount.toString(),
        ),
      ],
    );
  }

  pw.TableRow _buildTableHeaderRow({
    required String firstColumn,
    required String secondColumn,
  }) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(
        color: PdfColors.blue100,
      ),
      children: [
        _buildTableCell(
          firstColumn,
          isBold: true,
        ),
        _buildTableCell(
          secondColumn,
          isBold: true,
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  pw.TableRow _buildOverviewRow({
    required String label,
    required String value,
  }) {
    return pw.TableRow(
      children: [
        _buildTableCell(label),
        _buildTableCell(
          value,
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  pw.Widget _buildSummaryTable(
    AppointmentSummary summary,
  ) {
    final rows = <pw.TableRow>[
      _buildTableHeaderRow(
        firstColumn: 'Health measure',
        secondColumn: 'Summary',
      ),
    ];

    rows.add(
      _buildSummaryRow(
        label: 'Most frequent symptom',
        value: summary.hasSymptoms
            ? '${summary.mostFrequentSymptom} '
                '(${summary.mostFrequentSymptomCount} '
                '${summary.mostFrequentSymptomCount == 1 ? 'entry' : 'entries'})'
            : 'No symptoms recorded',
      ),
    );

    rows.add(
      _buildSummaryRow(
        label: 'Average sleep',
        value: summary.hasSleep
            ? '${summary.averageSleepHours.toStringAsFixed(1)} hours'
            : 'No sleep recorded',
      ),
    );

    rows.add(
      _buildSummaryRow(
        label: 'Average water intake',
        value: summary.hasWater
            ? '${summary.averageWaterLitresPerDay.toStringAsFixed(1)} '
                'litres per recorded day'
            : 'No water recorded',
      ),
    );

    rows.add(
      _buildSummaryRow(
        label: 'Most recorded medication',
        value: summary.hasMedication
            ? '${summary.mostRecordedMedication} '
                '(${summary.mostRecordedMedicationCount} '
                '${summary.mostRecordedMedicationCount == 1 ? 'entry' : 'entries'})'
            : 'No medication recorded',
      ),
    );

    rows.add(
      _buildSummaryRow(
        label: 'Most recorded mood',
        value: summary.hasMood
            ? summary.mostFrequentMood
            : 'No mood recorded',
      ),
    );

    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.grey300,
        width: 0.7,
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(3),
      },
      children: rows,
    );
  }

  pw.TableRow _buildSummaryRow({
    required String label,
    required String value,
  }) {
    return pw.TableRow(
      children: [
        _buildTableCell(
          label,
          isBold: true,
        ),
        _buildTableCell(value),
      ],
    );
  }

  pw.Widget _buildTableCell(
    String text, {
    bool isBold = false,
    pw.TextAlign textAlign = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      child: pw.Text(
        text,
        textAlign: textAlign,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight:
              isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.grey900,
        ),
      ),
    );
  }

  pw.Widget _buildHighlights(
    List<String> highlights,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: PdfColors.blue200,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: highlights.map((highlight) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(
              bottom: 9,
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '•',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue700,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(
                    highlight,
                    style: const pw.TextStyle(
                      fontSize: 10,
                      lineSpacing: 3,
                      color: PdfColors.grey900,
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

  pw.Widget _buildNotes(
    AppointmentSummary summary,
  ) {
    final noteEntries = summary.entries
        .where((entry) => entry.type == 'Note')
        .toList();

    return pw.Column(
      children: noteEntries.map((entry) {
        final title =
            (entry.data['title'] as String? ?? 'Health note').trim();

        final notes =
            (entry.data['notes'] as String? ?? '').trim();

        return pw.Container(
          width: double.infinity,
          margin: const pw.EdgeInsets.only(
            bottom: 10,
          ),
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
              color: PdfColors.grey300,
            ),
            borderRadius: pw.BorderRadius.circular(7),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title.isEmpty ? 'Health note' : title,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                ),
              ),
              if (entry.createdAt != null) ...[
                pw.SizedBox(height: 3),
                pw.Text(
                  _formatDate(entry.createdAt!),
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
              if (notes.isNotEmpty) ...[
                pw.SizedBox(height: 7),
                pw.Text(
                  notes,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    lineSpacing: 3,
                    color: PdfColors.grey800,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _buildDisclaimer() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.orange50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: PdfColors.orange200,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Important information',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.orange900,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'This report is intended to support communication between '
            'patients and healthcare professionals. It is based on '
            'information entered by the user and is not intended to '
            'diagnose, treat or replace professional medical advice.',
            style: const pw.TextStyle(
              fontSize: 9,
              lineSpacing: 3,
              color: PdfColors.grey800,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}