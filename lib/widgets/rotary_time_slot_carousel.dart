import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../models/reminder_time.dart';
import '../providers/language_provider.dart';

class RotaryTimeSlotCarousel extends StatefulWidget {
  final TimeSlot? selectedSlot; // null = All Doses
  final int totalDosesCount;
  final Map<TimeSlot, int> doseCounts;
  final Function(TimeSlot?) onSlotChanged;

  const RotaryTimeSlotCarousel({
    super.key,
    required this.selectedSlot,
    required this.totalDosesCount,
    required this.doseCounts,
    required this.onSlotChanged,
  });

  @override
  State<RotaryTimeSlotCarousel> createState() => _RotaryTimeSlotCarouselState();
}

class _RotaryTimeSlotCarouselState extends State<RotaryTimeSlotCarousel> {
  static const List<TimeSlot> _slots = [
    TimeSlot.morning,
    TimeSlot.afternoon,
    TimeSlot.evening,
    TimeSlot.night,
  ];

  late int _focusedIndex;

  static TimeSlot get currentLiveTimeSlot {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) return TimeSlot.morning;
    if (hour >= 12 && hour < 17) return TimeSlot.afternoon;
    if (hour >= 17 && hour < 21) return TimeSlot.evening;
    return TimeSlot.night;
  }

  @override
  void initState() {
    super.initState();
    if (widget.selectedSlot != null) {
      _focusedIndex = _slots.indexOf(widget.selectedSlot!);
    } else {
      _focusedIndex = _slots.indexOf(currentLiveTimeSlot);
    }
  }

  @override
  void didUpdateWidget(RotaryTimeSlotCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedSlot != null && widget.selectedSlot != oldWidget.selectedSlot) {
      _focusedIndex = _slots.indexOf(widget.selectedSlot!);
    }
  }

  void _rotateLeft() {
    setState(() {
      _focusedIndex = (_focusedIndex - 1 + _slots.length) % _slots.length;
    });
    widget.onSlotChanged(_slots[_focusedIndex]);
  }

  void _rotateRight() {
    setState(() {
      _focusedIndex = (_focusedIndex + 1) % _slots.length;
    });
    widget.onSlotChanged(_slots[_focusedIndex]);
  }

  String _getSlotTitle(TimeSlot slot, dynamic s) {
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

  String _getSlotEmoji(TimeSlot slot) {
    switch (slot) {
      case TimeSlot.morning:
        return '🌅';
      case TimeSlot.afternoon:
        return '☀️';
      case TimeSlot.evening:
        return '☕';
      case TimeSlot.night:
        return '🌙';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = context.watch<LanguageProvider>().strings;
    final now = DateTime.now();
    final liveSlot = currentLiveTimeSlot;

    final isAllDosesActive = widget.selectedSlot == null;

    final prevIndex = (_focusedIndex - 1 + _slots.length) % _slots.length;
    final nextIndex = (_focusedIndex + 1) % _slots.length;

    final prevSlot = _slots[prevIndex];
    final centerSlot = _slots[_focusedIndex];
    final nextSlot = _slots[nextIndex];

    final isCenterLiveNow = centerSlot == liveSlot;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Row: "All Doses" Master Button (Left) + Live Clock Chip (Right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // All Doses Button
              GestureDetector(
                onTap: () {
                  widget.onSlotChanged(null);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: isAllDosesActive ? AppColors.primaryGradient : null,
                    color: isAllDosesActive
                        ? null
                        : (isDark ? AppColors.darkCardElevated : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAllDosesActive
                          ? AppColors.primaryTealLight
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      width: isAllDosesActive ? 1.5 : 1,
                    ),
                    boxShadow: isAllDosesActive
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
                      Icon(
                        Icons.medication_rounded,
                        size: 15,
                        color: isAllDosesActive ? Colors.white : AppColors.primaryTeal,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        s.code == 'bn'
                            ? 'সব ওষুধ (${widget.totalDosesCount})'
                            : 'All Doses (${widget.totalDosesCount})',
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: isAllDosesActive
                              ? Colors.white
                              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        ),
                      ),
                      if (isAllDosesActive) ...[
                        const SizedBox(width: 5),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Live Clock Status Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.accentEmerald,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentEmerald.withValues(alpha: 0.8),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${DateFormat('hh:mm a').format(now)} · ${_getSlotTitle(liveSlot, s)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 2. Rotary Dial Row (Left Arrow < | Prev Slot | Center Focus Slot | Next Slot | Right Arrow >)
          GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null) {
                if (details.primaryVelocity! < -150) {
                  // Swiped left -> rotate clockwise
                  _rotateRight();
                } else if (details.primaryVelocity! > 150) {
                  // Swiped right -> rotate counter-clockwise
                  _rotateLeft();
                }
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Arrow Button (<)
                _buildArrowButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: _rotateLeft,
                  isDark: isDark,
                ),

                const SizedBox(width: 6),

                // Left Slot Card (Previous)
                Expanded(
                  flex: 2,
                  child: _buildSideSlotCard(
                    slot: prevSlot,
                    count: widget.doseCounts[prevSlot] ?? 0,
                    onTap: _rotateLeft,
                    s: s,
                    isDark: isDark,
                  ),
                ),

                const SizedBox(width: 8),

                // Center Slot Card (Prominent Live Center)
                Expanded(
                  flex: 3,
                  child: _buildCenterSlotCard(
                    slot: centerSlot,
                    count: widget.doseCounts[centerSlot] ?? 0,
                    isLiveNow: isCenterLiveNow,
                    isSelected: !isAllDosesActive && widget.selectedSlot == centerSlot,
                    onTap: () {
                      if (!isAllDosesActive && widget.selectedSlot == centerSlot) {
                        // Toggle back to All Doses
                        widget.onSlotChanged(null);
                      } else {
                        widget.onSlotChanged(centerSlot);
                      }
                    },
                    s: s,
                    isDark: isDark,
                  ),
                ),

                const SizedBox(width: 8),

                // Right Slot Card (Next)
                Expanded(
                  flex: 2,
                  child: _buildSideSlotCard(
                    slot: nextSlot,
                    count: widget.doseCounts[nextSlot] ?? 0,
                    onTap: _rotateRight,
                    s: s,
                    isDark: isDark,
                  ),
                ),

                const SizedBox(width: 6),

                // Right Arrow Button (>)
                _buildArrowButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: _rotateRight,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // 3. Center Arrow Indicator (▲)
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 3),
              child: Icon(
                Icons.arrow_drop_up_rounded,
                size: 22,
                color: (!isAllDosesActive && widget.selectedSlot == centerSlot)
                    ? centerSlot.color
                    : (isCenterLiveNow ? AppColors.primaryTeal : (isDark ? Colors.white30 : Colors.black26)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrowButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 32,
        height: 54,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardElevated : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.8,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
      ),
    );
  }

  Widget _buildSideSlotCard({
    required TimeSlot slot,
    required int count,
    required VoidCallback onTap,
    required dynamic s,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardElevated.withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder.withValues(alpha: 0.6) : AppColors.lightBorder,
            width: 0.8,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_getSlotEmoji(slot), style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 3),
            Text(
              _getSlotTitle(slot, s),
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              '$count',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: slot.color.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterSlotCard({
    required TimeSlot slot,
    required int count,
    required bool isLiveNow,
    required bool isSelected,
    required VoidCallback onTap,
    required dynamic s,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [slot.color, slot.color.withValues(alpha: 0.85)]
                : [
                    slot.color.withValues(alpha: isDark ? 0.22 : 0.12),
                    slot.color.withValues(alpha: isDark ? 0.12 : 0.05),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : slot.color,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: slot.color.withValues(alpha: isSelected ? 0.45 : 0.2),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_getSlotEmoji(slot), style: const TextStyle(fontSize: 17)),
                const SizedBox(width: 5),
                Text(
                  _getSlotTitle(slot, s),
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white : slot.color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLiveNow) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.3)
                          : AppColors.accentEmerald.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? Colors.white
                            : AppColors.accentEmerald,
                        width: 0.6,
                      ),
                    ),
                    child: Text(
                      s.code == 'bn' ? '● এখন' : '● NOW',
                      style: GoogleFonts.outfit(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? Colors.white : AppColors.accentEmerald,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  count == 1
                      ? (s.code == 'bn' ? '১টি ওষুধ' : '1 dose')
                      : (s.code == 'bn' ? '$countটি ওষুধ' : '$count doses'),
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.95)
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
