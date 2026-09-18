import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/services/report_and_alert_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/intake_record.dart';
import '../../models/medicine.dart';
import '../../models/reminder_time.dart';
import '../../providers/language_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../core/database/db_helper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<IntakeRecord> _recentLogs = [];
  bool _isLoadingLogs = true;
  String _selectedFilter = 'all'; // 'all', 'taken', 'missed'
  DateTime? _selectedDate; // Specific date filter

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() async {
    final logs = await DBHelper.instance.getAllRecords(limit: 200);
    if (mounted) {
      setState(() {
        _recentLogs = logs;
        _isLoadingLogs = false;
      });
    }
  }

  Future<void> _pickFilterDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _exportDoctorPdf(BuildContext context, int totalTaken) {
    final provider = context.read<MedicineProvider>();
    final remindersMap = <String, List<ReminderTime>>{};
    for (final med in provider.medicines) {
      remindersMap[med.id] = provider.getRemindersForMedicine(med.id);
    }

    ReportAndAlertService.instance.exportDoctorReportPdf(
      profile: provider.activeProfile,
      medicines: provider.medicines,
      remindersByMedicine: remindersMap,
      adherenceRate: provider.todayAdherenceRate,
      totalDosesTaken: totalTaken,
      totalDosesScheduled: _recentLogs.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<MedicineProvider>();
    final s = context.watch<LanguageProvider>().strings;

    final totalTaken = _recentLogs.where((l) => l.status == IntakeStatus.taken).length;
    final totalSkipped = _recentLogs.where((l) => l.status == IntakeStatus.skipped || l.status == IntakeStatus.missed).length;
    final adherenceScore = _recentLogs.isEmpty ? 0 : ((totalTaken / _recentLogs.length) * 100).toInt();

    final filteredLogs = _recentLogs.where((l) {
      if (_selectedFilter == 'taken' && l.status != IntakeStatus.taken) return false;
      if (_selectedFilter == 'missed' && l.status != IntakeStatus.skipped && l.status != IntakeStatus.missed) return false;
      if (_selectedDate != null) {
        final recDate = l.recordedAt;
        final isSameRec = recDate.year == _selectedDate!.year &&
            recDate.month == _selectedDate!.month &&
            recDate.day == _selectedDate!.day;
        if (!isSameRec) {
          final schedParts = l.scheduledDate.split('-');
          if (schedParts.length == 3) {
            final sy = int.tryParse(schedParts[0]);
            final sm = int.tryParse(schedParts[1]);
            final sd = int.tryParse(schedParts[2]);
            if (sy != _selectedDate!.year || sm != _selectedDate!.month || sd != _selectedDate!.day) {
              return false;
            }
          } else {
            return false;
          }
        }
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          s.doseHistory,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _selectedDate != null,
              backgroundColor: AppColors.accentRose,
              smallSize: 8,
              child: Icon(
                _selectedDate != null ? Icons.event_available_rounded : Icons.calendar_month_rounded,
                color: _selectedDate != null ? AppColors.primaryTealLight : null,
              ),
            ),
            tooltip: s.code == 'bn' ? 'তারিখ দিয়ে ফিল্টার করুন' : 'Filter by Date',
            onPressed: () => _pickFilterDate(context),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadLogs(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
          children: [
            // Analytics Overview Cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: s.adherenceRate,
                    value: '$adherenceScore%',
                    subtitle: s.overallScore,
                    icon: Icons.pie_chart_rounded,
                    color: AppColors.primaryTealLight,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: s.currentStreak,
                    value: '${provider.currentStreakDays} ${s.daysUnit}',
                    subtitle: s.keepItUp,
                    icon: Icons.local_fire_department_rounded,
                    color: AppColors.accentAmber,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: s.taken,
                    value: '$totalTaken',
                    subtitle: s.dosesConfirmed,
                    icon: Icons.check_circle_rounded,
                    color: AppColors.accentEmerald,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: s.skipped,
                    value: '$totalSkipped',
                    subtitle: s.dosesMissed,
                    icon: Icons.cancel_rounded,
                    color: AppColors.accentRose,
                    isDark: isDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Doctor Consultation PDF Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.doctorConsultationSummary,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.exportDoctorPdfSub,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _exportDoctorPdf(context, totalTaken),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: const Size(60, 36),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(s.export, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Screen 13 Filter Chips [All] [Taken] [Missed]
            Row(
              children: [
                _buildFilterChip('all', 'All', filteredLogs.length, isDark),
                const SizedBox(width: 8),
                _buildFilterChip('taken', 'Taken', totalTaken, isDark),
                const SizedBox(width: 8),
                _buildFilterChip('missed', 'Missed', totalSkipped, isDark),
              ],
            ),

            if (_selectedDate != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_available_rounded, size: 20, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, d MMMM yyyy').format(_selectedDate!),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                          ),
                          Text(
                            s.code == 'bn' ? 'শুধুমাত্র এই তারিখের ফিল্টার করা ইতিহাস' : 'Showing history for this date only',
                            style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.primary),
                      visualDensity: VisualDensity.compact,
                      tooltip: s.code == 'bn' ? 'ফিল্টার বাতিল করুন' : 'Clear filter',
                      onPressed: () => setState(() => _selectedDate = null),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            if (_isLoadingLogs)
              const Center(child: CircularProgressIndicator())
            else if (filteredLogs.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.history_rounded, size: 40, color: isDark ? Colors.white30 : Colors.black26),
                      const SizedBox(height: 10),
                      Text(
                        _selectedDate != null
                            ? (s.code == 'bn'
                                ? 'এই তারিখে কোনো ওষুধ নেওয়ার বা মিস করার রেকর্ড নেই'
                                : 'No intake or missed logs found for this selected date.')
                            : '${s.noIntakeLogsTitle}\n${s.noIntakeLogsSub}',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                      ),
                    ],
                  ),
                ),
              )
            else
              Builder(
                builder: (context) {
                  final now = DateTime.now();
                  final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                  final yesterday = now.subtract(const Duration(days: 1));
                  final yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

                  final Map<String, List<IntakeRecord>> groupedLogs = {};
                  for (final log in filteredLogs) {
                    final d = log.recordedAt;
                    final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                    groupedLogs.putIfAbsent(key, () => []).add(log);
                  }
                  final sortedDateKeys = groupedLogs.keys.toList()..sort((a, b) => b.compareTo(a));

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: sortedDateKeys.map((dateKey) {
                      final dayLogs = groupedLogs[dateKey]!;
                      final firstDate = dayLogs.first.recordedAt;
                      final dayTaken = dayLogs.where((l) => l.status == IntakeStatus.taken).length;
                      final daySkipped = dayLogs.where((l) => l.status == IntakeStatus.skipped || l.status == IntakeStatus.missed).length;

                      String headerTitle;
                      if (dateKey == todayStr) {
                        headerTitle = s.code == 'bn' ? 'আজ (${DateFormat('d MMM yyyy').format(firstDate)})' : 'Today (${DateFormat('d MMM yyyy').format(firstDate)})';
                      } else if (dateKey == yesterdayStr) {
                        headerTitle = s.code == 'bn' ? 'গতকাল (${DateFormat('d MMM yyyy').format(firstDate)})' : 'Yesterday (${DateFormat('d MMM yyyy').format(firstDate)})';
                      } else {
                        headerTitle = DateFormat('EEEE, d MMMM yyyy').format(firstDate);
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Section Header
                          Padding(
                            padding: const EdgeInsets.only(top: 10, bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      headerTitle,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    if (dayTaken > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.accentMint.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '$dayTaken taken',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.accentMint),
                                        ),
                                      ),
                                    if (dayTaken > 0 && daySkipped > 0) const SizedBox(width: 4),
                                    if (daySkipped > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '$daySkipped missed',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.error),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Cards for this date
                          ...dayLogs.map((log) {
                            final isTaken = log.status == IntakeStatus.taken;
                            final timeFormatted = DateFormat('hh:mm a').format(log.recordedAt);
                            final med = provider.medicines.cast<Medicine?>().firstWhere(
                                  (m) => m?.id == log.medicineId,
                                  orElse: () => null,
                                );
                            final medName = med?.name ?? 'Medicine';
                            final dosage = med?.dosage ?? '';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCard : AppColors.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Circular Icon Avatar
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: (isTaken ? AppColors.accentEmerald : AppColors.accentRose).withValues(alpha: 0.14),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isTaken ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                      color: isTaken ? AppColors.accentEmerald : AppColors.accentRose,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Medicine Name & Timestamp
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dosage.isNotEmpty ? '$medName $dosage' : medName,
                                          style: GoogleFonts.outfit(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isTaken ? 'Taken at $timeFormatted' : 'Missed / Skipped at $timeFormatted',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: isTaken
                                                ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                                                : AppColors.accentRose,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Status Badge (Emerald "Taken" or Rose "Missed")
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (isTaken ? AppColors.accentEmerald : AppColors.accentRose).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isTaken ? Icons.check_rounded : Icons.close_rounded,
                                          size: 13,
                                          color: isTaken ? AppColors.accentEmerald : AppColors.accentRose,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isTaken ? s.taken : s.skipped,
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: isTaken ? AppColors.accentEmerald : AppColors.accentRose,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 6),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, int count, bool isDark) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected
              ? null
              : (isDark ? AppColors.darkCard : AppColors.surface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryTeal.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.08 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
              Icon(icon, size: 20, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}
