import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/medicine.dart';
import '../../models/reminder_time.dart';
import '../../models/scheduled_dose.dart';
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

  // ==================== ADVANCED CUSTOM REPORT & DATA EXPORT (PDF) ====================

  /// Strip emojis and invalid glyphs that can fail standard PDF text renderers
  static String _cleanPdfText(String? input) {
    if (input == null || input.isEmpty) return '';
    return input
        .replaceAll(
          RegExp(
            r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F600}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]',
            unicode: true,
          ),
          '',
        )
        .trim();
  }

  /// Exports a customized, comprehensive medical compliance report with app branding,
  /// user-selected date range, medicine filtering, adherence analytics, and dose logs.
  Future<void> exportCustomReportPdf({
    required UserProfile? profile,
    required List<Medicine> selectedMedicines,
    required Map<String, List<ReminderTime>> remindersByMedicine,
    required DateTime startDate,
    required DateTime endDate,
    required List<ScheduledDose> dosesInRange,
    required bool includeAdherenceStats,
    required bool includePrescriptions,
    required bool includeIntakeLog,
    required bool includeDoctorNotes,
    required String languageCode,
  }) async {
    final pdf = pw.Document();

    // 1. Try to load branding logo
    pw.MemoryImage? brandLogo;
    try {
      final byteData = await rootBundle.load('assets/icons/app_brand_logo.png');
      brandLogo = pw.MemoryImage(byteData.buffer.asUint8List());
    } catch (_) {
      try {
        final byteData = await rootBundle.load('assets/icons/app_icon.png');
        brandLogo = pw.MemoryImage(byteData.buffer.asUint8List());
      } catch (_) {}
    }

    // 2. Setup robust typography with Google Fonts and fallbacks
    pw.Font? baseFont;
    pw.Font? boldFont;
    final List<pw.Font> fallbacks = [];
    try {
      baseFont = await PdfGoogleFonts.robotoRegular();
      boldFont = await PdfGoogleFonts.robotoBold();
    } catch (_) {
      baseFont = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
    }

    try {
      final bnFont = await PdfGoogleFonts.notoSansBengaliRegular();
      fallbacks.add(bnFont);
    } catch (_) {}

    final pdfTheme = pw.ThemeData.withFont(
      base: baseFont,
      bold: boldFont,
      fontFallback: fallbacks,
    );

    // 3. Filter doses by selected medicines
    final selectedMedIds = selectedMedicines.map((m) => m.id).toSet();
    final filteredDoses = dosesInRange
        .where((d) => selectedMedIds.contains(d.medicine.id))
        .toList();

    // Sort doses chronologically
    filteredDoses.sort((a, b) => a.doseDateTime.compareTo(b.doseDateTime));

    // 4. Calculate adherence metrics
    final totalScheduled = filteredDoses.length;
    final takenCount = filteredDoses.where((d) => d.isTaken).length;
    final skippedCount = filteredDoses.where((d) => d.isSkipped).length;
    final missedCount = filteredDoses.where((d) => d.isMissed).length;
    final totalCompleted = takenCount + skippedCount + missedCount;
    final adherenceRate = totalCompleted > 0
        ? ((takenCount / totalCompleted) * 100).round()
        : (takenCount > 0 ? 100 : 0);

    // 5. Palettes
    final royalViolet = PdfColor.fromHex('#7C3AED');
    final darkNavy = PdfColor.fromHex('#0F172A');
    final emeraldGreen = PdfColor.fromHex('#059669');
    final amberColor = PdfColor.fromHex('#D97706');
    final roseColor = PdfColor.fromHex('#E11D48');
    final slateCard = PdfColor.fromHex('#F8FAFC');
    final borderGrey = PdfColor.fromHex('#E2E8F0');
    final textMuted = PdfColor.fromHex('#64748B');

    final patientName = _cleanPdfText(profile?.name) != ''
        ? _cleanPdfText(profile?.name)
        : 'Patient Record';
    final patientRelation = _cleanPdfText(profile?.relation) != ''
        ? _cleanPdfText(profile?.relation)
        : 'Myself';
    final ageText = profile?.age != null ? '${profile!.age} Yrs' : 'N/A';
    final dateRangeStr =
        '${DateFormat('dd MMM yyyy').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}';
    final daysCount = endDate.difference(startDate).inDays + 1;

    pdf.addPage(
      pw.MultiPage(
        theme: pdfTheme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(26),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 8),
            margin: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'MediRemind • Health Compliance & Intake Log',
                  style: pw.TextStyle(fontSize: 8.5, color: textMuted, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  '$patientName • $dateRangeStr',
                  style: pw.TextStyle(fontSize: 8.5, color: textMuted),
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            margin: const pw.EdgeInsets.only(top: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'MediRemind Healthcare Platform • Verified Patient Medical Log',
                  style: pw.TextStyle(fontSize: 7.5, color: textMuted),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 8, color: textMuted, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // ==================== APP BRANDING & HEADER BANNER ====================
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: pw.BoxDecoration(
                color: royalViolet,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (brandLogo != null) ...[
                    pw.Container(
                      width: 44,
                      height: 44,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Image(brandLogo, fit: pw.BoxFit.contain),
                    ),
                    pw.SizedBox(width: 12),
                  ],
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'MediRemind • Health Compliance Report',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Verified Digital Medication Adherence & Clinical Intake Log',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey200),
                        ),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(5),
                        ),
                        child: pw.Text(
                          'OFFICIAL REPORT',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: royalViolet,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 12),

            // ==================== PATIENT & FILTER INFO BOX ====================
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: slateCard,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: borderGrey, width: 1),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 5,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          children: [
                            pw.Text('Patient Name: ', style: pw.TextStyle(fontSize: 9, color: textMuted)),
                            pw.Text(
                              patientName,
                              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: darkNavy),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 3),
                        pw.Row(
                          children: [
                            pw.Text('Relation/Profile: ', style: pw.TextStyle(fontSize: 9, color: textMuted)),
                            pw.Text(patientRelation, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(width: 14),
                            pw.Text('Age: ', style: pw.TextStyle(fontSize: 9, color: textMuted)),
                            pw.Text(ageText, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.Container(width: 1, height: 32, color: borderGrey),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    flex: 6,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          children: [
                            pw.Text('Period Scope: ', style: pw.TextStyle(fontSize: 9, color: textMuted)),
                            pw.Text(
                              '$dateRangeStr ($daysCount Days)',
                              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: royalViolet),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 3),
                        pw.Row(
                          children: [
                            pw.Text('Medications: ', style: pw.TextStyle(fontSize: 9, color: textMuted)),
                            pw.Text(
                              '${selectedMedicines.length} Selected (of ${selectedMedicines.length} in scope)',
                              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: darkNavy),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ==================== ADHERENCE KPI SUMMARY ====================
            if (includeAdherenceStats) ...[
              pw.SizedBox(height: 12),
              pw.Row(
                children: [
                  // KPI 1: Adherence Rate
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: pw.BoxDecoration(
                        color: adherenceRate >= 80
                            ? PdfColor.fromHex('#ECFDF5')
                            : (adherenceRate >= 50 ? PdfColor.fromHex('#FFFBEB') : PdfColor.fromHex('#FFF1F2')),
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(
                          color: adherenceRate >= 80
                              ? emeraldGreen
                              : (adherenceRate >= 50 ? amberColor : roseColor),
                          width: 1,
                        ),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            '$adherenceRate%',
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: adherenceRate >= 80
                                  ? emeraldGreen
                                  : (adherenceRate >= 50 ? amberColor : roseColor),
                            ),
                          ),
                          pw.SizedBox(height: 1),
                          pw.Text(
                            'ADHERENCE RATE',
                            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: darkNavy),
                          ),
                          pw.Text(
                            adherenceRate >= 80 ? 'Optimal Compliance' : (adherenceRate >= 50 ? 'Moderate' : 'Low'),
                            style: pw.TextStyle(fontSize: 7, color: textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),

                  // KPI 2: Total Scheduled
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: pw.BoxDecoration(
                        color: slateCard,
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(color: borderGrey, width: 1),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            '$totalScheduled',
                            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: darkNavy),
                          ),
                          pw.SizedBox(height: 1),
                          pw.Text(
                            'DOSES SCHEDULED',
                            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: darkNavy),
                          ),
                          pw.Text('in selected range', style: pw.TextStyle(fontSize: 7, color: textMuted)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),

                  // KPI 3: Taken Doses
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#ECFDF5'),
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(color: emeraldGreen.flatten(), width: 1),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            '$takenCount',
                            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: emeraldGreen),
                          ),
                          pw.SizedBox(height: 1),
                          pw.Text(
                            'DOSES TAKEN',
                            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: darkNavy),
                          ),
                          pw.Text('Confirmed taken', style: pw.TextStyle(fontSize: 7, color: textMuted)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),

                  // KPI 4: Missed or Skipped
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: pw.BoxDecoration(
                        color: (missedCount + skippedCount) > 0 ? PdfColor.fromHex('#FFF1F2') : slateCard,
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(
                          color: (missedCount + skippedCount) > 0 ? roseColor : borderGrey,
                          width: 1,
                        ),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            '${missedCount + skippedCount}',
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: (missedCount + skippedCount) > 0 ? roseColor : textMuted,
                            ),
                          ),
                          pw.SizedBox(height: 1),
                          pw.Text(
                            'MISSED / SKIPPED',
                            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: darkNavy),
                          ),
                          pw.Text('$missedCount missed, $skippedCount skip', style: pw.TextStyle(fontSize: 7, color: textMuted)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // ==================== SECTION 1: PRESCRIPTION REGIMEN ====================
            if (includePrescriptions && selectedMedicines.isNotEmpty) ...[
              pw.SizedBox(height: 14),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#EDE9FE'),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '1. Active Medication Regimen & Schedule',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: royalViolet),
                    ),
                    pw.Text(
                      '${selectedMedicines.length} item(s)',
                      style: pw.TextStyle(fontSize: 8.5, color: textMuted),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: borderGrey, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(2.5),
                  3: pw.FlexColumnWidth(3),
                  4: pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: royalViolet),
                    children: [
                      _buildHeaderCell('Medicine Name'),
                      _buildHeaderCell('Form & Dosage'),
                      _buildHeaderCell('Meal Instruction'),
                      _buildHeaderCell('Scheduled Times'),
                      _buildHeaderCell('Remaining Stock'),
                    ],
                  ),
                  ...selectedMedicines.asMap().entries.map((entry) {
                    final index = entry.key;
                    final med = entry.value;
                    final rems = remindersByMedicine[med.id] ?? [];
                    final timesStr = rems.map((r) => r.formattedTime).join(', ');
                    final isEven = index % 2 == 0;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : slateCard),
                      children: [
                        _buildDataCell(_cleanPdfText(med.name), isBold: true),
                        _buildDataCell('${med.type.label} • ${_cleanPdfText(med.dosage)}'),
                        _buildDataCell(_cleanPdfText(med.instruction.title)),
                        _buildDataCell(timesStr.isEmpty ? 'As needed' : timesStr),
                        _buildDataCell(
                          '${med.currentStock} units${med.isLowStock ? ' [LOW]' : ''}',
                          textColor: med.isLowStock ? roseColor : darkNavy,
                          isBold: med.isLowStock,
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],

            // ==================== SECTION 2: DAILY INTAKE HISTORY LOG ====================
            if (includeIntakeLog) ...[
              pw.SizedBox(height: 14),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#EDE9FE'),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '2. Daily Dose Intake History Log',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: royalViolet),
                    ),
                    pw.Text(
                      '${filteredDoses.length} recorded scheduled event(s)',
                      style: pw.TextStyle(fontSize: 8.5, color: textMuted),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),
              if (filteredDoses.isEmpty) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: slateCard,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: borderGrey, width: 0.5),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'No doses recorded for the selected medications within this date range.',
                      style: pw.TextStyle(fontSize: 9, color: textMuted),
                    ),
                  ),
                ),
              ] else ...[
                pw.Table(
                  border: pw.TableBorder.all(color: borderGrey, width: 0.5),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(2.2),
                    1: pw.FlexColumnWidth(1.8),
                    2: pw.FlexColumnWidth(3.5),
                    3: pw.FlexColumnWidth(2.2),
                    4: pw.FlexColumnWidth(2.3),
                  },
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: darkNavy),
                      children: [
                        _buildHeaderCell('Date'),
                        _buildHeaderCell('Scheduled'),
                        _buildHeaderCell('Medicine & Dosage'),
                        _buildHeaderCell('Intake Status'),
                        _buildHeaderCell('Recorded At'),
                      ],
                    ),
                    ...filteredDoses.asMap().entries.map((entry) {
                      final index = entry.key;
                      final dose = entry.value;
                      final isEven = index % 2 == 0;
                      final dateStr = DateFormat('dd MMM yyyy').format(dose.scheduledDate);
                      final timeStr = dose.reminder.formattedTime;
                      final medStr = '${_cleanPdfText(dose.medicine.name)} (${_cleanPdfText(dose.medicine.dosage)})';

                      String statusLabel;
                      PdfColor statusColor;
                      if (dose.isTaken) {
                        statusLabel = 'TAKEN';
                        statusColor = emeraldGreen;
                      } else if (dose.isSkipped) {
                        statusLabel = 'SKIPPED';
                        statusColor = textMuted;
                      } else if (dose.isMissed) {
                        statusLabel = 'MISSED';
                        statusColor = roseColor;
                      } else {
                        statusLabel = 'PENDING';
                        statusColor = amberColor;
                      }

                      final recordTime = dose.record?.recordedAt != null
                          ? DateFormat('hh:mm a').format(dose.record!.recordedAt)
                          : '-';

                      return pw.TableRow(
                        decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : slateCard),
                        children: [
                          _buildDataCell(dateStr),
                          _buildDataCell(timeStr, isBold: true),
                          _buildDataCell(medStr),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                            child: pw.Text(
                              statusLabel,
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                          _buildDataCell(recordTime),
                        ],
                      );
                    }),
                  ],
                ),
              ],
            ],

            // ==================== SECTION 3: DOCTOR NOTES & SIGNATURE ====================
            if (includeDoctorNotes) ...[
              pw.SizedBox(height: 14),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: borderGrey, width: 1),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Physician Consultation Remarks & Prescription Adjustments:',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: darkNavy),
                    ),
                    pw.SizedBox(height: 28),
                    pw.Divider(thickness: 0.5, color: borderGrey),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Doctor Signature & Reg No: _____________________________', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('Next Appointment: _____ / _____ / 20___', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ];
        },
      ),
    );

    final cleanFileName =
        'MediRemind_Health_Report_${patientName.replaceAll(RegExp(r'\s+'), '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: cleanFileName,
    );
  }

  static pw.Widget _buildHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _buildDataCell(String text, {bool isBold = false, PdfColor? textColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor ?? PdfColor.fromHex('#1E293B'),
        ),
      ),
    );
  }
}
