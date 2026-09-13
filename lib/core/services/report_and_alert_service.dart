import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/medicine.dart';
import '../../models/reminder_time.dart';
import '../../models/user_profile.dart';

class ReportAndAlertService {
  static final ReportAndAlertService instance = ReportAndAlertService._();
  ReportAndAlertService._();

  // ==================== CAREGIVER ALERTS (WhatsApp & SMS) ====================

  /// Send an immediate WhatsApp alert to a caregiver for an overdue medication
  Future<bool> sendCaregiverWhatsAppAlert({
    String? phone,
    required String memberName,
    required String medicineName,
    required String dosage,
    required String scheduledTime,
  }) async {
    final message = '⚠️ *MediRemind Care Alert* ⚠️\n\n'
        'Hello! *$memberName* has not yet taken their scheduled medication:\n'
        '💊 *Medicine:* $medicineName ($dosage)\n'
        '⏰ *Scheduled Time:* $scheduledTime\n\n'
        'Please check in with them to ensure timely intake.';

    final encoded = Uri.encodeComponent(message);
    final cleanPhone = phone?.replaceAll(RegExp(r'[^0-9+]'), '') ?? '';
    final urlString = cleanPhone.isNotEmpty
        ? 'https://wa.me/$cleanPhone?text=$encoded'
        : 'https://wa.me/?text=$encoded';

    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Send an SMS alert to a caregiver
  Future<bool> sendCaregiverSmsAlert({
    String? phone,
    required String memberName,
    required String medicineName,
    required String scheduledTime,
  }) async {
    final message = 'MediRemind Alert: $memberName missed their $scheduledTime dose of $medicineName. Please check in.';
    final cleanPhone = phone?.replaceAll(RegExp(r'[^0-9+]'), '') ?? '';
    final uri = Uri(
      scheme: 'sms',
      path: cleanPhone,
      queryParameters: {'body': message},
    );

    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    }
    return false;
  }

  // ==================== DOCTOR SUMMARY PDF REPORT ====================

  /// Generate and preview/share a 1-page compliance PDF report for doctor consultations
  Future<void> exportDoctorReportPdf({
    required UserProfile? profile,
    required List<Medicine> medicines,
    required Map<String, List<ReminderTime>> remindersByMedicine,
    required double adherenceRate,
    required int totalDosesTaken,
    required int totalDosesScheduled,
  }) async {
    final pdf = pw.Document();
    final patientName = profile?.name ?? 'Family (Combined)';
    final relation = profile?.relation ?? 'All Members';
    final dateStr = DateFormat('MMMM d, yyyy').format(DateTime.now());
    final adherencePercent = (adherenceRate * 100).toInt();

    // Palette for PDF (Royal Teal & Mint Green)
    final primaryTeal = PdfColor.fromHex('#0D9488');
    final mintGreen = PdfColor.fromHex('#10B981');
    final darkNavy = PdfColor.fromHex('#1A1E1C');
    final lightBg = PdfColor.fromHex('#FCFBF7');
    final cardBorder = PdfColor.fromHex('#E6F4EA');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Top Header Banner
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: primaryTeal,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'MediRemind • Health Compliance Report',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Verified Digital Medication Adherence Summary for Doctor Consultation',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(
                      dateStr,
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // Patient Info & Adherence Gauge
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(14),
                      decoration: pw.BoxDecoration(
                        color: lightBg,
                        border: pw.Border.all(color: cardBorder, width: 1.5),
                        borderRadius: pw.BorderRadius.circular(10),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Patient: $patientName',
                            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: darkNavy),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text('Profile / Relation: $relation', style: const pw.TextStyle(fontSize: 11)),
                          pw.SizedBox(height: 4),
                          pw.Text('Active Medications: ${medicines.length} items', style: const pw.TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(14),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#ECFDF5'),
                        border: pw.Border.all(color: mintGreen, width: 1.5),
                        borderRadius: pw.BorderRadius.circular(10),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            '$adherencePercent%',
                            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: mintGreen),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Overall Adherence',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: mintGreen),
                          ),
                          pw.Text(
                            '$totalDosesTaken / $totalDosesScheduled doses recorded',
                            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Medication Regimen Table Header
              pw.Text(
                'Active Prescription Regimen',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: darkNavy),
              ),
              pw.SizedBox(height: 8),

              // Table
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: primaryTeal),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                headers: ['Medicine Name', 'Strength / Dosage', 'Form', 'Timing Instruction', 'Scheduled Times', 'Stock Left'],
                data: medicines.map((med) {
                  final rems = remindersByMedicine[med.id] ?? [];
                  final timesStr = rems.map((r) => r.formattedTime).join(', ');
                  return [
                    med.name,
                    med.dosage,
                    med.type.label,
                    med.instruction.title,
                    timesStr.isEmpty ? 'As Needed' : timesStr,
                    '${med.currentStock} units',
                  ];
                }).toList(),
              ),

              pw.SizedBox(height: 20),

              // Doctor Notes Box
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, width: 1),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Physician Consultation Notes & Adjustments:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 40), // Whitespace for doctor's pen notes
                    pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Doctor Signature: _______________________', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('Next Visit Date: _____ / _____ / ________', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Footer
              pw.Divider(color: cardBorder, thickness: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('MediRemind • Android 10-15 Health Platform', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  pw.Text('Page 1 of 1 • Patient Confidential', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Trigger native print/share/save sheet
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'MediRemind_Doctor_Report_${patientName.replaceAll(' ', '_')}.pdf',
    );
  }
}
