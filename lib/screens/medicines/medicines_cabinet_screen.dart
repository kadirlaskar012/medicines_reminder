import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../models/medicine.dart';
import '../../models/reminder_time.dart';
import '../../providers/language_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../widgets/dual_tone_capsule.dart';
import '../../widgets/empty_medicines_view.dart';
import '../../widgets/medicine_info_stock_sheet.dart';
import '../../widgets/stock_meter_bar.dart';
import 'add_edit_medicine_screen.dart';
import 'medicine_details_screen.dart';

class MedicinesCabinetScreen extends StatefulWidget {
  const MedicinesCabinetScreen({super.key});

  @override
  State<MedicinesCabinetScreen> createState() => _MedicinesCabinetScreenState();
}

class _MedicinesCabinetScreenState extends State<MedicinesCabinetScreen> {
  String _searchQuery = '';
  String _selectedStatusTab = 'All'; // All, Active, Completed

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<MedicineProvider>();
    final s = context.watch<LanguageProvider>().strings;
    final allMeds = provider.filteredMedicines;

    // Apply filtering & search
    final activeCount = allMeds.where((m) => m.isActive && !m.isExpired).length;
    final pausedCount = allMeds.where((m) => !m.isActive && !m.isExpired).length;
    final completedCount = allMeds.where((m) => m.isExpired).length;

    final filtered = allMeds.where((m) {
      final matchesSearch = m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.dosage.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      if (_selectedStatusTab == 'Active') return m.isActive && !m.isExpired;
      if (_selectedStatusTab == 'Paused') return !m.isActive && !m.isExpired;
      if (_selectedStatusTab == 'Completed') return m.isExpired;

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(s.medicinesTab),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 28),
            tooltip: s.addNewMedicine,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditMedicineScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                decoration: InputDecoration(
                  hintText: s.searchMedicineHint,
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // 2. Status Segmented Tabs [All (N)] | [Active (N)] | [Paused (N)] | [Completed (N)]
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _buildTabItem('All', s.all, allMeds.length, isDark),
                  _buildTabItem('Active', s.activeStatus, activeCount, isDark),
                  _buildTabItem('Paused', s.code == 'bn' ? 'স্থগিত' : (s.code == 'hi' ? 'रोकी गई' : 'Paused'), pausedCount, isDark),
                  _buildTabItem('Completed', s.courseCompleted, completedCount, isDark),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 3. Medicine List or Empty View
          Expanded(
            child: filtered.isEmpty
                ? const EmptyMedicinesView()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
                    itemCount: filtered.length,
                    itemBuilder: (context, idx) {
                      final med = filtered[idx];
                      final reminders = provider.getRemindersForMedicine(med.id);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MedicineDetailsScreen(medicine: med),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(22),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkCardElevated : const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                        ),
                                      ),
                                      child: Center(
                                        child: DualToneCapsule.fromIndex(
                                          med.colorValue,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  med.name,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                                    letterSpacing: -0.2,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (!med.isActive) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    'Paused',
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w700,
                                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${med.dosage.isNotEmpty ? med.dosage : "500 mg"} · ${s.medicineTypeName(med.type.name)}',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 6,
                                            children: reminders.map((r) {
                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryTeal.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  r.formattedTime,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark ? AppColors.primaryTealLight : AppColors.primaryTeal,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch.adaptive(
                                      value: med.isActive,
                                      activeTrackColor: AppColors.accentEmerald,
                                      inactiveTrackColor: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                      onChanged: (val) async {
                                        await provider.toggleMedicineActive(med);
                                      },
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert_rounded),
                                      onSelected: (val) async {
                                        if (val == 'details') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => MedicineDetailsScreen(medicine: med),
                                            ),
                                          );
                                        } else if (val == 'edit') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => AddEditMedicineScreen(medicineToEdit: med),
                                            ),
                                          );
                                        } else if (val == 'toggle_pause') {
                                          await provider.toggleMedicineActive(med);
                                        } else if (val == 'refill') {
                                          _showRefillDialog(context, med, s);
                                        } else if (val == 'duplicate') {
                                          final dupRems = reminders.map((r) => ReminderTime(
                                            id: '',
                                            medicineId: '',
                                            hour: r.hour,
                                            minute: r.minute,
                                            daysOfWeek: r.daysOfWeek,
                                            isAlarm: r.isAlarm,
                                            notificationId: DateTime.now().millisecondsSinceEpoch % 100000,
                                          )).toList();
                                          await provider.addMedicine(
                                            name: '${med.name} (Copy)',
                                            dosage: med.dosage,
                                            type: med.type,
                                            colorValue: med.colorValue,
                                            instruction: med.instruction,
                                            currentStock: med.currentStock,
                                            refillThreshold: med.refillThreshold,
                                            unit: med.unit,
                                            notes: med.notes,
                                            reminderTimes: dupRems,
                                          );
                                        } else if (val == 'delete') {
                                          _confirmDelete(context, med, s);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'details',
                                          child: Row(
                                            children: [
                                              Icon(Icons.info_outline_rounded, size: 18),
                                              SizedBox(width: 8),
                                              Text('Details'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.edit_rounded, size: 18),
                                              const SizedBox(width: 8),
                                              Text(s.editMedicine),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'toggle_pause',
                                          child: Row(
                                            children: [
                                              Icon(med.isActive ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded, size: 18),
                                              const SizedBox(width: 8),
                                              Text(med.isActive ? 'Pause Reminders' : 'Resume Reminders'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'refill',
                                          child: Row(
                                            children: [
                                              Icon(Icons.add_shopping_cart_rounded, size: 18),
                                              SizedBox(width: 8),
                                              Text('Refill / Update Stock'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'duplicate',
                                          child: Row(
                                            children: [
                                              Icon(Icons.copy_rounded, size: 18),
                                              SizedBox(width: 8),
                                              Text('Duplicate'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuDivider(),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                              const SizedBox(width: 8),
                                              Text(s.deleteMedicine, style: const TextStyle(color: AppColors.error)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                const Divider(height: 1, thickness: 0.6),
                                const SizedBox(height: 12),

                                // Dynamic Stock Meter Bar with 1-Tap Refill
                                StockMeterBar(
                                  currentStock: med.currentStock,
                                  totalCapacity: (med.refillThreshold * 4).clamp(10, 200),
                                  threshold: med.refillThreshold,
                                  unit: med.displayUnit,
                                  onRefillTap: () => _showRefillDialog(context, med, s),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Left: Edit badge
                                    InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => AddEditMedicineScreen(medicineToEdit: med)),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppColors.darkCardElevated : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.edit_outlined, size: 13, color: AppColors.primaryTealLight),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Edit',
                                              style: GoogleFonts.outfit(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Right: Info & Stock badge
                                    InkWell(
                                      onTap: () => MedicineInfoStockSheet.show(context, med),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryTeal.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: AppColors.primaryTeal.withValues(alpha: 0.3),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.inventory_2_outlined, size: 13, color: AppColors.primaryTealLight),
                                            const SizedBox(width: 5),
                                            Text(
                                              'Info & Stock',
                                              style: GoogleFonts.outfit(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? AppColors.primaryTealLight : AppColors.primaryTeal,
                                              ),
                                            ),
                                            if (med.isLowStock || med.isOutOfStock) ...[
                                              const SizedBox(width: 4),
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.accentRose,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.04, end: 0, duration: 250.ms);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String key, String label, int count, bool isDark) {
    final isSelected = _selectedStatusTab == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedStatusTab = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? (isDark ? const Color(0xFF0B132B) : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))]
                : null,
          ),
          child: Text(
            '$label ($count)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? AppColors.primary : (isDark ? Colors.white60 : Colors.black54),
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  void _showRefillDialog(BuildContext context, Medicine med, AppStrings s) {
    final qtyCtrl = TextEditingController(text: '${med.type.defaultStock}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.add_shopping_cart_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(s.refillStockTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${s.medicineName}: ${med.name}'),
            const SizedBox(height: 6),
            Text('${s.currentQuantity}: ${med.formattedStock}'),
            const SizedBox(height: 16),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: '${s.addedPillsCount} (${s.unitName(med.displayUnit)})',
                suffixText: s.unitName(med.displayUnit),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final added = int.tryParse(qtyCtrl.text.trim()) ?? 0;
              if (added > 0) {
                Navigator.pop(ctx);
                final updatedMed = med.copyWith(currentStock: med.currentStock + added);
                final provider = context.read<MedicineProvider>();
                final rems = provider.getRemindersForMedicine(med.id);
                await provider.updateMedicine(medicine: updatedMed, reminders: rems);
              }
            },
            child: Text(s.addStockBtn),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Medicine med, AppStrings s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          s.code == 'bn' ? '"${med.name}" মুছে ফেলবেন?' : 'Delete "${med.name}"?',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          s.code == 'bn'
              ? 'এটি এর ভবিষ্যৎ সকল রিমাইন্ডার এবং ওষুধের ইতিহাস মুছে ফেলবে।'
              : (s.code == 'hi'
                  ? 'यह इसके भविष्य के अलार्म और दवा का इतिहास हटा देगा।'
                  : 'This will remove its future reminders and medication history.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<MedicineProvider>().deleteMedicine(med.id);
            },
            child: Text(s.delete),
          ),
        ],
      ),
    );
  }
}
