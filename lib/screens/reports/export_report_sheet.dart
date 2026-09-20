import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/services/report_and_alert_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/reminder_time.dart';
import '../../models/scheduled_dose.dart';
import '../../providers/language_provider.dart';
import '../../providers/medicine_provider.dart';

class ExportReportSheet extends StatefulWidget {
  const ExportReportSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ExportReportSheet(),
    );
  }

  @override
  State<ExportReportSheet> createState() => _ExportReportSheetState();
}

class _ExportReportSheetState extends State<ExportReportSheet> {
  // Preset: '7d', '14d', 'month', '30d', 'custom'
  String _selectedPreset = '7d';
  late DateTime _startDate;
  late DateTime _endDate;

  final Set<String> _selectedMedicineIds = {};
  bool _includeAdherence = true;
  bool _includePrescriptions = true;
  bool _includeIntakeLog = true;
  bool _includeDoctorNotes = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _endDate = DateTime(now.year, now.month, now.day);
    _startDate = _endDate.subtract(const Duration(days: 6));

    // Initially select all medicines
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MedicineProvider>();
      setState(() {
        _selectedMedicineIds.addAll(provider.medicines.map((m) => m.id));
      });
    });
  }

  void _applyPreset(String preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() {
      _selectedPreset = preset;
      if (preset == '7d') {
        _endDate = today;
        _startDate = today.subtract(const Duration(days: 6));
      } else if (preset == '14d') {
        _endDate = today;
        _startDate = today.subtract(const Duration(days: 13));
      } else if (preset == 'month') {
        _startDate = DateTime(today.year, today.month, 1);
        _endDate = today;
      } else if (preset == '30d') {
        _endDate = today;
        _startDate = today.subtract(const Duration(days: 29));
      }
    });
  }

  Future<void> _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime(2035),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF7C3AED),
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedPreset = 'custom';
        _startDate = DateTime(picked.start.year, picked.start.month, picked.start.day);
        _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day);
      });
    }
  }

  Future<void> _handleExport() async {
    final provider = context.read<MedicineProvider>();
    final s = context.read<LanguageProvider>().strings;

    if (_selectedMedicineIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.noMedsSelectedWarning),
          backgroundColor: AppColors.accentRose,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      // Gather all scheduled doses across the selected date range
      final List<ScheduledDose> allDosesInRange = [];
      final daysCount = _endDate.difference(_startDate).inDays + 1;

      for (int i = 0; i < daysCount; i++) {
        final day = _startDate.add(Duration(days: i));
        final doses = provider.getDosesForDate(day);
        allDosesInRange.addAll(doses);
      }

      // Filter selected medicines
      final selectedMeds = provider.medicines
          .where((m) => _selectedMedicineIds.contains(m.id))
          .toList();

      final remindersByMed = <String, List<ReminderTime>>{};
      for (final med in provider.medicines) {
        remindersByMed[med.id] = provider.getRemindersForMedicine(med.id);
      }

      await ReportAndAlertService.instance.exportCustomReportPdf(
        profile: provider.activeProfile,
        selectedMedicines: selectedMeds,
        remindersByMedicine: remindersByMed,
        startDate: _startDate,
        endDate: _endDate,
        dosesInRange: allDosesInRange,
        includeAdherenceStats: _includeAdherence,
        includePrescriptions: _includePrescriptions,
        includeIntakeLog: _includeIntakeLog,
        includeDoctorNotes: _includeDoctorNotes,
        languageCode: s.code,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: AppColors.accentRose,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<MedicineProvider>();
    final s = context.watch<LanguageProvider>().strings;
    final medicines = provider.medicines;

    final allSelected = medicines.isNotEmpty && _selectedMedicineIds.length == medicines.length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 25,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.exportOptionsTitle,
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        s.exportReportSub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Scrollable filter options
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              children: [
                // ==================== 1. DATE RANGE SECTION ====================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.dateRangeFilter,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${_endDate.difference(_startDate).inDays + 1} days',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Preset Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPresetChip('7d', s.code == 'bn' ? 'গত ৭ দিন' : 'Last 7 Days'),
                    _buildPresetChip('14d', s.code == 'bn' ? 'গত ১৪ দিন' : 'Last 14 Days'),
                    _buildPresetChip('month', s.code == 'bn' ? 'এই মাস' : 'This Month'),
                    _buildPresetChip('30d', s.code == 'bn' ? 'গত ৩০ দিন' : 'Last 30 Days'),
                    _buildPresetChip('custom', s.code == 'bn' ? 'কাস্টম রেঞ্জ' : 'Custom Range', isCustom: true),
                  ],
                ),
                const SizedBox(height: 10),

                // Date Display & Picker Box
                InkWell(
                  onTap: _pickCustomDateRange,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.date_range_rounded, size: 18, color: Color(0xFF7C3AED)),
                            const SizedBox(width: 8),
                            Text(
                              '${DateFormat('dd MMM yyyy').format(_startDate)}  —  ${DateFormat('dd MMM yyyy').format(_endDate)}',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const Icon(Icons.edit_calendar_rounded, size: 18, color: Color(0xFF7C3AED)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ==================== 2. MEDICINE FILTER SECTION ====================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.medicineFilterTitle,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (allSelected) {
                            _selectedMedicineIds.clear();
                          } else {
                            _selectedMedicineIds.addAll(medicines.map((m) => m.id));
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          allSelected ? (s.code == 'bn' ? 'সব বাতিল' : 'Deselect All') : s.selectAllMeds,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                if (medicines.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        s.code == 'bn' ? 'কোনো সক্রিয় ওষুধ নেই' : 'No active medicines available',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: medicines.map((med) {
                        final isSelected = _selectedMedicineIds.contains(med.id);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedMedicineIds.add(med.id);
                              } else {
                                _selectedMedicineIds.remove(med.id);
                              }
                            });
                          },
                          dense: true,
                          activeColor: const Color(0xFF7C3AED),
                          checkColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          title: Text(
                            med.name,
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            '${med.type.label} • ${med.dosage} (${med.currentStock} units left)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                            ),
                          ),
                          secondary: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Color(med.colorValue).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.medication_rounded,
                              size: 18,
                              color: Color(med.colorValue),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                const SizedBox(height: 18),

                // ==================== 3. REPORT SECTIONS ====================
                Text(
                  s.includeSections,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),

                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildSectionToggle(
                        title: s.secAdherenceStats,
                        icon: Icons.pie_chart_outline_rounded,
                        value: _includeAdherence,
                        onChanged: (v) => setState(() => _includeAdherence = v),
                        isDark: isDark,
                      ),
                      const Divider(height: 1, indent: 46),
                      _buildSectionToggle(
                        title: s.secPrescriptions,
                        icon: Icons.list_alt_rounded,
                        value: _includePrescriptions,
                        onChanged: (v) => setState(() => _includePrescriptions = v),
                        isDark: isDark,
                      ),
                      const Divider(height: 1, indent: 46),
                      _buildSectionToggle(
                        title: s.secIntakeLog,
                        icon: Icons.history_rounded,
                        value: _includeIntakeLog,
                        onChanged: (v) => setState(() => _includeIntakeLog = v),
                        isDark: isDark,
                      ),
                      const Divider(height: 1, indent: 46),
                      _buildSectionToggle(
                        title: s.secDoctorNotes,
                        icon: Icons.edit_note_rounded,
                        value: _includeDoctorNotes,
                        onChanged: (v) => setState(() => _includeDoctorNotes = v),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),

          // Bottom sticky export button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _handleExport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isGenerating
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            s.generatingPdfPrompt,
                            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            s.generateAndSharePdf,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String key, String label, {bool isCustom = false}) {
    final isSelected = _selectedPreset == key;
    return ChoiceChip(
      selected: isSelected,
      label: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          color: isSelected ? Colors.white : null,
        ),
      ),
      selectedColor: const Color(0xFF7C3AED),
      backgroundColor: Colors.transparent,
      side: BorderSide(
        color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFCBD5E1),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (_) {
        if (isCustom) {
          _pickCustomDateRange();
        } else {
          _applyPreset(key);
        }
      },
    );
  }

  Widget _buildSectionToggle({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      dense: true,
      activeTrackColor: const Color(0xFF7C3AED),
      activeThumbColor: Colors.white,
      secondary: Icon(icon, size: 18, color: const Color(0xFF7C3AED)),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }
}
