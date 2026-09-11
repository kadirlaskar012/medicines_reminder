import 'package:flutter/material.dart';
import '../core/constants/app_svg_icons.dart';
import '../core/theme/app_colors.dart';

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
    final percentage = (rate * 100).toInt();

    String title;
    String subtitle;
    Color accentColor = AppColors.primary;
    Widget? streakBadge;

    if (totalCount == 0) {
      title = 'No Doses Today';
      subtitle = 'You are all clear for today!';
    } else if (takenCount == totalCount) {
      title = 'All Done for Today!';
      subtitle = 'Great job staying on track with your health.';
      accentColor = AppColors.success;
      streakBadge = AppSvgIcons.render(AppSvgIcons.celebration, width: 36, height: 36);
    } else if (takenCount > 0) {
      title = '$takenCount of $totalCount Doses Taken';
      subtitle = 'Keep going, timely medication is key!';
      accentColor = AppColors.primary;
      streakBadge = AppSvgIcons.render(AppSvgIcons.fireStreak, width: 32, height: 32);
    } else {
      title = 'Pending Doses';
      subtitle = 'You have $totalCount doses scheduled today.';
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

