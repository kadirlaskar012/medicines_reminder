import 'package:flutter/material.dart';
import '../core/constants/app_svg_icons.dart';
import '../models/medicine.dart';

class PillIconBadge extends StatelessWidget {
  final MedicineType type;
  final Color color;
  final double size;

  const PillIconBadge({
    super.key,
    required this.type,
    required this.color,
    this.size = 54,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.36),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          const BoxShadow(
            color: Colors.white24,
            blurRadius: 4,
            offset: Offset(0, -1),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.2),
      child: Center(
        child: AppSvgIcons.render(
          type.svgString,
          width: size * 0.6,
          height: size * 0.6,
          color: color,
        ),
      ),
    );
  }
}
