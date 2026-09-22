import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/language_provider.dart';
import '../providers/medicine_provider.dart';

class CalendarTimelineBar extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const CalendarTimelineBar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<CalendarTimelineBar> createState() => _CalendarTimelineBarState();
}

class _CalendarTimelineBarState extends State<CalendarTimelineBar> {
  static const double _gap = 8.0;
  static const double _paddingH = 16.0;

  late final ScrollController _scrollController;
  late final List<DateTime> _dates;
  late final int _todayIndex;
  bool _hasScrolledToInitial = false;
  double _targetOffset = 0.0;
  bool _isScrolledAway = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _dates = List.generate(61, (i) {
      return today.subtract(Duration(days: 30 - i));
    });
    _todayIndex = 30;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasScrolledToInitial) {
      final screenWidth = MediaQuery.of(context).size.width;
      final itemWidth = (screenWidth - (_paddingH * 2) - (6 * _gap)) / 7.0;
      final targetOffset = (_todayIndex - 6) * (itemWidth + _gap);
      _targetOffset = targetOffset > 0 ? targetOffset : 0.0;
      _scrollController = ScrollController(
        initialScrollOffset: _targetOffset,
      );
      _scrollController.addListener(_onScroll);
      _hasScrolledToInitial = true;
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final diff = (_scrollController.offset - _targetOffset).abs();
    final isAway = diff > 40.0;
    if (isAway != _isScrolledAway) {
      setState(() {
        _isScrolledAway = isAway;
      });
    }
  }

  void _scrollToTodayAndSelect() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _targetOffset > 0 ? _targetOffset : 0.0,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
    widget.onDateSelected(today);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = context.watch<LanguageProvider>().strings;
    final medProvider = context.watch<MedicineProvider>();

    final isTodaySelected = widget.selectedDate.year == now.year &&
        widget.selectedDate.month == now.month &&
        widget.selectedDate.day == now.day;
    final showResetButton = !isTodaySelected || _isScrolledAway;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row: Month / Year Display + Jump to Today Button / Mini Legend
        Padding(
          padding: const EdgeInsets.fromLTRB(_paddingH, 0, _paddingH, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Month & Year display with calendar icon
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      size: 15,
                      color: isDark ? AppColors.primaryTealLight : AppColors.primaryTeal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.formatMonthYear(widget.selectedDate.month, widget.selectedDate.year),
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (!isTodaySelected) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.primaryTeal.withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        s.code == 'bn' || s.code == 'hi'
                            ? '${s.formatNumber(widget.selectedDate.day)} ${s.monthName(widget.selectedDate.month)}'
                            : DateFormat('d MMM').format(widget.selectedDate),
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.primaryTealLight : AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // Right side: Quick "Today" Reset Button OR Mini Legend
              if (showResetButton)
                GestureDetector(
                  onTap: _scrollToTodayAndSelect,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryTeal.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.restart_alt_rounded, size: 13, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          s.todayDate,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                // Mini Adherence Legend dots when centered on Today
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLegendDot(AppColors.accentEmerald, s.doneLegend),
                    const SizedBox(width: 8),
                    _buildLegendDot(AppColors.accentAmber, s.pendingLegend),
                    const SizedBox(width: 8),
                    _buildLegendDot(AppColors.accentRose, s.missedLegend),
                  ],
                ),
            ],
          ),
        ),

        // Horizontal Scrollable Date Strip (7 visible days)
        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final computedWidth = (availableWidth - (_paddingH * 2) - (6 * _gap)) / 7.0;
            final itemWidth = computedWidth < 46.0 ? 46.0 : computedWidth;

            return SizedBox(
              height: 84,
              child: ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: _paddingH),
                itemCount: _dates.length,
                separatorBuilder: (_, _) => const SizedBox(width: _gap),
                itemBuilder: (context, index) {
                  final date = _dates[index];
                  final isSelected = date.year == widget.selectedDate.year &&
                      date.month == widget.selectedDate.month &&
                      date.day == widget.selectedDate.day;
                  final isToday = date.year == now.year &&
                      date.month == now.month &&
                      date.day == now.day;
                  final isPast = date.isBefore(today);

                  // Dose adherence status for this date
                  final status = medProvider.getDateComplianceStatus(date);
                  Color? dotColor;
                  switch (status) {
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

                  Color cardBg;
                  Gradient? gradient;
                  Border border;
                  List<BoxShadow>? shadow;
                  Color dayTextColor;
                  Color numTextColor;

                  if (isSelected) {
                    // Vibrant Teal Gradient on Active Selection
                    cardBg = AppColors.primaryTeal;
                    gradient = AppColors.primaryGradient;
                    border = Border.all(
                      color: AppColors.primaryTealLight,
                      width: 1.5,
                    );
                    shadow = [
                      BoxShadow(
                        color: AppColors.primaryTeal.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ];
                    dayTextColor = Colors.white.withValues(alpha: 0.9);
                    numTextColor = Colors.white;
                  } else if (isToday) {
                    // Today (Unselected)
                    cardBg = isDark
                        ? AppColors.primaryTeal.withValues(alpha: 0.15)
                        : AppColors.primaryTeal.withValues(alpha: 0.08);
                    border = Border.all(
                      color: AppColors.primaryTeal.withValues(alpha: 0.6),
                      width: 1.5,
                    );
                    dayTextColor = isDark ? AppColors.primaryTealLight : AppColors.primaryDark;
                    numTextColor = isDark ? AppColors.primaryTealLight : AppColors.primaryDark;
                  } else if (isPast) {
                    // Past days
                    cardBg = isDark ? AppColors.darkCard : Colors.white;
                    border = Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      width: 1.0,
                    );
                    dayTextColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
                    numTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
                  } else {
                    // Future days
                    cardBg = isDark
                        ? AppColors.darkCard.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.6);
                    border = Border.all(
                      color: isDark
                          ? AppColors.darkBorder.withValues(alpha: 0.5)
                          : AppColors.lightBorder.withValues(alpha: 0.7),
                      width: 1.0,
                    );
                    dayTextColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
                    numTextColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
                  }

                  return GestureDetector(
                    onTap: () => widget.onDateSelected(date),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      width: itemWidth,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: gradient == null ? cardBg : null,
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(18),
                        border: border,
                        boxShadow: shadow,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Weekday
                          Text(
                            s.weekdayShort(date.weekday),
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: (isToday || isSelected) ? FontWeight.w800 : FontWeight.w600,
                              letterSpacing: 0.3,
                              color: dayTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          // Day Number
                          Text(
                            s.formatNumber(date.day),
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: (isToday || isSelected) ? FontWeight.w900 : FontWeight.w700,
                              color: numTextColor,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Indicator Dot / Today Pill with Adherence Status
                          if (isToday)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : (dotColor ?? AppColors.primaryTeal).withValues(alpha: isDark ? 0.22 : 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.6)
                                      : (dotColor ?? AppColors.primaryTeal).withValues(alpha: 0.4),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (dotColor != null) ...[
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.white : dotColor,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: (isSelected ? Colors.white : dotColor).withValues(alpha: 0.6),
                                            blurRadius: 3,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                  ],
                                  Text(
                                    s.today,
                                    style: GoogleFonts.outfit(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark ? AppColors.primaryTealLight : AppColors.primaryDark),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (dotColor != null)
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: dotColor,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 1.2)
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: dotColor.withValues(alpha: 0.65),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            )
                          else if (isSelected)
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            )
                          else
                            const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5.5,
          height: 5.5,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: AppColors.lightTextMuted,
          ),
        ),
      ],
    );
  }
}
