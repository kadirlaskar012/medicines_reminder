import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../screens/medicines/add_edit_medicine_screen.dart';

class EmptyMedicinesView extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final VoidCallback? onAdd;

  const EmptyMedicinesView({
    super.key,
    this.title,
    this.subtitle,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 3D Medicine Bottle with Leaves Illustration
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: isDark
                      ? [
                          AppColors.primary.withValues(alpha: 0.25),
                          Colors.transparent,
                        ]
                      : [
                          const Color(0xFFE0F2FE),
                          const Color(0xFFF0FDF4).withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                ),
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Soft Mint Leaves Backdrop
                    Positioned(
                      right: 15,
                      top: 20,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(30),
                            bottomLeft: Radius.circular(30),
                          ),
                        ),
                        child: const Icon(Icons.eco_rounded, color: Color(0xFF10B981), size: 26),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      bottom: 30,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF06B6D4).withValues(alpha: 0.2),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        child: const Icon(Icons.eco_rounded, color: Color(0xFF06B6D4), size: 18),
                      ),
                    ),

                    // Glossy 3D Bottle
                    Container(
                      width: 86,
                      height: 104,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Bottle Cap
                          Container(
                            width: 44,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Green Cross
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Title
            Text(
              title ?? 'No Medicines Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              subtitle ?? 'You haven\'t added any medicine.\nAdd your first medicine to get started.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 28),

            // CTA Button
            SizedBox(
              width: 220,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onAdd ?? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddEditMedicineScreen()),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Add Medicine',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
