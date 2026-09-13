import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_svg_icons.dart';
import '../core/theme/app_colors.dart';
import '../providers/language_provider.dart';

class AdherenceRing extends StatelessWidget {
  final double rate;
  final int takenCount;
  final int totalCount;

  const AdherenceRing({
    super.key,
    required this.rate,
    required this.takenCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = context.watch<LanguageProvider>().strings;
    final percentage = (rate * 100).toInt();

    String title;
    String subtitle;
    Color accentColor = AppColors.primary;
    Widget? streakBadge;

    if (totalCount == 0) {
      title = s.noDosesScheduled;
      subtitle = s.tapToAddFirst;
    } else if (takenCount == totalCount) {
      title = s.allDoneToday;
      subtitle = s.allDoneSub;
      accentColor = AppColors.success;
      streakBadge = AppSvgIcons.render(AppSvgIcons.celebration, width: 36, height: 36);
    } else if (takenCount > 0) {
      title = '$takenCount / $totalCount ${s.taken}';
      subtitle = '${totalCount - takenCount} ${s.dosesRemaining}';
      accentColor = AppColors.primary;
      streakBadge = AppSvgIcons.render(AppSvgIcons.fireStreak, width: 32, height: 32);
    } else {
      title = s.due;
      subtitle = '$totalCount ${s.dosesRemaining}';
      accentColor = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 68,
                height: 68,
                child: CircularProgressIndicator(
                  value: totalCount == 0 ? 1.0 : rate,
                  strokeWidth: 7,
                  strokeCap: StrokeCap.round,
                  backgroundColor: accentColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),
              Text(
                totalCount == 0 ? '100%' : '$percentage%',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (streakBadge != null) ...[
            const SizedBox(width: 12),
            streakBadge,
          ],
        ],
      ),
    );
  }
}

