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
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Image.asset(
          type.assetPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => AppSvgIcons.render(
            type.svgString,
            width: size * 0.7,
            height: size * 0.7,
            color: color,
          ),
        ),
      ),
    );
  }
}
