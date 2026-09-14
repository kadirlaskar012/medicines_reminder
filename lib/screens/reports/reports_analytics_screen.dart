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
  int? _selectedBarIndex;

  void _previousPeriod() {
    setState(() {
      _selectedBarIndex = null;
      if (_selectedPeriod == 'Weekly') {
        _anchorDate = _anchorDate.subtract(const Duration(days: 7));
      } else if (_selectedPeriod == 'Monthly') {
        _anchorDate = DateTime(_anchorDate.year, _anchorDate.month - 1, 1);
      } else {
        _anchorDate = DateTime(_anchorDate.year - 1, 1, 1);
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
      } else if (_selectedPeriod == 'Monthly') {
        _anchorDate = DateTime(_anchorDate.year, _anchorDate.month + 1, 1);
      } else {
        _anchorDate = DateTime(_anchorDate.year + 1, 1, 1);
      }
    });
  }

  String _getDateRangeText() {
    if (_selectedPeriod == 'Weekly') {
      final startOfWeek = DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day - (_anchorDate.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      if (startOfWeek.year == endOfWeek.year) {
        return '${DateFormat('d MMM').format(startOfWeek)} – ${DateFormat('d MMM yyyy').format(endOfWeek)}';
      } else {
        return '${DateFormat('d MMM yyyy').format(startOfWeek)} – ${DateFormat('d MMM yyyy').format(endOfWeek)}';
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
    final canNext = _canGoNext();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Medication Adherence',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
            child: Row(
              children: ['Weekly', 'Monthly', 'Yearly'].map((period) {
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

          // Period Range Navigator (< 14 Sep – 20 Sep 2026 >)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
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
                Text(
                  _getDateRangeText(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
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

          const SizedBox(height: 24),

          // Main Adherence Ring
          Center(
            child: SizedBox(
              width: 176,
              height: 176,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 176,
                    height: 176,
                    child: CircularProgressIndicator(
                      value: totalCount > 0 ? (adherenceRate / 100) : 0.0,
                      strokeWidth: 14,
                      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      color: totalCount == 0
                          ? (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))
                          : (adherenceRate >= 80
                              ? AppColors.success
                              : (adherenceRate >= 50 ? AppColors.warning : AppColors.error)),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (totalCount > 0) ...[
                        Text(
                          '$adherenceRate%',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          'Adherence',
                          style: TextStyle(
                            fontSize: 13,
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'For period',
                          style: TextStyle(
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
          ),

          const SizedBox(height: 14),

          // Context Line: "1 of 7 scheduled doses taken" or "No medication data for this period"
          Center(
            child: Text(
              totalCount > 0
                  ? '$takenCount of $totalCount scheduled doses taken'
                  : 'No medication data for this period.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 3 Real Summary Stat Cards (Taken, Missed, Total)
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  label: 'Taken',
                  value: '$takenCount',
                  color: AppColors.success,
                  bgColor: isDark ? AppColors.success.withValues(alpha: 0.14) : const Color(0xFFECFDF5),
                  borderColor: isDark ? AppColors.success.withValues(alpha: 0.3) : const Color(0xFFA7F3D0),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  label: 'Missed',
                  value: '$missedCount',
                  color: AppColors.error,
                  bgColor: isDark ? AppColors.error.withValues(alpha: 0.14) : const Color(0xFFFEF2F2),
                  borderColor: isDark ? AppColors.error.withValues(alpha: 0.3) : const Color(0xFFFECACA),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  label: 'Total',
                  value: '$totalCount',
                  color: AppColors.primary,
                  bgColor: isDark ? AppColors.primary.withValues(alpha: 0.14) : const Color(0xFFEFF6FF),
                  borderColor: isDark ? AppColors.primary.withValues(alpha: 0.3) : const Color(0xFFBFDBFE),
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Daily Adherence Bar Chart Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedPeriod == 'Weekly'
                          ? 'Daily Adherence'
                          : (_selectedPeriod == 'Monthly' ? 'Monthly Trend' : 'Yearly Trend'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Tap bar for details',
                      style: TextStyle(
                        fontSize: 11,
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

          // Streak Section (Spec 20 & 63: Supportive, not overly gamified)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: isDark ? 0.2 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🔥', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Medication Consistency',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Current streak: ${provider.currentStreakDays} ${provider.currentStreakDays == 1 ? "day" : "days"}  ·  Best: ${provider.bestStreakDays} ${provider.bestStreakDays == 1 ? "day" : "days"}',
                        style: TextStyle(
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
    if (_selectedPeriod == 'Weekly') {
      final startOfWeek = DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day - (_anchorDate.weekday - 1));
      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      // Gather data for all 7 days
      final data = List.generate(7, (i) {
        final day = startOfWeek.add(Duration(days: i));
        final doses = provider.getDosesForDate(day);
        final taken = doses.where((d) => d.isTaken).length;
        final total = doses.length;
        final rate = total == 0 ? 0.0 : (taken / total);
        return {
          'name': dayNames[i],
          'fullDate': DateFormat('EEEE, d MMM').format(day),
          'rate': rate,
          'taken': taken,
          'total': total,
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
        for (int d = startDay; d <= endDay; d++) {
          final date = DateTime(_anchorDate.year, _anchorDate.month, d);
          final doses = provider.getDosesForDate(date);
          total += doses.length;
          taken += doses.where((item) => item.isTaken).length;
        }
        final rate = total == 0 ? 0.0 : (taken / total);
        return {
          'name': 'W${w + 1}',
          'fullDate': 'Week ${w + 1} ($startDay-$endDay ${DateFormat("MMM").format(_anchorDate)})',
          'rate': rate,
          'taken': taken,
          'total': total,
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
        for (int d = 1; d <= daysInM; d++) {
          final date = DateTime(_anchorDate.year, monthNum, d);
          final doses = provider.getDosesForDate(date);
          total += doses.length;
          taken += doses.where((item) => item.isTaken).length;
        }
        final rate = total == 0 ? 0.0 : (taken / total);
        return {
          'name': monthNames[m],
          'fullDate': '${fullMonths[m]} ${_anchorDate.year}',
          'rate': rate,
          'taken': taken,
          'total': total,
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
                  (selected['total'] as int) > 0
                      ? '${selected['taken']} / ${selected['total']} taken (${((selected['rate'] as double) * 100).round()}%)'
                      : 'No scheduled doses',
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
              final isSelected = _selectedBarIndex == i;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _selectedBarIndex = (_selectedBarIndex == i) ? null : i;
                  });
                },
                child: _buildBar(
                  item['name'] as String,
                  item['rate'] as double,
                  isDark,
                  (item['total'] as int) > 0,
                  isSelected: isSelected,
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
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
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
          const SizedBox(height: 4),
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

  Widget _buildBar(
    String label,
    double rate,
    bool isDark,
    bool hasDoses, {
    required bool isSelected,
    double width = 24,
  }) {
    final bool isZero = !hasDoses || rate == 0.0;
    final barHeight = isZero ? 6.0 : (80.0 * rate).clamp(10.0, 80.0);

    // Color logic per Section 19:
    // Green: High adherence (>= 80%)
    // Amber: Medium (40-79%)
    // Red: Low (< 40%) - only when scheduled doses were missed
    Color barColor;
    if (!hasDoses) {
      barColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    } else if (rate >= 0.8) {
      barColor = AppColors.success;
    } else if (rate >= 0.4) {
      barColor = AppColors.warning;
    } else {
      barColor = AppColors.error;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Percentage indicator on bar
        if (hasDoses && rate > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              '${(rate * 100).round()}%',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
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
            color: barColor,
            borderRadius: BorderRadius.circular(6),
            border: isSelected
                ? Border.all(
                    color: isDark ? Colors.white : AppColors.primary,
                    width: 2,
                  )
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: barColor.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkTextMuted : AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
