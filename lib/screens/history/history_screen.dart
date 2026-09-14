import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() async {
    final logs = await DBHelper.instance.getAllRecords(limit: 60);
    if (mounted) {
      setState(() {
        _recentLogs = logs;
        _isLoadingLogs = false;
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
    final totalSkipped = _recentLogs.where((l) => l.status == IntakeStatus.skipped).length;
    final adherenceScore = _recentLogs.isEmpty ? 100 : ((totalTaken / _recentLogs.length) * 100).toInt();

    final filteredLogs = _recentLogs.where((l) {
      if (_selectedFilter == 'taken') return l.status == IntakeStatus.taken;
      if (_selectedFilter == 'missed') return l.status == IntakeStatus.skipped;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(s.doseHistory),
        elevation: 0,
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
                    color: AppColors.primary,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: s.currentStreak,
                    value: '5 ${s.daysUnit}',
                    subtitle: s.keepItUp,
                    icon: Icons.local_fire_department_rounded,
                    color: AppColors.accentMint,
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
                    color: AppColors.accentMint,
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
                    color: AppColors.error,
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
            const SizedBox(height: 16),

            // Month Section Header (Screen 13)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(DateTime.now()),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '${filteredLogs.length} ${s.records}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

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
                        '${s.noIntakeLogsTitle}\n${s.noIntakeLogsSub}',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...filteredLogs.map((log) {
                final isTaken = log.status == IntakeStatus.taken;
                final dateFormatted = DateFormat('hh:mm a • MMM d').format(log.recordedAt);
                final med = provider.medicines.cast<Medicine?>().firstWhere(
                      (m) => m?.id == log.medicineId,
                      orElse: () => null,
                    );
                final medName = med?.name ?? 'Medicine';
                final dosage = med?.dosage ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Circular Icon Avatar
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: (isTaken ? AppColors.accentMint : AppColors.error).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isTaken ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          color: isTaken ? AppColors.accentMint : AppColors.error,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Medicine Name & Timestamp
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dosage.isNotEmpty ? '$medName $dosage' : medName,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateFormatted,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Status Badge (Green "Taken" or Red "Missed")
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: (isTaken ? AppColors.accentMint : AppColors.error).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isTaken ? Icons.check_rounded : Icons.close_rounded,
                              size: 14,
                              color: isTaken ? AppColors.accentMint : AppColors.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isTaken ? 'Taken' : 'Missed',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isTaken ? AppColors.accentMint : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
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
          color: isSelected
              ? AppColors.primary
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
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
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
          ),
        ],
      ),
    );
  }
}
