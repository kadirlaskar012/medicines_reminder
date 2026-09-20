import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class DualToneCapsule extends StatelessWidget {
  final double size;
  final Color primaryColor;
  final Color secondaryColor;
  final double angle;
  final bool hasGlow;

  const DualToneCapsule({
    super.key,
    this.size = 48,
    this.primaryColor = Colors.white,
    this.secondaryColor = const Color(0xFFE2E8F0),
    this.angle = -math.pi / 4, // 45 degree tilt
    this.hasGlow = false,
  });

  factory DualToneCapsule.fromIndex(int index, {double size = 48, bool hasGlow = false}) {
    final colors = AppColors.getDualCapsuleColor(index);
    return DualToneCapsule(
      size: size,
      primaryColor: colors[0],
      secondaryColor: colors[1],
      hasGlow: hasGlow,
    );
  }

  factory DualToneCapsule.paracetamol({double size = 48, bool hasGlow = false}) {
    return DualToneCapsule(
      size: size,
      primaryColor: const Color(0xFFEF4444),
      secondaryColor: const Color(0xFF06B6D4),
      hasGlow: hasGlow,
    );
  }

  factory DualToneCapsule.vitaminD3({double size = 48, bool hasGlow = false}) {
    return DualToneCapsule(
      size: size,
      primaryColor: const Color(0xFFF59E0B),
      secondaryColor: const Color(0xFFFEF08A),
      hasGlow: hasGlow,
    );
  }

  factory DualToneCapsule.amoxicillin({double size = 48, bool hasGlow = false}) {
    return DualToneCapsule(
      size: size,
      primaryColor: const Color(0xFFEF4444),
      secondaryColor: const Color(0xFFFFFFFF),
      hasGlow: hasGlow,
    );
  }

  factory DualToneCapsule.calcium({double size = 48, bool hasGlow = false}) {
    return DualToneCapsule(
      size: size,
      primaryColor: const Color(0xFF10B981),
      secondaryColor: const Color(0xFF67E8F9),
      hasGlow: hasGlow,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CapsulePainter(
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
          angle: angle,
          hasGlow: hasGlow,
        ),
      ),
    );
  }
}

class _CapsulePainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final double angle;
  final bool hasGlow;

  _CapsulePainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.angle,
    required this.hasGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final width = size.width * 0.42;
    final height = size.height * 0.88;
    final radius = width / 2;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final capsuleRect = Rect.fromCenter(center: Offset.zero, width: width, height: height);
    final isWhiteOrLight = primaryColor.computeLuminance() > 0.82;

    // 1. Drop shadow / Glow
    if (hasGlow) {
      final glowPaint = Paint()
        ..color = isWhiteOrLight
            ? Colors.black.withValues(alpha: 0.22)
            : primaryColor.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
      canvas.drawRRect(RRect.fromRectAndRadius(capsuleRect, Radius.circular(radius)), glowPaint);
    } else {
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: isWhiteOrLight ? 0.18 : 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(capsuleRect.shift(const Offset(1.5, 2.5)), Radius.circular(radius)),
        shadowPaint,
      );
    }

    // Clip to capsule shape for 3D dual split
    final capsuleRRect = RRect.fromRectAndRadius(capsuleRect, Radius.circular(radius));
    canvas.save();
    canvas.clipRRect(capsuleRRect);

    // 2. Draw Top Half (Primary)
    final topRect = Rect.fromLTRB(
      -width / 2,
      -height / 2,
      width / 2,
      0,
    );
    final topPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isWhiteOrLight
            ? [
                Colors.white,
                Colors.white,
                const Color(0xFFF1F5F9),
              ]
            : [
                primaryColor.withValues(alpha: 0.9),
                primaryColor,
                HSLColor.fromColor(primaryColor).withLightness(
                  (HSLColor.fromColor(primaryColor).lightness - 0.15).clamp(0.0, 1.0),
                ).toColor(),
              ],
      ).createShader(topRect);
    canvas.drawRect(Rect.fromLTRB(-width, -height, width, 0), topPaint);

    // 3. Draw Bottom Half (Secondary)
    final bottomRect = Rect.fromLTRB(
      -width / 2,
      0,
      width / 2,
      height / 2,
    );
    final bottomPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isWhiteOrLight
            ? [
                const Color(0xFFF1F5F9),
                const Color(0xFFE2E8F0),
                const Color(0xFFCBD5E1),
              ]
            : [
                secondaryColor.withValues(alpha: 0.9),
                secondaryColor,
                HSLColor.fromColor(secondaryColor).withLightness(
                  (HSLColor.fromColor(secondaryColor).lightness - 0.15).clamp(0.0, 1.0),
                ).toColor(),
              ],
      ).createShader(bottomRect);
    canvas.drawRect(Rect.fromLTRB(-width, 0, width, height), bottomPaint);

    // 4. Center seam line
    final seamPaint = Paint()
      ..color = isWhiteOrLight
          ? const Color(0xFF94A3B8)
          : Colors.black.withValues(alpha: 0.22)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(-width / 2, 0), Offset(width / 2, 0), seamPaint);

    // 5. 3D Specular Highlight / Curved Glare
    final highlightPath = Path()
      ..moveTo(-width * 0.28, -height * 0.42)
      ..quadraticBezierTo(
        -width * 0.38,
        0,
        -width * 0.28,
        height * 0.42,
      );
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: isWhiteOrLight ? 0.75 : 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * 0.14
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(highlightPath, highlightPaint);

    canvas.restore(); // Restore clip

    // 6. Perimeter Outline / Border (Ensures crisp contrast against any background)
    final borderPaint = Paint()
      ..color = isWhiteOrLight
          ? const Color(0xFFCBD5E1)
          : primaryColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(capsuleRRect, borderPaint);

    canvas.restore(); // Restore transform
  }

  @override
  bool shouldRepaint(covariant _CapsulePainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.angle != angle ||
        oldDelegate.hasGlow != hasGlow;
  }
}
