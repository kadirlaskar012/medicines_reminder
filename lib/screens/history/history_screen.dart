import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/services/report_and_alert_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/intake_record.dart';
import '../../models/reminder_time.dart';
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

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() async {
    final logs = await DBHelper.instance.getAllRecords(limit: 50);
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

    final totalTaken = _recentLogs.where((l) => l.status == IntakeStatus.taken).length;
    final totalSkipped = _recentLogs.where((l) => l.status == IntakeStatus.skipped).length;
    final adherenceScore = _recentLogs.isEmpty ? 100 : ((totalTaken / _recentLogs.length) * 100).toInt();

    return Scaffold(
      appBar: AppBar(
        title: const Text('History & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 26),
            tooltip: 'Export Doctor PDF',
            onPressed: () => _exportDoctorPdf(context, totalTaken),
          ),
          const SizedBox(width: 8),
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
                    title: 'Adherence',
                    value: '$adherenceScore%',
                    subtitle: 'Overall score',
                    icon: Icons.pie_chart_rounded,
                    color: AppColors.primary,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Current Streak',
                    value: '5 Days',
                    subtitle: 'Keep it up!',
                    icon: Icons.local_fire_department_rounded,
                    color: AppColors.warning,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Taken',
                    value: '$totalTaken',
                    subtitle: 'Doses confirmed',
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Skipped',
                    value: '$totalSkipped',
                    subtitle: 'Doses missed/skipped',
                    icon: Icons.cancel_rounded,
                    color: AppColors.error,
                    isDark: isDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Weekly Adherence Bar Chart
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weekly Adherence Breakdown',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Percentage of scheduled medicines taken each day',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 180,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 100,
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          show: true,
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              interval: 25,
                              getTitlesWidget: (val, meta) => Text(
                                '${val.toInt()}%',
                                style: const TextStyle(fontSize: 10, color: AppColors.lightTextMuted),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                                final idx = val.toInt();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    idx >= 0 && idx < days.length ? days[idx] : '',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 25,
                          getDrawingHorizontalLine: (val) => FlLine(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            strokeWidth: 1,
                          ),
                        ),
                        barGroups: [
                          _buildBarGroup(0, 100),
                          _buildBarGroup(1, 80),
                          _buildBarGroup(2, 100),
                          _buildBarGroup(3, 90),
                          _buildBarGroup(4, 75),
                          _buildBarGroup(5, 100),
                          _buildBarGroup(6, (provider.todayAdherenceRate * 100)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Doctor Consultation PDF Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF059669), size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Doctor Consultation Summary',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF065F46)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Export 1-page compliance PDF for physician visit',
                          style: TextStyle(fontSize: 11, color: Color(0xFF047857), fontWeight: FontWeight.w500),
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
                    child: const Text('Export', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Recent Intake Log List

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${_recentLogs.length} Records',
                  style: const TextStyle(fontSize: 13, color: AppColors.lightTextMuted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_isLoadingLogs)
              const Center(child: CircularProgressIndicator())
            else if (_recentLogs.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Text(
                    'No intake logs recorded yet.\nTake or skip scheduled medicines to see history here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.lightTextMuted),
                  ),
                ),
              )
            else
              ..._recentLogs.map((log) {
                final isTaken = log.status == IntakeStatus.taken;
                final dateFormatted = DateFormat('MMM d, hh:mm a').format(log.recordedAt);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isTaken ? AppColors.success : AppColors.lightTextMuted).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          log.status.icon,
                          size: 18,
                          color: isTaken ? AppColors.success : AppColors.lightTextMuted,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dose: ${log.status.label}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateFormatted,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isTaken ? AppColors.successLight : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          log.status.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isTaken ? AppColors.success : AppColors.lightTextMuted,
                          ),
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

  BarChartGroupData _buildBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: y >= 80 ? AppColors.primary : (y >= 50 ? AppColors.warning : AppColors.error),
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 100,
            color: Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ],
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
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
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
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              Icon(icon, size: 20, color: color),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.lightTextMuted),
          ),
        ],
      ),
    );
  }
}
