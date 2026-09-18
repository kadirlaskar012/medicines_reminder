import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../models/reminder_time.dart';
import '../../models/scheduled_dose.dart';
import '../../providers/language_provider.dart';
import '../../providers/medicine_provider.dart';

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
      if (s.code == 'bn') {
        return '${startOfWeek.day} ${s.monthName(startOfWeek.month)} – ${endOfWeek.day} ${s.monthName(endOfWeek.month)} ${endOfWeek.year}';
      }
      if (startOfWeek.year == endOfWeek.year) {
        return '${DateFormat('d MMM').format(startOfWeek)} – ${DateFormat('d MMM yyyy').format(endOfWeek)}';
      } else {
        return '${DateFormat('d MMM yyyy').format(startOfWeek)} – ${DateFormat('d MMM yyyy').format(endOfWeek)}';
      }
    } else if (_selectedPeriod == 'Monthly') {
      if (s.code == 'bn') {
        return '${s.monthName(_anchorDate.month)} ${_anchorDate.year}';
      }
      return DateFormat('MMMM yyyy').format(_anchorDate);
    } else {
      return '${_anchorDate.year}';
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

    final days = _getDaysInSelectedPeriod();
    int takenCount = 0;
    int missedCount = 0;
    int upcomingCount = 0;

    for (final day in days) {
      final doses = provider.getDosesForDate(day);
      for (final d in doses) {
        if (d.isTaken) {
          takenCount++;
        } else if (d.isMissed) {
          missedCount++;
        } else {
          upcomingCount++;
        }
      }
    }

    final totalDue = takenCount + missedCount;
    final totalScheduled = totalDue + upcomingCount;
    final adherenceRate = totalDue > 0 ? ((takenCount / totalDue) * 100).round() : (upcomingCount > 0 ? 100 : 0);
    final hasMeds = provider.medicines.isNotEmpty;
    final canNext = _canGoNext();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          s.code == 'bn' ? 'মেডিসিন অনুপালন রিপোর্ট' : 'Medication Adherence',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
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
                {'key': 'Weekly', 'label': s.code == 'bn' ? 'সাপ্তাহিক' : 'Weekly'},
                {'key': 'Monthly', 'label': s.code == 'bn' ? 'মাসিক' : 'Monthly'},
                {'key': 'Yearly', 'label': s.code == 'bn' ? 'বার্ষিক' : 'Yearly'},
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
            _buildWeekDayStrip(provider, s, isDark),
          ],

          const SizedBox(height: 24),

          // Main Adherence Ring Card
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
                          value: totalScheduled == 0
                              ? 0.0
                              : (totalDue > 0 ? (adherenceRate / 100) : 1.0),
                          strokeWidth: 15,
                          backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          color: totalScheduled == 0
                              ? (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))
                              : (totalDue == 0 && upcomingCount > 0
                                  ? AppColors.primaryTeal
                                  : (adherenceRate >= 80
                                      ? AppColors.accentEmerald
                                      : (adherenceRate >= 50 ? AppColors.accentAmber : AppColors.accentRose))),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (totalScheduled > 0) ...[
                            Text(
                              totalDue > 0 ? '$adherenceRate%' : 'On Track',
                              style: GoogleFonts.outfit(
                                fontSize: totalDue > 0 ? 38 : 28,
                                fontWeight: FontWeight.w900,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                letterSpacing: -1,
                              ),
                            ),
                            Text(
                              totalDue > 0 ? 'Adherence Rate' : '$upcomingCount Upcoming',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
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
                              'No Doses',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'For period',
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
                  totalScheduled == 0
                      ? 'No medication data for this period.'
                      : (totalDue > 0
                          ? (upcomingCount > 0
                              ? '$takenCount of $totalDue due doses taken ($upcomingCount upcoming)'
                              : '$takenCount of $totalDue scheduled doses taken')
                          : '$upcomingCount scheduled doses upcoming'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.96, 0.96)),

          const SizedBox(height: 20),

          // 3 Real Summary Stat Cards (Taken, Missed, Total Due)
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  label: 'Taken',
                  value: '$takenCount',
                  color: AppColors.accentEmerald,
                  bgColor: isDark ? AppColors.accentEmerald.withValues(alpha: 0.12) : const Color(0xFFECFDF5),
                  borderColor: isDark ? AppColors.accentEmerald.withValues(alpha: 0.3) : const Color(0xFFA7F3D0),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryCard(
                  label: 'Missed',
                  value: '$missedCount',
                  color: AppColors.accentRose,
                  bgColor: isDark ? AppColors.accentRose.withValues(alpha: 0.12) : const Color(0xFFFEF2F2),
                  borderColor: isDark ? AppColors.accentRose.withValues(alpha: 0.3) : const Color(0xFFFECACA),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryCard(
                  label: 'Total Due',
                  value: '$totalDue',
                  color: AppColors.accentCyan,
                  bgColor: isDark ? AppColors.accentCyan.withValues(alpha: 0.12) : const Color(0xFFEFF6FF),
                  borderColor: isDark ? AppColors.accentCyan.withValues(alpha: 0.3) : const Color(0xFFBFDBFE),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          if (upcomingCount > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.schedule_rounded, size: 16, color: AppColors.primaryTeal),
                  const SizedBox(width: 6),
                  Text(
                    '$upcomingCount upcoming doses scheduled in this period',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],

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
                      _selectedPeriod == 'Weekly'
                          ? (s.code == 'bn' ? 'দৈনিক গ্রহণের অনুপাত' : 'Daily Adherence')
                          : (_selectedPeriod == 'Monthly'
                              ? (s.code == 'bn' ? 'মাসিক ট্রেন্ড' : 'Monthly Trend')
                              : (s.code == 'bn' ? 'বার্ষিক ট্রেন্ড' : 'Yearly Trend')),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      s.code == 'bn' ? 'বারে ট্যাপ করে বিস্তারিত দেখুন' : 'Tap bar for details',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildDynamicChart(provider, isDark),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Day Dose Inspection Breakdown Card (Date-wise Missed/Taken details)
          _buildDayDoseInspection(provider, s, isDark),

          const SizedBox(height: 20),

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
                        'Medication Consistency',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Current streak: ${provider.currentStreakDays} ${provider.currentStreakDays == 1 ? "day" : "days"}  ·  Best: ${provider.bestStreakDays} ${provider.bestStreakDays == 1 ? "day" : "days"}',
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
                          'No medicines in cabinet',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Add medicines to begin recording daily intake and tracking adherence trends.',
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

  Widget _buildDynamicChart(MedicineProvider provider, bool isDark) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_selectedPeriod == 'Weekly') {
      final startOfWeek = DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day - (_anchorDate.weekday - 1));
      final s = context.read<LanguageProvider>().strings;

      // Gather data for all 7 days
      final data = List.generate(7, (i) {
        final day = startOfWeek.add(Duration(days: i));
        final targetDay = DateTime(day.year, day.month, day.day);
        final doses = provider.getDosesForDate(day);

        int taken = 0;
        int due = 0;
        int upcoming = 0;
        for (final d in doses) {
          if (d.isTaken) {
            taken++;
            due++;
          } else if (d.isMissed) {
            due++;
          } else {
            upcoming++;
          }
        }

        final bool isFuture = targetDay.isAfter(today);
        final bool isAllUpcoming = due == 0 && upcoming > 0;
        final double rate = due > 0 ? (taken / due) : (isAllUpcoming ? 1.0 : 0.0);

        final dayName = s.weekdayShort(day.weekday);
        final fullDateStr = s.code == 'bn'
            ? '${s.weekdayFull(day.weekday)}, ${day.day} ${s.monthName(day.month)}'
            : DateFormat('EEEE, d MMM').format(day);

        return {
          'name': dayName,
          'fullDate': fullDateStr,
          'rate': rate,
          'taken': taken,
          'due': due,
          'upcoming': upcoming,
          'total': doses.length,
          'isFuture': isFuture,
          'isAllUpcoming': isAllUpcoming,
          'date': day,
        };
      });

      return _renderBarsWithTooltip(data, isDark, width: 26);
    } else if (_selectedPeriod == 'Monthly') {
      final daysInMonth = DateTime(_anchorDate.year, _anchorDate.month + 1, 0).day;
      final int weeksCount = (daysInMonth / 7).ceil();

      final data = List.generate(weeksCount, (w) {
        final startDay = w * 7 + 1;
        final endDay = ((w + 1) * 7).clamp(1, daysInMonth);
        int total = 0;
        int taken = 0;
        int due = 0;
        int upcoming = 0;

        for (int d = startDay; d <= endDay; d++) {
          final date = DateTime(_anchorDate.year, _anchorDate.month, d);
          final doses = provider.getDosesForDate(date);
          total += doses.length;
          for (final item in doses) {
            if (item.isTaken) {
              taken++;
              due++;
            } else if (item.isMissed) {
              due++;
            } else {
              upcoming++;
            }
          }
        }

        final startWeekDate = DateTime(_anchorDate.year, _anchorDate.month, startDay);
        final bool isFuture = startWeekDate.isAfter(today);
        final bool isAllUpcoming = due == 0 && upcoming > 0;
        final double rate = due > 0 ? (taken / due) : (isAllUpcoming ? 1.0 : 0.0);

        return {
          'name': 'W${w + 1}',
          'fullDate': 'Week ${w + 1} ($startDay-$endDay ${DateFormat("MMM").format(_anchorDate)})',
          'rate': rate,
          'taken': taken,
          'due': due,
          'upcoming': upcoming,
          'total': total,
          'isFuture': isFuture,
          'isAllUpcoming': isAllUpcoming,
        };
      });

      return _renderBarsWithTooltip(data, isDark, width: 34);
    } else {
      // Yearly: 12 months (Jan - Dec)
      final monthNames = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
      final fullMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

      final data = List.generate(12, (m) {
        final monthNum = m + 1;
        final daysInM = DateTime(_anchorDate.year, monthNum + 1, 0).day;
        int total = 0;
        int taken = 0;
        int due = 0;
        int upcoming = 0;

        for (int d = 1; d <= daysInM; d++) {
          final date = DateTime(_anchorDate.year, monthNum, d);
          final doses = provider.getDosesForDate(date);
          total += doses.length;
          for (final item in doses) {
            if (item.isTaken) {
              taken++;
              due++;
            } else if (item.isMissed) {
              due++;
            } else {
              upcoming++;
            }
          }
        }

        final monthStart = DateTime(_anchorDate.year, monthNum, 1);
        final bool isFuture = monthStart.isAfter(today);
        final bool isAllUpcoming = due == 0 && upcoming > 0;
        final double rate = due > 0 ? (taken / due) : (isAllUpcoming ? 1.0 : 0.0);

        return {
          'name': monthNames[m],
          'fullDate': '${fullMonths[m]} ${_anchorDate.year}',
          'rate': rate,
          'taken': taken,
          'due': due,
          'upcoming': upcoming,
          'total': total,
          'isFuture': isFuture,
          'isAllUpcoming': isAllUpcoming,
        };
      });

      return _renderBarsWithTooltip(data, isDark, width: 16);
    }
  }

  Widget _renderBarsWithTooltip(List<Map<String, dynamic>> items, bool isDark, {double width = 24}) {
    final selected = (_selectedBarIndex != null && _selectedBarIndex! < items.length)
        ? items[_selectedBarIndex!]
        : null;

    return Column(
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
                  (selected['total'] as int) == 0
                      ? 'No scheduled doses'
                      : ((selected['due'] as int) == 0 && (selected['upcoming'] as int) > 0
                          ? '${selected['upcoming']} upcoming'
                          : ((selected['upcoming'] as int) > 0
                              ? '${selected['taken']} / ${selected['due']} taken (${((selected['rate'] as double) * 100).round()}%) · ${selected['upcoming']} upcoming'
                              : '${selected['taken']} / ${selected['due']} taken (${((selected['rate'] as double) * 100).round()}%)')),
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
                },
                child: _buildBar(
                  item['name'] as String,
                  item['rate'] as double,
                  isDark,
                  (item['total'] as int) > 0,
                  isSelected: isSelected,
                  isAllUpcoming: item['isAllUpcoming'] as bool,
                  width: width,
                ),
              );
            }),
          ),
        ),
      ],
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
    required bool isAllUpcoming,
    double width = 24,
  }) {
    final double barHeight;
    Gradient? barGradient;
    Color barColor;

    if (!hasDoses) {
      barHeight = 6.0;
      barColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    } else if (isAllUpcoming) {
      barHeight = 16.0;
      barColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
      barGradient = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          AppColors.primaryTeal.withValues(alpha: isDark ? 0.3 : 0.2),
          AppColors.primaryTeal.withValues(alpha: isDark ? 0.5 : 0.4),
        ],
      );
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
        if (hasDoses && !isAllUpcoming)
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
        else if (hasDoses && isAllUpcoming)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              '•',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: isDark ? AppColors.primaryTealLight : AppColors.primaryTeal,
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
                : (isAllUpcoming
                    ? Border.all(
                        color: AppColors.primaryTeal.withValues(alpha: 0.3),
                        width: 1,
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

  // 7-Day Week Slider Strip for Reports
  Widget _buildWeekDayStrip(MedicineProvider provider, AppStrings s, bool isDark) {
    final startOfWeek = DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day - (_anchorDate.weekday - 1));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
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
                      s.code == 'bn' ? 'সাপ্তাহিক ক্যালেন্ডার ট্র্যাকার' : '7-Day Week Tracker',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  s.code == 'bn' ? 'যেকোনো দিন ট্যাপ করে দেখুন' : 'Tap day to inspect',
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
              final isSelected = DateUtils.isSameDay(day, _selectedDateForDetail);
              final isToday = DateUtils.isSameDay(day, today);
              final compliance = provider.getDateComplianceStatus(day);

              Color? dotColor;
              switch (compliance) {
                case DateComplianceStatus.allTaken:
                  dotColor = AppColors.accentEmerald;
                  break;
                case DateComplianceStatus.partialTaken:
                  dotColor = AppColors.accentAmber;
                  break;
                case DateComplianceStatus.hasMissed:
                  dotColor = AppColors.accentRose;
                  break;
                case DateComplianceStatus.noneScheduled:
                case DateComplianceStatus.futurePending:
                  dotColor = null;
                  break;
              }

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _selectedDateForDetail = day;
                      _selectedBarIndex = i;
                    });
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
                          '${day.day}',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: dotColor ?? (isSelected ? Colors.white.withValues(alpha: 0.5) : Colors.transparent),
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

  // Day Dose Inspection Breakdown Card
  Widget _buildDayDoseInspection(MedicineProvider provider, AppStrings s, bool isDark) {
    final doses = provider.getDosesForDate(_selectedDateForDetail);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = DateUtils.isSameDay(_selectedDateForDetail, today);

    int taken = 0;
    int missed = 0;
    int upcoming = 0;

    for (final d in doses) {
      if (d.isTaken) {
        taken++;
      } else if (d.isMissed) {
        missed++;
      } else {
        upcoming++;
      }
    }

    final totalDoses = doses.length;
    final totalDue = taken + missed;
    final adherencePercent = totalDue > 0 ? ((taken / totalDue) * 100).round() : (upcoming > 0 ? 100 : 0);

    final dateFormatted = s.code == 'bn'
        ? '${s.weekdayFull(_selectedDateForDetail.weekday)}, ${_selectedDateForDetail.day} ${s.monthName(_selectedDateForDetail.month)} ${_selectedDateForDetail.year}'
        : DateFormat('EEEE, d MMMM yyyy').format(_selectedDateForDetail);

    return Container(
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
          // Header Row with Date & Status
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryTeal.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.event_note_rounded, color: Colors.white, size: 22),
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
                            s.code == 'bn' ? 'তারিখের ওষুধের বিবরণ' : 'Day Dose Inspection',
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
                              s.code == 'bn' ? 'আজ' : 'Today',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.primaryTealLight : AppColors.primaryTeal,
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
              // Adherence or Missed indicator badge
              if (totalDoses > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: missed > 0
                        ? AppColors.accentRose.withValues(alpha: isDark ? 0.2 : 0.1)
                        : (totalDue > 0 && taken == totalDue
                            ? AppColors.accentEmerald.withValues(alpha: isDark ? 0.2 : 0.1)
                            : AppColors.primaryTeal.withValues(alpha: isDark ? 0.2 : 0.1)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: missed > 0
                          ? AppColors.accentRose.withValues(alpha: 0.4)
                          : (totalDue > 0 && taken == totalDue
                              ? AppColors.accentEmerald.withValues(alpha: 0.4)
                              : AppColors.primaryTeal.withValues(alpha: 0.4)),
                    ),
                  ),
                  child: Text(
                    missed > 0
                        ? (s.code == 'bn' ? '$missedটি মিস হয়েছে' : '$missed Missed')
                        : (totalDue > 0 ? '$adherencePercent%' : (s.code == 'bn' ? 'আসন্ন' : 'Upcoming')),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: missed > 0
                          ? AppColors.accentRose
                          : (totalDue > 0 && taken == totalDue ? AppColors.accentEmerald : AppColors.primaryTeal),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Pills/Stats Bar for this Date
          if (totalDoses > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDayStatPill(
                    label: s.code == 'bn' ? 'নেওয়া হয়েছে' : 'Taken',
                    count: taken,
                    color: AppColors.accentEmerald,
                    isDark: isDark,
                  ),
                  Container(width: 1, height: 24, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  _buildDayStatPill(
                    label: s.code == 'bn' ? 'মিস হয়েছে' : 'Missed',
                    count: missed,
                    color: AppColors.accentRose,
                    isDark: isDark,
                  ),
                  Container(width: 1, height: 24, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  _buildDayStatPill(
                    label: s.code == 'bn' ? 'আসন্ন / বাকি' : 'Upcoming',
                    count: upcoming,
                    color: AppColors.primaryTeal,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 14),

          // Doses List or Empty State
          if (totalDoses == 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
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
                    s.code == 'bn' ? 'এই দিনে কোনো নির্ধারিত ওষুধ ছিল না' : 'No medicines were scheduled on this date',
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
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final dose = doses[index];
                final med = dose.medicine;
                final isTaken = dose.isTaken;
                final isMissed = dose.isMissed;
                final timeSlotTitle = _getTimeSlotTitle(dose.reminder.timeSlot, s);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isMissed
                          ? AppColors.accentRose.withValues(alpha: 0.45)
                          : (isTaken
                              ? AppColors.accentEmerald.withValues(alpha: 0.35)
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                      width: isMissed || isTaken ? 1.2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isMissed
                                ? AppColors.accentRose
                                : (isTaken ? AppColors.accentEmerald : Colors.black))
                            .withValues(alpha: isDark ? 0.1 : 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Medicine Color Stripe / Icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(med.colorValue).withValues(alpha: isDark ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Color(med.colorValue).withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            med.type.icon,
                            color: Color(med.colorValue),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Medicine details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med.name,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
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
                                const SizedBox(width: 6),
                                Text(
                                  '•',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${dose.reminder.formattedTime} ($timeSlotTitle)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            if (med.instruction.title.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                s.foodInstructionName(med.instruction.name),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primaryTeal,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status Badge
                      _buildDoseStatusBadge(dose, s, isDark),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _getTimeSlotTitle(TimeSlot slot, AppStrings s) {
    switch (slot) {
      case TimeSlot.morning:
        return s.morning;
      case TimeSlot.afternoon:
        return s.afternoon;
      case TimeSlot.evening:
        return s.evening;
      case TimeSlot.night:
        return s.night;
    }
  }

  Widget _buildDayStatPill({
    required String label,
    required int count,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Text(
          '$count',
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

  Widget _buildDoseStatusBadge(ScheduledDose dose, AppStrings s, bool isDark) {
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
              s.code == 'bn' ? 'নেওয়া হয়েছে' : 'Taken',
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.accentEmerald,
              ),
            ),
          ],
        ),
      );
    } else if (dose.isMissed) {
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
              s.code == 'bn' ? 'মিস হয়েছে' : 'Missed',
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
              s.code == 'bn' ? 'আসন্ন' : 'Upcoming',
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
