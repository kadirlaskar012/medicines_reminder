import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/language_provider.dart';

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
  static const double _gap = 6.0;
  static const double _paddingH = 16.0;

  late final ScrollController _scrollController;
  late final List<DateTime> _dates;
  late final int _todayIndex;
  bool _hasScrolledToInitial = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Generate 61 days: 30 days past, Today, 30 days future (covers full month & history)
    _dates = List.generate(61, (i) {
      return today.subtract(Duration(days: 30 - i));
    });
    _todayIndex = 30; // Index where today is located
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasScrolledToInitial) {
      final screenWidth = MediaQuery.of(context).size.width;
      final itemWidth = (screenWidth - (_paddingH * 2) - (6 * _gap)) / 7.0;
      // Position Today at the right edge of the visible 7-day strip:
      // Item at (_todayIndex - 6) is at the left edge, and Today is at the right edge.
      final targetOffset = (_todayIndex - 6) * (itemWidth + _gap);
      _scrollController = ScrollController(
        initialScrollOffset: targetOffset > 0 ? targetOffset : 0.0,
      );
      _hasScrolledToInitial = true;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = context.watch<LanguageProvider>().strings;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        // Exactly 7 cards visible across the available width
        final computedWidth = (availableWidth - (_paddingH * 2) - (6 * _gap)) / 7.0;
        final itemWidth = computedWidth < 42.0 ? 42.0 : computedWidth;

        return SizedBox(
          height: 78,
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

              // Distinct color styles for Today vs Past vs Future
              Color cardBg;
              Border border;
              List<BoxShadow>? shadow;
              Color dayTextColor;
              Color numTextColor;

              if (isToday) {
                // Today: Prominent Vibrant Brand Blue
                if (isSelected) {
                  cardBg = AppColors.primary;
                  border = Border.all(
                    color: const Color(0xFF93C5FD),
                    width: 1.8,
                  );
                  shadow = [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ];
                  dayTextColor = Colors.white.withValues(alpha: 0.95);
                  numTextColor = Colors.white;
                } else {
                  cardBg = isDark
                      ? const Color(0xFF1E3A8A).withValues(alpha: 0.28)
                      : const Color(0xFFEFF6FF);
                  border = Border.all(
                    color: AppColors.primary,
                    width: 2.0,
                  );
                  dayTextColor = AppColors.primary;
                  numTextColor = AppColors.primary;
                }
              } else if (isPast) {
                // Past Days: Distinct Slate / Neutral tones
                if (isSelected) {
                  cardBg = isDark ? const Color(0xFF334155) : const Color(0xFF475569);
                  border = Border.all(
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF334155),
                    width: 1.8,
                  );
                  shadow = [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ];
                  dayTextColor = Colors.white.withValues(alpha: 0.9);
                  numTextColor = Colors.white;
                } else {
                  cardBg = isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9);
                  border = Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    width: 1.0,
                  );
                  dayTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
                  numTextColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
                }
              } else {
                // Future / Upcoming Days (revealed on scroll right)
                if (isSelected) {
                  cardBg = AppColors.primaryDark;
                  border = Border.all(color: AppColors.primary, width: 1.5);
                  dayTextColor = Colors.white.withValues(alpha: 0.9);
                  numTextColor = Colors.white;
                } else {
                  cardBg = isDark
                      ? AppColors.darkCard.withValues(alpha: 0.35)
                      : AppColors.lightSurface.withValues(alpha: 0.65);
                  border = Border.all(
                    color: isDark
                        ? const Color(0xFF334155).withValues(alpha: 0.5)
                        : const Color(0xFFE2E8F0).withValues(alpha: 0.8),
                    width: 1.0,
                  );
                  dayTextColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
                  numTextColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
                }
              }

              return GestureDetector(
                onTap: () => widget.onDateSelected(date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: itemWidth,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(15),
                    border: border,
                    boxShadow: shadow,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Weekday name
                      Text(
                        s.weekdayShort(date.weekday),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                          letterSpacing: 0.2,
                          color: dayTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      // Day number
                      Text(
                        DateFormat('d').format(date),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: (isToday || isSelected) ? FontWeight.w900 : FontWeight.w700,
                          color: numTextColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Bottom Indicator / Today Pill Badge
                      if (isToday)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.25)
                                : AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            s.today,
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : AppColors.primary,
                            ),
                          ),
                        )
                      else if (isPast && isSelected)
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white70,
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
    );
  }
}
