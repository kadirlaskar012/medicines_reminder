import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../models/medicine.dart';
import '../../models/reminder_time.dart';
import '../../models/scheduled_dose.dart';
import '../../providers/language_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../widgets/medicine_visual.dart';
import 'export_report_sheet.dart';

class ReportsAnalyticsScreen extends StatefulWidget {
  const ReportsAnalyticsScreen({super.key});

  @override
  State<ReportsAnalyticsScreen> createState() => _ReportsAnalyticsScreenState();
}

class _ReportsAnalyticsScreenState extends State<ReportsAnalyticsScreen> {
  String _selectedPeriod = 'Weekly'; // Weekly, Monthly, Yearly
  DateTime _anchorDate = DateTime.now();
  int? _selectedBarIndex;
  DateTime _selectedDateForDetail = DateTime.now();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateForDetail = now;
    final startOfWeek = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    _selectedBarIndex = now.difference(startOfWeek).inDays.clamp(0, 6);
  }

  void _previousPeriod() {
    setState(() {
      _selectedBarIndex = null;
      if (_selectedPeriod == 'Weekly') {
        _anchorDate = _anchorDate.subtract(const Duration(days: 7));
        _selectedDateForDetail = _selectedDateForDetail.subtract(const Duration(days: 7));
        final startOfWeek = DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day - (_anchorDate.weekday - 1));
        _selectedBarIndex = _selectedDateForDetail.difference(startOfWeek).inDays.clamp(0, 6);
      } else if (_selectedPeriod == 'Monthly') {
        _anchorDate = DateTime(_anchorDate.year, _anchorDate.month - 1, 1);
        _selectedDateForDetail = DateTime(_anchorDate.year, _anchorDate.month, 1);
      } else {
        _anchorDate = DateTime(_anchorDate.year - 1, 1, 1);
        _selectedDateForDetail = DateTime(_anchorDate.year, 1, 1);
      }
    });
  }

  bool _canGoNext() {
    final now = DateTime.now();
    if (_selectedPeriod == 'Weekly') {
      final startOfWeek = DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day - (_anchorDate.weekday - 1));
      final startOfThisWeek = DateTime(now.year, now.month, now.day - (now.weekday - 1));
      return startOfWeek.isBefore(startOfThisWeek);
    } else if (_selectedPeriod == 'Monthly') {
      final anchorMonth = DateTime(_anchorDate.year, _anchorDate.month, 1);
      final thisMonth = DateTime(now.year, now.month, 1);
      return anchorMonth.isBefore(thisMonth);
    } else {
      return _anchorDate.year < now.year;
    }
  }

  void _nextPeriod() {
    if (!_canGoNext()) return;
    setState(() {
      _selectedBarIndex = null;
      if (_selectedPeriod == 'Weekly') {
        _anchorDate = _anchorDate.add(const Duration(days: 7));
        _selectedDateForDetail = _selectedDateForDetail.add(const Duration(days: 7));
        final startOfWeek = DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day - (_anchorDate.weekday - 1));
        _selectedBarIndex = _selectedDateForDetail.difference(startOfWeek).inDays.clamp(0, 6);
      } else if (_selectedPeriod == 'Monthly') {
        _anchorDate = DateTime(_anchorDate.year, _anchorDate.month + 1, 1);
        _selectedDateForDetail = DateTime(_anchorDate.year, _anchorDate.month, 1);
      } else {
        _anchorDate = DateTime(_anchorDate.year + 1, 1, 1);
        _selectedDateForDetail = DateTime(_anchorDate.year, 1, 1);
      }
    });
  }

  String _getDateRangeText(AppStrings s) {
    if (_selectedPeriod == 'Weekly') {
      final startOfWeek = DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day - (_anchorDate.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return s.formatDateRange(startOfWeek, endOfWeek);
    } else if (_selectedPeriod == 'Monthly') {
      return '${s.getMonthName(_anchorDate.month)} ${s.formatNumber(_anchorDate.year)}';
    } else {
      return s.formatNumber(_anchorDate.year);
    }
  }

  List<DateTime> _getDaysInSelectedPeriod() {
    if (_selectedPeriod == 'Weekly') {
      final startOfWeek = DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day - (_anchorDate.weekday - 1));
      return List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
    } else if (_selectedPeriod == 'Monthly') {
      final daysInMonth = DateTime(_anchorDate.year, _anchorDate.month + 1, 0).day;
      return List.generate(daysInMonth, (i) => DateTime(_anchorDate.year, _anchorDate.month, i + 1));
    } else {
      final daysInYear = DateTime(_anchorDate.year, 12, 31).difference(DateTime(_anchorDate.year, 1, 1)).inDays + 1;
      return List.generate(daysInYear, (i) => DateTime(_anchorDate.year, 1, 1).add(Duration(days: i)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<MedicineProvider>();
    final s = context.watch<LanguageProvider>().strings;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = _getDaysInSelectedPeriod();

    // Historical adherence calculations strictly based on completed days before today
    int takenCount = 0;
    int missedCount = 0;

    for (final day in days) {
      final targetDay = DateTime(day.year, day.month, day.day);
      if (targetDay.isBefore(today)) {
        final doses = provider.getDosesForDate(day);
        for (final d in doses) {
          if (d.isTaken) {
            takenCount++;
          } else {
            // On past days, any dose not taken was missed or skipped
            missedCount++;
          }
        }
      }
    }

    final totalCompleted = takenCount + missedCount;
    final adherenceRate = totalCompleted > 0 ? ((takenCount / totalCompleted) * 100).round() : 0;
    final hasMeds = provider.medicines.isNotEmpty;
    final canNext = _canGoNext();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          s.adherenceReportTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        actions: [
          IconButton(
            tooltip: s.exportReportTitle,
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Color(0xFF7C3AED),
                size: 20,
              ),
            ),
            onPressed: () => ExportReportSheet.show(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        children: [
          // Period Selector ([Weekly] [Monthly] [Yearly])
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                {'key': 'Weekly', 'label': s.weeklyPeriod},
                {'key': 'Monthly', 'label': s.monthlyPeriod},
                {'key': 'Yearly', 'label': s.yearlyPeriod},
              ].map((item) {
                final period = item['key']!;
                final label = item['label']!;
                final isSelected = _selectedPeriod == period;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_selectedPeriod != period) {
                        setState(() {
                          _selectedPeriod = period;
                          _selectedBarIndex = null;
                        });
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppColors.primaryGradient : null,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primaryTeal.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppColors.darkTextMuted : AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 14),

          // Period Range Navigator (< 14 Sep – 20 Sep 2026 >) with Calendar picker
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 24),
                  tooltip: 'Previous period',
                  onPressed: _previousPeriod,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDateForDetail,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedPeriod = 'Weekly';
                        _anchorDate = picked;
                        _selectedDateForDetail = picked;
                        final startOfWeek = DateTime(picked.year, picked.month, picked.day - (picked.weekday - 1));
                        _selectedBarIndex = picked.difference(startOfWeek).inDays.clamp(0, 6);
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          size: 16,
                          color: isDark ? AppColors.primaryTealLight : AppColors.primaryTeal,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getDateRangeText(s),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    size: 24,
                    color: canNext
                        ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                        : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                  ),
                  tooltip: canNext ? 'Next period' : 'Current period',
                  onPressed: canNext ? _nextPeriod : null,
                ),
              ],
            ),
          ),

          // 7-Day Interactive Week Slider Strip in Weekly Mode
          if (_selectedPeriod == 'Weekly') ...[
            const SizedBox(height: 14),
            _buildWeekDayStrip(provider, s, isDark, today),
          ],

          const SizedBox(height: 20),

          // Main Adherence Ring Card (Strictly Completed / Historical)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (adherenceRate >= 80 ? AppColors.accentEmerald : AppColors.primaryTeal)
                      .withValues(alpha: isDark ? 0.12 : 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  width: 170,
                  height: 170,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 170,
                        height: 170,
                        child: CircularProgressIndicator(
                          value: totalCompleted == 0 ? 0.0 : (adherenceRate / 100),
                          strokeWidth: 15,
                          backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          color: totalCompleted == 0
                              ? (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))
                              : (adherenceRate >= 80
                                  ? AppColors.accentEmerald
                                  : (adherenceRate >= 50 ? AppColors.accentAmber : AppColors.accentRose)),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (totalCompleted > 0) ...[
                            Text(
                              '$adherenceRate%',
                              style: GoogleFonts.outfit(
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                letterSpacing: -1,
                              ),
                            ),
                            Text(
                              s.adherenceRateLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
                              ),
                            ),
                          ] else if (hasMeds) ...[
                            Icon(
                              Icons.history_toggle_off_rounded,
                              size: 32,
                              color: AppColors.primaryTeal,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.inProgressLabel,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              s.pendingCompletionLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                              ),
                            ),
                          ] else ...[
                            Icon(
                              Icons.event_busy_rounded,
                              size: 32,
                              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.noDosesLabel,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              s.forPeriodLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  totalCompleted == 0
                      ? (hasMeds
                          ? s.historicalReportsFinalize
                          : s.noMedDataForPeriod)
                      : s.scheduledDosesTakenCount(takenCount, totalCompleted),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.96, 0.96)),

          const SizedBox(height: 18),

          // 3 Historical Summary Stat Cards (Taken, Missed, Total Due)
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  label: s.taken,
                  value: s.formatNumber(takenCount),
                  color: AppColors.accentEmerald,
                  bgColor: isDark ? AppColors.accentEmerald.withValues(alpha: 0.12) : const Color(0xFFECFDF5),
                  borderColor: isDark ? AppColors.accentEmerald.withValues(alpha: 0.3) : const Color(0xFFA7F3D0),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryCard(
                  label: s.missedOrSkipped,
                  value: s.formatNumber(missedCount),
                  color: AppColors.accentRose,
                  bgColor: isDark ? AppColors.accentRose.withValues(alpha: 0.12) : const Color(0xFFFEF2F2),
                  borderColor: isDark ? AppColors.accentRose.withValues(alpha: 0.3) : const Color(0xFFFECACA),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryCard(
                  label: s.totalDue,
                  value: s.formatNumber(totalCompleted),
                  color: AppColors.accentCyan,
                  bgColor: isDark ? AppColors.accentCyan.withValues(alpha: 0.12) : const Color(0xFFEFF6FF),
                  borderColor: isDark ? AppColors.accentCyan.withValues(alpha: 0.3) : const Color(0xFFBFDBFE),
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Daily Adherence Bar Chart Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedPeriod == 'Weekly' ? s.dailyAdherenceRatio : (_selectedPeriod == 'Monthly' ? s.monthlyTrend : s.yearlyTrend),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      s.tapBarForDetails,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildDynamicChart(provider, isDark, today),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Day Dose Inspection Breakdown Section (Spacious, Uncramped, Full Width)
          _buildDayDoseInspection(provider, s, isDark, today),

          const SizedBox(height: 24),

          // Streak Section (Supportive, jewel-tone flame card)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentAmber.withValues(alpha: isDark ? 0.08 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.amberGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentAmber.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🔥', style: TextStyle(fontSize: 24)),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                 .scaleXY(begin: 0.95, end: 1.05, duration: 1400.ms),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.medicationConsistency,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        s.streakSummaryText(provider.currentStreakDays, provider.bestStreakDays),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Export Report Banner Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                    : [const Color(0xFFF5F3FF), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFF7C3AED).withValues(alpha: isDark ? 0.35 : 0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: isDark ? 0.15 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
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
                      child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                s.exportReportTitle,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'PDF',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF7C3AED),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.exportReportSub,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () => ExportReportSheet.show(context),
                    icon: const Icon(Icons.file_download_outlined, size: 20),
                    label: Text(
                      s.exportReportCardBtn,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Friendly empty state if user has no medicines
          if (!hasMeds) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.noMedicinesInCabinet,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.noMedicinesInCabinetDesc,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 7-Day Interactive Week Slider Strip
  // -------------------------------------------------------------
  Widget _buildWeekDayStrip(MedicineProvider provider, AppStrings s, bool isDark, DateTime today) {
    final startOfWeek = DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day - (_anchorDate.weekday - 1));
    final weekDays = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.date_range_rounded, size: 16, color: AppColors.primaryTeal),
                    const SizedBox(width: 6),
                    Text(
                      s.sevenDayTracker,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  s.tapPastDayForReport,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(7, (i) {
              final day = weekDays[i];
              final targetDay = DateTime(day.year, day.month, day.day);
              final isSelected = DateUtils.isSameDay(day, _selectedDateForDetail);
              final isToday = DateUtils.isSameDay(day, today);
              final isPast = targetDay.isBefore(today);

              final doses = provider.getDosesForDate(day);
              final total = doses.length;
              final taken = doses.where((d) => d.isTaken).length;

              // Exact user specification:
              // 1. All taken -> Green
              // 2. Partial taken (e.g. 3 of 4, 2 of 4) -> Yellow / Amber
              // 3. All missed/skipped (0 taken) on past day -> Red
              // 4. Today: if 0 taken and has overdue/skipped -> Red, else pending
              // 5. Future / None scheduled -> null
              Color? dotColor;
              if (total > 0) {
                if (taken == total) {
                  dotColor = AppColors.accentEmerald;
                } else if (taken > 0) {
                  dotColor = AppColors.accentAmber;
                } else {
                  if (isPast) {
                    dotColor = AppColors.accentRose;
                  } else if (isToday) {
                    final hasOverdueOrSkipped = doses.any((d) => d.isOverdue || d.isSkipped);
                    if (hasOverdueOrSkipped) {
                      dotColor = AppColors.accentRose;
                    }
                  }
                }
              }

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _selectedDateForDetail = day;
                      _selectedBarIndex = i;
                    });
                    // When tapping previous dates, open pop-up bottom sheet
                    if (isPast) {
                      _showPastDayReportSheet(context, day, provider, s, isDark);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.primaryGradient : null,
                      color: isSelected
                          ? null
                          : (isToday
                              ? (isDark ? AppColors.primaryTeal.withValues(alpha: 0.15) : AppColors.primaryTeal.withValues(alpha: 0.08))
                              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC))),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryTealLight
                            : (isToday
                                ? AppColors.primaryTeal.withValues(alpha: 0.5)
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                        width: isSelected || isToday ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primaryTeal.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.weekdayShort(day.weekday),
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.darkTextMuted : AppColors.textSecondary),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.formatNumber(day.day),
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: dotColor ?? (isSelected ? Colors.white.withValues(alpha: 0.35) : Colors.transparent),
                            boxShadow: dotColor != null
                                ? [
                                    BoxShadow(
                                      color: dotColor.withValues(alpha: 0.5),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Past Day Pop-up Bottom Sheet Modal
  // -------------------------------------------------------------
  void _showPastDayReportSheet(
    BuildContext context,
    DateTime date,
    MedicineProvider provider,
    AppStrings s,
    bool isDark,
  ) {
    final doses = provider.getDosesForDate(date);
    final total = doses.length;
    final taken = doses.where((d) => d.isTaken).length;
    final missed = total - taken;
    final adherenceRate = total > 0 ? ((taken / total) * 100).round() : 0;

    final dateFormatted = s.formatFullDate(date);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBackground : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.purpleGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.analytics_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                s.pastDayReport,
                                style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  s.archivedLabel,
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateFormatted,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22),
                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Scrollable content inside sheet
              Flexible(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  children: [
                    // Adherence Summary Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildSheetStatPill(
                                label: s.totalLabel,
                                value: s.formatNumber(total),
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                isDark: isDark,
                              ),
                              Container(width: 1, height: 32, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              _buildSheetStatPill(
                                label: s.taken,
                                value: s.formatNumber(taken),
                                color: AppColors.accentEmerald,
                                isDark: isDark,
                              ),
                              Container(width: 1, height: 32, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              _buildSheetStatPill(
                                label: s.missedOrSkipped,
                                value: s.formatNumber(missed),
                                color: AppColors.accentRose,
                                isDark: isDark,
                              ),
                              Container(width: 1, height: 32, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              _buildSheetStatPill(
                                label: s.adherenceLabel,
                                value: '${s.formatNumber(adherenceRate)}%',
                                color: adherenceRate >= 80
                                    ? AppColors.accentEmerald
                                    : (adherenceRate >= 40 ? AppColors.accentAmber : AppColors.accentRose),
                                isDark: isDark,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Result Banner
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: total == 0
                                  ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))
                                  : (taken == total
                                      ? AppColors.accentEmerald.withValues(alpha: isDark ? 0.2 : 0.12)
                                      : (taken > 0
                                          ? AppColors.accentAmber.withValues(alpha: isDark ? 0.2 : 0.12)
                                          : AppColors.accentRose.withValues(alpha: isDark ? 0.2 : 0.12))),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  total == 0
                                      ? Icons.info_outline_rounded
                                      : (taken == total
                                          ? Icons.check_circle_rounded
                                          : (taken > 0 ? Icons.warning_amber_rounded : Icons.cancel_rounded)),
                                  size: 16,
                                  color: total == 0
                                      ? (isDark ? AppColors.darkTextMuted : AppColors.textMuted)
                                      : (taken == total
                                          ? AppColors.accentEmerald
                                          : (taken > 0 ? AppColors.accentAmber : AppColors.accentRose)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    total == 0
                                        ? s.noMedsScheduledDate
                                        : (taken == total
                                            ? s.allMedsTaken100
                                            : (taken > 0
                                                ? s.partiallyCompletedText(taken, total, missed)
                                                : s.allMedsMissedText(missed))),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: total == 0
                                          ? (isDark ? AppColors.darkTextMuted : AppColors.textMuted)
                                          : (taken == total
                                              ? AppColors.accentEmerald
                                              : (taken > 0 ? AppColors.accentAmber : AppColors.accentRose)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Section Title
                    Text(
                      s.medicationDetailsList,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Doses list
                    if (total == 0)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_available_rounded,
                                size: 40,
                                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                s.noMedsScheduledDate,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...doses.map((dose) {
                        final med = dose.medicine;
                        final isTaken = dose.isTaken;
                        final isSkipped = dose.isSkipped;
                        final timeSlotTitle = _getTimeSlotTitle(dose.reminder.timeSlot, s);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isTaken
                                  ? AppColors.accentEmerald.withValues(alpha: 0.35)
                                  : (isSkipped
                                      ? AppColors.accentAmber.withValues(alpha: 0.35)
                                      : AppColors.accentRose.withValues(alpha: 0.35)),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Medicine Squircle Icon with 3D Visual
                                  _buildMedicineVisualIcon(med, isDark, size: 42, visualSize: 30),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          med.name,
                                          style: GoogleFonts.outfit(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          med.dosage.isNotEmpty
                                              ? '${med.dosage} · ${s.medicineTypeName(med.type.name)}'
                                              : s.medicineTypeName(med.type.name),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Status Badge
                                  _buildHistoricalDoseBadge(dose, s, isDark),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Divider(height: 1, thickness: 0.7),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 13,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${dose.reminder.formattedTime} ($timeSlotTitle)',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                    ),
                                  ),
                                  if (med.instruction.title.isNotEmpty) ...[
                                    const SizedBox(width: 10),
                                    Icon(
                                      Icons.restaurant_rounded,
                                      size: 13,
                                      color: AppColors.primaryTeal,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      s.foodInstructionName(med.instruction.name),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.primaryTeal,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetStatPill({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // Dynamic Chart (Weekly, Monthly, Yearly)
  // -------------------------------------------------------------
  Widget _buildDynamicChart(MedicineProvider provider, bool isDark, DateTime today) {
    final s = context.read<LanguageProvider>().strings;
    if (_selectedPeriod == 'Weekly') {
      final startOfWeek = DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day - (_anchorDate.weekday - 1));

      final data = List.generate(7, (i) {
        final day = startOfWeek.add(Duration(days: i));
        final targetDay = DateTime(day.year, day.month, day.day);
        final doses = provider.getDosesForDate(day);

        int taken = 0;
        int missed = 0;
        for (final d in doses) {
          if (d.isTaken) {
            taken++;
          } else if (targetDay.isBefore(today) || d.isSkipped || d.isMissed) {
            missed++;
          }
        }

        final bool isPast = targetDay.isBefore(today);
        final bool isToday = targetDay.isAtSameMomentAs(today);
        final bool isFuture = targetDay.isAfter(today);

        final int due = isPast ? doses.length : (taken + missed);
        final double rate = (isPast && doses.isNotEmpty)
            ? (taken / doses.length)
            : (isToday && due > 0 ? (taken / due) : 0.0);

        final dayName = s.weekdayShort(day.weekday);
        final fullDateStr = s.formatDayMonthWeekday(day);

        return {
          'name': dayName,
          'fullDate': fullDateStr,
          'rate': rate,
          'taken': taken,
          'due': due,
          'total': doses.length,
          'isPast': isPast,
          'isToday': isToday,
          'isFuture': isFuture,
          'date': day,
        };
      });

      return _renderBarsWithTooltip(data, isDark, width: 26, today: today, provider: provider);
    } else if (_selectedPeriod == 'Monthly') {
      final daysInMonth = DateTime(_anchorDate.year, _anchorDate.month + 1, 0).day;
      final int weeksCount = (daysInMonth / 7).ceil();

      final data = List.generate(weeksCount, (w) {
        final startDay = w * 7 + 1;
        final endDay = ((w + 1) * 7).clamp(1, daysInMonth);
        int total = 0;
        int taken = 0;
        int due = 0;

        for (int d = startDay; d <= endDay; d++) {
          final date = DateTime(_anchorDate.year, _anchorDate.month, d);
          final doses = provider.getDosesForDate(date);
          total += doses.length;
          final targetDay = DateTime(date.year, date.month, date.day);
          for (final item in doses) {
            if (item.isTaken) {
              taken++;
              due++;
            } else if (targetDay.isBefore(today) || item.isSkipped || item.isMissed) {
              due++;
            }
          }
        }

        final startWeekDate = DateTime(_anchorDate.year, _anchorDate.month, startDay);
        final bool isFuture = startWeekDate.isAfter(today);
        final double rate = due > 0 ? (taken / due) : 0.0;

        final weekName = s.code == 'bn'
            ? 'স${s.formatNumber(w + 1)}'
            : (s.code == 'hi' ? 'स${s.formatNumber(w + 1)}' : 'W${w + 1}');
        final fullDateStr = s.formatWeekRange(w + 1, startDay, endDay, _anchorDate.month);

        return {
          'name': weekName,
          'fullDate': fullDateStr,
          'rate': rate,
          'taken': taken,
          'due': due,
          'total': total,
          'isPast': !isFuture,
          'isToday': false,
          'isFuture': isFuture,
        };
      });

      return _renderBarsWithTooltip(data, isDark, width: 34, today: today, provider: provider);
    } else {
      // Yearly: 12 months (Jan - Dec)
      final monthNames = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

      final data = List.generate(12, (m) {
        final monthNum = m + 1;
        final daysInM = DateTime(_anchorDate.year, monthNum + 1, 0).day;
        int total = 0;
        int taken = 0;
        int due = 0;

        for (int d = 1; d <= daysInM; d++) {
          final date = DateTime(_anchorDate.year, monthNum, d);
          final doses = provider.getDosesForDate(date);
          total += doses.length;
          final targetDay = DateTime(date.year, date.month, date.day);
          for (final item in doses) {
            if (item.isTaken) {
              taken++;
              due++;
            } else if (targetDay.isBefore(today) || item.isSkipped || item.isMissed) {
              due++;
            }
          }
        }

        final monthStart = DateTime(_anchorDate.year, monthNum, 1);
        final bool isFuture = monthStart.isAfter(today);
        final double rate = due > 0 ? (taken / due) : 0.0;

        final mLabel = s.code == 'bn' || s.code == 'hi'
            ? s.monthName(monthNum).substring(0, 1)
            : monthNames[m];
        final fullDateStr = s.formatMonthYear(monthNum, _anchorDate.year);

        return {
          'name': mLabel,
          'fullDate': fullDateStr,
          'rate': rate,
          'taken': taken,
          'due': due,
          'total': total,
          'isPast': !isFuture,
          'isToday': false,
          'isFuture': isFuture,
        };
      });

      return _renderBarsWithTooltip(data, isDark, width: 16, today: today, provider: provider);
    }
  }

  Widget _renderBarsWithTooltip(
    List<Map<String, dynamic>> items,
    bool isDark, {
    double width = 24,
    required DateTime today,
    required MedicineProvider provider,
  }) {
    final s = context.read<LanguageProvider>().strings;
    final selected = (_selectedBarIndex != null && _selectedBarIndex! < items.length)
        ? items[_selectedBarIndex!]
        : null;

    return RepaintBoundary(
      child: Column(
        children: [
        // Interactive Tooltip / Detail callout
        if (selected != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selected['fullDate'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                Text(
                  (selected['isFuture'] as bool? ?? false)
                      ? s.futureDate
                      : ((selected['total'] as int) == 0
                          ? s.noScheduledDoses
                          : ((selected['isToday'] as bool? ?? false)
                              ? s.dosesTakenOngoing(selected['taken'] as int, selected['total'] as int)
                              : s.dosesTakenWithPercent(
                                  selected['taken'] as int,
                                  selected['total'] as int,
                                  ((selected['rate'] as double) * 100).round(),
                                ))),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

        // Bars
        SizedBox(
          height: 130,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(items.length, (i) {
              final item = items[i];
              final itemDate = item['date'] as DateTime?;
              final isSelected = (_selectedPeriod == 'Weekly' && itemDate != null)
                  ? DateUtils.isSameDay(itemDate, _selectedDateForDetail)
                  : (_selectedBarIndex == i);

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _selectedBarIndex = i;
                    if (itemDate != null) {
                      _selectedDateForDetail = itemDate;
                    }
                  });
                  if (itemDate != null && itemDate.isBefore(today)) {
                    _showPastDayReportSheet(context, itemDate, provider, s, isDark);
                  }
                },
                child: _buildBar(
                  item['name'] as String,
                  item['rate'] as double,
                  isDark,
                  (item['total'] as int) > 0,
                  isSelected: isSelected,
                  isFuture: item['isFuture'] as bool? ?? false,
                  isToday: item['isToday'] as bool? ?? false,
                  width: width,
                ),
              );
            }),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(
    String label,
    double rate,
    bool isDark,
    bool hasDoses, {
    required bool isSelected,
    required bool isFuture,
    required bool isToday,
    double width = 24,
  }) {
    final double barHeight;
    Gradient? barGradient;
    Color barColor;

    if (!hasDoses || isFuture) {
      barHeight = 6.0;
      barColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    } else {
      barHeight = (80.0 * rate).clamp(10.0, 80.0);
      if (rate >= 0.8) {
        barColor = AppColors.accentEmerald;
        barGradient = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [AppColors.primaryTeal, AppColors.accentEmerald],
        );
      } else if (rate >= 0.4) {
        barColor = AppColors.accentAmber;
        barGradient = AppColors.amberGradient;
      } else {
        barColor = AppColors.accentRose;
        barGradient = AppColors.roseGradient;
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Percentage or indicator on bar
        if (hasDoses && !isFuture)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              '${(rate * 100).round()}%',
              style: GoogleFonts.outfit(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
              ),
            ),
          )
        else
          const SizedBox(height: 12),

        Container(
          width: width,
          height: barHeight,
          decoration: BoxDecoration(
            color: barGradient == null ? barColor : null,
            gradient: barGradient,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: isSelected
                ? Border.all(
                    color: isDark ? Colors.white : AppColors.primaryTeal,
                    width: 2,
                  )
                : (isToday
                    ? Border.all(
                        color: AppColors.primaryTeal.withValues(alpha: 0.5),
                        width: 1.5,
                      )
                    : null),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: barColor.withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? (isDark ? AppColors.primaryTealLight : AppColors.primaryTeal)
                : (isDark ? AppColors.darkTextMuted : AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // Day Dose Inspection Section (Spacious, Full Width, Uncramped)
  // -------------------------------------------------------------
  Widget _buildDayDoseInspection(MedicineProvider provider, AppStrings s, bool isDark, DateTime today) {
    final doses = provider.getDosesForDate(_selectedDateForDetail);
    final targetDate = DateTime(_selectedDateForDetail.year, _selectedDateForDetail.month, _selectedDateForDetail.day);
    final isToday = DateUtils.isSameDay(_selectedDateForDetail, today);
    final isPast = targetDate.isBefore(today);

    int taken = 0;
    int skipped = 0;
    int overdueOrMissed = 0;
    int scheduledFuture = 0;

    for (final d in doses) {
      if (d.isTaken) {
        taken++;
      } else if (d.isSkipped) {
        skipped++;
      } else if (isPast || d.isOverdue) {
        overdueOrMissed++;
      } else {
        scheduledFuture++;
      }
    }

    final totalDoses = doses.length;
    final totalMissedOrSkipped = skipped + overdueOrMissed;

    final dateFormatted = s.formatFullDate(_selectedDateForDetail);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sleek Section Header Container
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: isPast ? AppColors.purpleGradient : AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (isPast ? const Color(0xFF7C3AED) : AppColors.primaryTeal).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        isPast ? Icons.analytics_rounded : Icons.event_note_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                s.dayInspectionHeading,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (isToday) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryTeal.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.primaryTeal.withValues(alpha: 0.4),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  s.historyDateToday,
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.primaryTealLight : AppColors.primaryTeal,
                                  ),
                                ),
                              ),
                            ] else if (isPast) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  s.pastLabel,
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateFormatted,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Summary Status Badge
                  if (totalDoses > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: taken == totalDoses
                            ? AppColors.accentEmerald.withValues(alpha: isDark ? 0.2 : 0.12)
                            : (taken > 0
                                ? AppColors.accentAmber.withValues(alpha: isDark ? 0.2 : 0.12)
                                : AppColors.accentRose.withValues(alpha: isDark ? 0.2 : 0.12)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: taken == totalDoses
                              ? AppColors.accentEmerald.withValues(alpha: 0.4)
                              : (taken > 0
                                  ? AppColors.accentAmber.withValues(alpha: 0.4)
                                  : AppColors.accentRose.withValues(alpha: 0.4)),
                        ),
                      ),
                      child: Text(
                        taken == totalDoses
                            ? s.allDoneShort
                            : (taken > 0
                                ? '${s.formatNumber(taken)} / ${s.formatNumber(totalDoses)}'
                                : (totalMissedOrSkipped > 0
                                    ? s.missedCountShort(totalMissedOrSkipped)
                                    : s.scheduledShort)),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: taken == totalDoses
                              ? AppColors.accentEmerald
                              : (taken > 0 ? AppColors.accentAmber : AppColors.accentRose),
                        ),
                      ),
                    ),
                ],
              ),

              if (totalDoses > 0) ...[
                const SizedBox(height: 14),
                // Slim Quick Stats Strip inside header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDayStatPill(
                        label: s.taken,
                        value: s.formatNumber(taken),
                        color: AppColors.accentEmerald,
                        isDark: isDark,
                      ),
                      Container(width: 1, height: 22, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      _buildDayStatPill(
                        label: s.missedOrSkipped,
                        value: s.formatNumber(totalMissedOrSkipped),
                        color: AppColors.accentRose,
                        isDark: isDark,
                      ),
                      if (isToday) ...[
                        Container(width: 1, height: 22, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        _buildDayStatPill(
                          label: s.scheduledSchedule,
                          value: s.formatNumber(scheduledFuture),
                          color: AppColors.primaryTeal,
                          isDark: isDark,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Standalone Elevated Dose Cards (Maximum Screen Width, No Nested Box!)
        if (totalDoses == 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.event_available_rounded,
                  size: 36,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
                const SizedBox(height: 8),
                Text(
                  s.noMedsScheduledDate,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: doses.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final dose = doses[index];
              final med = dose.medicine;
              final isTaken = dose.isTaken;
              final isSkipped = dose.isSkipped;
              final isOverdueOrPastMissed = isPast ? !isTaken && !isSkipped : dose.isOverdue;
              final timeSlotTitle = _getTimeSlotTitle(dose.reminder.timeSlot, s);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isTaken
                        ? AppColors.accentEmerald.withValues(alpha: 0.4)
                        : (isSkipped
                            ? AppColors.accentAmber.withValues(alpha: 0.4)
                            : (isOverdueOrPastMissed
                                ? AppColors.accentRose.withValues(alpha: 0.45)
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder))),
                    width: isTaken || isSkipped || isOverdueOrPastMissed ? 1.3 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isTaken
                              ? AppColors.accentEmerald
                              : (isOverdueOrPastMissed ? AppColors.accentRose : Colors.black))
                          .withValues(alpha: isDark ? 0.12 : 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Squircle icon + Title & Dosage + Status badge
                    Row(
                      children: [
                        _buildMedicineVisualIcon(med, isDark, size: 46, visualSize: 34),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                med.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                med.dosage.isNotEmpty
                                    ? '${med.dosage} · ${s.medicineTypeName(med.type.name)}'
                                    : s.medicineTypeName(med.type.name),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildInspectionStatusBadge(dose, s, isDark, isPast),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1, thickness: 0.7),
                    const SizedBox(height: 10),
                    // Bottom Row: Time chip & Food instruction chip
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 13.5,
                              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                            ),
                            const SizedBox(width: 4.5),
                            Text(
                              '${dose.reminder.formattedTime} ($timeSlotTitle)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (med.instruction.title.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.restaurant_rounded,
                                size: 13.5,
                                color: AppColors.primaryTeal,
                              ),
                              const SizedBox(width: 4.5),
                              Text(
                                s.foodInstructionName(med.instruction.name),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryTeal,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  String _getTimeSlotTitle(TimeSlot slot, AppStrings s) {
    switch (slot) {
      case TimeSlot.morning:
        return s.morningSlot;
      case TimeSlot.lunch:
        return s.lunchSlot;
      case TimeSlot.afternoon:
        return s.afternoonSlot;
      case TimeSlot.evening:
        return s.eveningSlot;
      case TimeSlot.night:
        return s.nightSlot;
    }
  }

  Widget _buildMedicineVisualIcon(
    Medicine med,
    bool isDark, {
    double size = 46,
    double visualSize = 34,
  }) {
    final gradientColors = MedicineVisual.getGradients(med.colorValue, med.type);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradientColors[0].withValues(alpha: isDark ? 0.16 : 0.08),
            gradientColors[1].withValues(alpha: isDark ? 0.06 : 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(
          color: gradientColors[0].withValues(alpha: isDark ? 0.35 : 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: MedicineVisual.fromMedicine(
          med,
          size: visualSize,
        ),
      ),
    );
  }

  Widget _buildDayStatPill({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // Historical Dose Badge for Past Day Sheet
  Widget _buildHistoricalDoseBadge(ScheduledDose dose, AppStrings s, bool isDark) {
    if (dose.isTaken) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.accentEmerald.withValues(alpha: isDark ? 0.2 : 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.accentEmerald.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.accentEmerald),
            const SizedBox(width: 4),
            Text(
              s.taken,
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.accentEmerald,
              ),
            ),
          ],
        ),
      );
    } else if (dose.isSkipped) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.accentAmber.withValues(alpha: isDark ? 0.22 : 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.accentAmber.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.redo_rounded, size: 14, color: AppColors.accentAmber),
            const SizedBox(width: 4),
            Text(
              s.skipped,
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.accentAmber,
              ),
            ),
          ],
        ),
      );
    } else {
      // Past day unrecorded dose is missed
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.accentRose.withValues(alpha: isDark ? 0.22 : 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.accentRose.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cancel_rounded, size: 14, color: AppColors.accentRose),
            const SizedBox(width: 4),
            Text(
              s.missed,
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.accentRose,
              ),
            ),
          ],
        ),
      );
    }
  }

  // Inspection Badge for Day Dose Inspection section
  Widget _buildInspectionStatusBadge(ScheduledDose dose, AppStrings s, bool isDark, bool isPast) {
    if (dose.isTaken) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.accentEmerald.withValues(alpha: isDark ? 0.2 : 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.accentEmerald.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.accentEmerald),
            const SizedBox(width: 4),
            Text(
              s.taken,
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.accentEmerald,
              ),
            ),
          ],
        ),
      );
    } else if (dose.isSkipped) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.accentAmber.withValues(alpha: isDark ? 0.22 : 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.accentAmber.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.redo_rounded, size: 14, color: AppColors.accentAmber),
            const SizedBox(width: 4),
            Text(
              s.skipped,
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.accentAmber,
              ),
            ),
          ],
        ),
      );
    } else if (isPast || dose.isOverdue) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.accentRose.withValues(alpha: isDark ? 0.22 : 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.accentRose.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cancel_rounded, size: 14, color: AppColors.accentRose),
            const SizedBox(width: 4),
            Text(
              s.missed,
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.accentRose,
              ),
            ),
          ],
        ),
      );
    } else {
      // Future/Scheduled for later today
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primaryTeal.withValues(alpha: isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primaryTeal.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule_rounded, size: 14, color: AppColors.primaryTeal),
            const SizedBox(width: 4),
            Text(
              s.scheduledShort,
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryTeal,
              ),
            ),
          ],
        ),
      );
    }
  }
}
