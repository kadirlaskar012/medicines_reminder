import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/medicine_provider.dart';

class ReportsAnalyticsScreen extends StatefulWidget {
  const ReportsAnalyticsScreen({super.key});

  @override
  State<ReportsAnalyticsScreen> createState() => _ReportsAnalyticsScreenState();
}

class _ReportsAnalyticsScreenState extends State<ReportsAnalyticsScreen> {
  String _selectedPeriod = 'Weekly'; // Weekly, Monthly, Yearly
  DateTime _anchorDate = DateTime.now();

  void _previousPeriod() {
    setState(() {
      if (_selectedPeriod == 'Weekly') {
        _anchorDate = _anchorDate.subtract(const Duration(days: 7));
      } else if (_selectedPeriod == 'Monthly') {
        _anchorDate = DateTime(_anchorDate.year, _anchorDate.month - 1, _anchorDate.day);
      } else {
        _anchorDate = DateTime(_anchorDate.year - 1, _anchorDate.month, _anchorDate.day);
      }
    });
  }

  void _nextPeriod() {
    setState(() {
      if (_selectedPeriod == 'Weekly') {
        _anchorDate = _anchorDate.add(const Duration(days: 7));
      } else if (_selectedPeriod == 'Monthly') {
        _anchorDate = DateTime(_anchorDate.year, _anchorDate.month + 1, _anchorDate.day);
      } else {
        _anchorDate = DateTime(_anchorDate.year + 1, _anchorDate.month, _anchorDate.day);
      }
    });
  }

  String _getDateRangeText() {
    if (_selectedPeriod == 'Weekly') {
      final startOfWeek = DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day - (_anchorDate.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      if (startOfWeek.year == endOfWeek.year) {
        return '${DateFormat('d MMM').format(startOfWeek)} - ${DateFormat('d MMM yyyy').format(endOfWeek)}';
      } else {
        return '${DateFormat('d MMM yyyy').format(startOfWeek)} - ${DateFormat('d MMM yyyy').format(endOfWeek)}';
      }
    } else if (_selectedPeriod == 'Monthly') {
      return DateFormat('MMMM yyyy').format(_anchorDate);
    } else {
      return DateFormat('yyyy').format(_anchorDate);
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
      // Yearly: sample the 12 mid-month points
      return List.generate(12, (i) => DateTime(_anchorDate.year, i + 1, 15));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<MedicineProvider>();

    final days = _getDaysInSelectedPeriod();
    int totalCount = 0;
    int takenCount = 0;

    for (final day in days) {
      final doses = provider.getDosesForDate(day);
      totalCount += doses.length;
      takenCount += doses.where((d) => d.isTaken).length;
    }

    final missedCount = (totalCount - takenCount).clamp(0, 99999);
    final adherenceRate = totalCount > 0 ? ((takenCount / totalCount) * 100).round() : 0;
    final hasMeds = provider.medicines.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
        children: [
          // Period Selector ([Weekly] [Monthly] [Yearly])
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: ['Weekly', 'Monthly', 'Yearly'].map((period) {
                final isSelected = _selectedPeriod == period;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPeriod = period),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        period,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : (isDark ? AppColors.darkTextMuted : const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Dynamic Date Navigator (< Dynamic Date >)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 22),
                tooltip: 'Previous period',
                onPressed: _previousPeriod,
              ),
              Text(
                _getDateRangeText(),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 22),
                tooltip: 'Next period',
                onPressed: _nextPeriod,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Circular Donut Adherence Gauge (Real Adherence %, 0% when no intake)
          Center(
            child: SizedBox(
              width: 170,
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 170,
                    height: 170,
                    child: CircularProgressIndicator(
                      value: totalCount > 0 ? (adherenceRate / 100) : 0.0,
                      strokeWidth: 14,
                      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      color: adherenceRate > 0 ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$adherenceRate%',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        totalCount > 0 ? 'Medicine Taken' : 'No Doses Logged',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // 3 Real Summary Stat Cards (Taken, Missed, Total)
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  label: 'Taken',
                  value: '$takenCount',
                  color: const Color(0xFF10B981),
                  bgColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  label: 'Missed',
                  value: '$missedCount',
                  color: const Color(0xFFEF4444),
                  bgColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  label: 'Total',
                  value: '$totalCount',
                  color: AppColors.primary,
                  bgColor: AppColors.primary.withValues(alpha: 0.1),
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Daily Adherence Bar Chart
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedPeriod == 'Weekly' ? 'Daily Adherence' : (_selectedPeriod == 'Monthly' ? 'Monthly Trend' : 'Yearly Trend'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    if (provider.currentStreakDays > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥 ', style: TextStyle(fontSize: 11)),
                            Text(
                              '${provider.currentStreakDays}d streak',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFD97706)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDynamicChart(provider, isDark),
              ],
            ),
          ),

          // Clean Empty State if user has not added any medications yet
          if (!hasMeds) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard.withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No active medicines',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Add medicines from Cabinet to track real-time intake analytics and adherence streaks.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
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
    if (_selectedPeriod == 'Weekly') {
      final startOfWeek = DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day - (_anchorDate.weekday - 1));
      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      return SizedBox(
        height: 120,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (i) {
            final day = startOfWeek.add(Duration(days: i));
            final doses = provider.getDosesForDate(day);
            final double rate = doses.isEmpty ? 0.0 : (doses.where((d) => d.isTaken).length / doses.length);
            final bool hasDoses = doses.isNotEmpty;
            return _buildBar(dayNames[i], rate, isDark, hasDoses);
          }),
        ),
      );
    } else if (_selectedPeriod == 'Monthly') {
      // 4-5 weekly chunks in month
      final daysInMonth = DateTime(_anchorDate.year, _anchorDate.month + 1, 0).day;
      final int weeksCount = (daysInMonth / 7).ceil();

      return SizedBox(
        height: 120,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(weeksCount, (w) {
            final startDay = w * 7 + 1;
            final endDay = ((w + 1) * 7).clamp(1, daysInMonth);
            int total = 0;
            int taken = 0;
            for (int d = startDay; d <= endDay; d++) {
              final date = DateTime(_anchorDate.year, _anchorDate.month, d);
              final doses = provider.getDosesForDate(date);
              total += doses.length;
              taken += doses.where((item) => item.isTaken).length;
            }
            final double rate = total == 0 ? 0.0 : (taken / total);
            return _buildBar('W${w + 1}', rate, isDark, total > 0);
          }),
        ),
      );
    } else {
      // Yearly: 12 months (Jan - Dec)
      final monthNames = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
      return SizedBox(
        height: 120,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(12, (m) {
            final monthNum = m + 1;
            final daysInM = DateTime(_anchorDate.year, monthNum + 1, 0).day;
            int total = 0;
            int taken = 0;
            for (int d = 1; d <= daysInM; d++) {
              final date = DateTime(_anchorDate.year, monthNum, d);
              final doses = provider.getDosesForDate(date);
              total += doses.length;
              taken += doses.where((item) => item.isTaken).length;
            }
            final double rate = total == 0 ? 0.0 : (taken / total);
            return _buildBar(monthNames[m], rate, isDark, total > 0, width: 14);
          }),
        ),
      );
    }
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String day, double heightFactor, bool isDark, bool hasDoses, {double width = 22}) {
    final bool isZero = !hasDoses || heightFactor == 0.0;
    final barHeight = isZero ? 4.0 : (80.0 * heightFactor).clamp(6.0, 80.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: width,
          height: barHeight,
          decoration: BoxDecoration(
            color: isZero ? (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)) : null,
            gradient: isZero
                ? null
                : const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xFF10B981), Color(0xFF34D399)],
                  ),
            borderRadius: BorderRadius.circular(isZero ? 2 : 8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
