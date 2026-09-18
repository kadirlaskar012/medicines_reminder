import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/language_provider.dart';

class AdherenceRing extends StatelessWidget {
  final double rate;
  final int takenCount;
  final int totalCount;
  final int streakDays;

  const AdherenceRing({
    super.key,
    required this.rate,
    required this.takenCount,
    required this.totalCount,
    this.streakDays = 5,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = context.watch<LanguageProvider>().strings;
    final percentage = (rate * 100).toInt();

    String title;
    String subtitle;
    Color accentColor = AppColors.primaryTealLight;

    if (totalCount == 0) {
      title = s.noDosesScheduled;
      subtitle = s.tapToAddFirst;
    } else if (takenCount == totalCount) {
      title = s.allDoneToday;
      subtitle = s.allDoneSub;
      accentColor = AppColors.accentEmerald;
    } else if (takenCount > 0) {
      title = '$takenCount / $totalCount ${s.taken}';
      subtitle = '${totalCount - takenCount} ${s.dosesRemaining}';
      accentColor = AppColors.primaryTealLight;
    } else {
      title = s.due;
      subtitle = '$totalCount ${s.dosesRemaining}';
      accentColor = AppColors.accentAmber;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.primaryTeal.withValues(alpha: 0.18),
                  AppColors.accentCyan.withValues(alpha: 0.08),
                  AppColors.darkCard,
                ]
              : [
                  AppColors.primaryTeal.withValues(alpha: 0.08),
                  AppColors.accentCyan.withValues(alpha: 0.04),
                  Colors.white,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: isDark ? 0.28 : 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withValues(alpha: isDark ? 0.16 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: Hero Info & Streak Flame Pill
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Tag Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryTeal.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accentEmerald,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentEmerald.withValues(alpha: 0.8),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'DAILY ADHERENCE',
                        style: GoogleFonts.outfit(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: isDark ? AppColors.primaryTealLight : AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),

                // Main Title
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),

                // Subtitle
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 6),

                // Streak Flame Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: AppColors.accentAmber.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.accentAmber.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 4),
                      Text(
                        '$streakDays-Day Streak! Keep going!',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentAmber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Right: Circular Gradient Progress Ring
          SizedBox(
            width: 66,
            height: 66,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(66, 66),
                  painter: _GradientProgressPainter(
                    progress: totalCount == 0 ? 1.0 : rate.clamp(0.0, 1.0),
                    trackColor: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.5),
                    gradientColors: [
                      AppColors.primaryTealLight,
                      AppColors.accentCyan,
                      accentColor,
                    ],
                    strokeWidth: 6.5,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      totalCount == 0 ? '100%' : '$percentage%',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'TODAY',
                      style: GoogleFonts.outfit(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0, duration: 300.ms);
  }
}

class _GradientProgressPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final List<Color> gradientColors;
  final double strokeWidth;

  _GradientProgressPainter({
    required this.progress,
    required this.trackColor,
    required this.gradientColors,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Progress arc with gradient shader
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepAngle = 2 * math.pi * progress;

    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: gradientColors,
        startAngle: -math.pi / 2,
        endAngle: (3 * math.pi / 2),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi / 2);
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: radius),
      0,
      sweepAngle,
      false,
      progressPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GradientProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

