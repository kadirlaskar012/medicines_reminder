import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../models/medicine.dart';
import '../../models/reminder_time.dart';
import '../../providers/language_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../widgets/medicine_visual.dart';
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
  String _sortBy = 'az'; // Default Alphabetical A-Z, 'za', 'newest', 'lowStock'
  MedicineType? _selectedTypeFilter; // null means All Types

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

      if (_selectedTypeFilter != null && m.type != _selectedTypeFilter) {
        return false;
      }

      return true;
    }).toList();

    // Default Alphabetical A-Z sorting, plus interactive sorting
    if (_sortBy == 'az') {
      filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (_sortBy == 'za') {
      filtered.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    } else if (_sortBy == 'newest') {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortBy == 'lowStock') {
      filtered.sort((a, b) => a.currentStock.compareTo(b.currentStock));
    }

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
          // 1. Search Bar (Luxury Elevated Frosted Design)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
                style: GoogleFonts.outfit(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: s.searchMedicineHint,
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D9488), Color(0xFF06B6D4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.search_rounded, color: Colors.white, size: 18),
                    ),
                  ),
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
                color: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  _buildTabItem('All', s.all, allMeds.length, isDark, s),
                  _buildTabItem('Active', s.activeStatus, activeCount, isDark, s),
                  _buildTabItem('Paused', s.pausedLabel, pausedCount, isDark, s),
                  _buildTabItem('Completed', s.courseCompleted, completedCount, isDark, s),
                ],
              ),
            ),
          ),

          // 3. Sort & Filter Controls Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Row(
              children: [
                // Sort By Button
                InkWell(
                  onTap: () => _showSortBottomSheet(context, s, isDark),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sort_by_alpha_rounded, size: 15, color: AppColors.primaryTealLight),
                        const SizedBox(width: 5),
                        Text(
                          _getSortLabel(s),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(Icons.arrow_drop_down_rounded, size: 16, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Filter by Type Button
                InkWell(
                  onTap: () => _showFilterBottomSheet(context, s, isDark, allMeds),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _selectedTypeFilter != null
                          ? AppColors.primaryTeal.withValues(alpha: 0.15)
                          : (isDark ? AppColors.darkSurface : Colors.white),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedTypeFilter != null
                            ? AppColors.primaryTeal
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.filter_list_rounded,
                          size: 15,
                          color: _selectedTypeFilter != null
                              ? AppColors.primaryTealLight
                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _selectedTypeFilter == null
                              ? s.allTypes
                              : s.medicineTypeName(_selectedTypeFilter!.name),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: _selectedTypeFilter != null ? FontWeight.w700 : FontWeight.w600,
                            color: _selectedTypeFilter != null
                                ? (isDark ? AppColors.primaryTealLight : AppColors.primaryTeal)
                                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                          ),
                        ),
                        if (_selectedTypeFilter != null) ...[
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => setState(() => _selectedTypeFilter = null),
                            child: const Icon(Icons.close_rounded, size: 14, color: AppColors.primaryTealLight),
                          ),
                        ] else ...[
                          const SizedBox(width: 3),
                          Icon(Icons.arrow_drop_down_rounded, size: 16, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary),
                        ],
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Total counter badge
                Text(
                  s.medsCountShort(filtered.length),
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // 4. Medicine List or Empty View
          Expanded(
            child: filtered.isEmpty
                ? const EmptyMedicinesView()
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
                    itemCount: filtered.length,
                    itemBuilder: (context, idx) {
                      final med = filtered[idx];
                      final reminders = provider.getRemindersForMedicine(med.id);

                      final itemWidget = Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : AppColors.lightBorder,
                            width: 1.2,
                          ),
                          boxShadow: AppColors.glossyCardShadow(isDark),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                height: 24,
                                child: IgnorePointer(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: isDark
                                          ? AppColors.glossySheenDark
                                          : AppColors.glossySheenLight,
                                    ),
                                  ),
                                ),
                              ),
                              InkWell(
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
                                    _buildMedicineSquircleIcon(med, isDark),
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
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: med.isActive
                                                      ? AppColors.accentEmerald.withValues(alpha: 0.12)
                                                      : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: med.isActive
                                                        ? AppColors.accentEmerald.withValues(alpha: 0.3)
                                                        : Colors.transparent,
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
                                                        color: med.isActive ? AppColors.accentEmerald : (isDark ? Colors.white38 : Colors.black38),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      med.isActive ? s.activeLabel : s.pausedLabel,
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w700,
                                                        color: med.isActive ? AppColors.accentEmerald : (isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Text(
                                                '${med.dosage.isNotEmpty ? med.dosage : "500 mg"} · ${s.medicineTypeName(med.type.name)}',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary,
                                                ),
                                              ),
                                              if (med.isLowStock || med.isOutOfStock) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                  decoration: BoxDecoration(
                                                    color: (med.isOutOfStock ? AppColors.accentRose : AppColors.accentAmber).withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: (med.isOutOfStock ? AppColors.accentRose : AppColors.accentAmber).withValues(alpha: 0.4),
                                                      width: 0.8,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    med.isOutOfStock
                                                        ? s.outOfStockLabel
                                                        : s.leftStockCount(med.currentStock),
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w700,
                                                      color: med.isOutOfStock ? AppColors.accentRose : AppColors.accentAmber,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 5),
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
                                        if (val == 'details' || val == 'timings') {
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
                                        PopupMenuItem(
                                          value: 'details',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.info_outline_rounded, size: 18),
                                              const SizedBox(width: 8),
                                              Text(s.viewDetails),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'timings',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.alarm_rounded, size: 18, color: AppColors.primary),
                                              const SizedBox(width: 8),
                                              Text(s.scheduledAlarmsTitle),
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
                                              Text(med.isActive ? s.pauseReminders : s.resumeReminders),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'refill',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.add_shopping_cart_rounded, size: 18),
                                              const SizedBox(width: 8),
                                              Text(s.refillOrUpdateStock),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'duplicate',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.copy_rounded, size: 18),
                                              const SizedBox(width: 8),
                                              Text(s.duplicate),
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
                                  unit: s.unitName(med.displayUnit),
                                  strings: s,
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
                                              s.editBtn,
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
                                              s.infoAndStockBtn,
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
                      ],
                    ),
                  ),
                );
                return RepaintBoundary(child: itemWidget);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String key, String label, int count, bool isDark, AppStrings s) {
    final isSelected = _selectedStatusTab == key;

    // Distinct signature gradient & glow for each status tab
    List<Color> gradientColors;
    Color glowColor;
    if (key == 'All') {
      gradientColors = const [Color(0xFF0D9488), Color(0xFF14B8A6)];
      glowColor = const Color(0xFF0D9488);
    } else if (key == 'Active') {
      gradientColors = const [Color(0xFF4F46E5), Color(0xFF6366F1)];
      glowColor = const Color(0xFF4F46E5);
    } else if (key == 'Paused') {
      gradientColors = const [Color(0xFFEA580C), Color(0xFFF97316)];
      glowColor = const Color(0xFFEA580C);
    } else {
      gradientColors = const [Color(0xFF7C3AED), Color(0xFF8B5CF6)];
      glowColor = const Color(0xFF7C3AED);
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedStatusTab = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: glowColor.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            '$label (${s.formatNumber(count)})',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary),
              fontSize: 11.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineSquircleIcon(Medicine med, bool isDark) {
    final gradientColors = MedicineVisual.getGradients(med.colorValue, med.type);

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradientColors[0].withValues(alpha: isDark ? 0.16 : 0.08),
            gradientColors[1].withValues(alpha: isDark ? 0.06 : 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: gradientColors[0].withValues(alpha: isDark ? 0.35 : 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: MedicineVisual.fromMedicine(
          med,
          size: 38,
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
              onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
              decoration: InputDecoration(
                labelText: '${s.addedPillsCount} (${s.unitName(med.displayUnit)})',
                hintText: '0',
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
          s.deleteMedicinePrompt(med.name),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          s.deleteFutureRemindersAndHistoryWarning,
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

  String _getSortLabel(AppStrings s) {
    switch (_sortBy) {
      case 'az':
        return s.sortAZ;
      case 'za':
        return s.sortZA;
      case 'newest':
        return s.sortNewest;
      case 'lowStock':
        return s.sortLowStock;
      default:
        return s.sortAZ;
    }
  }

  void _showSortBottomSheet(BuildContext context, AppStrings s, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  s.sortBy,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSortOption(ctx, 'az', s.sortAZ, Icons.sort_by_alpha_rounded, isDark),
                _buildSortOption(ctx, 'za', s.sortZA, Icons.text_rotate_vertical_rounded, isDark),
                _buildSortOption(ctx, 'newest', s.sortNewest, Icons.schedule_rounded, isDark),
                _buildSortOption(ctx, 'lowStock', s.sortLowStock, Icons.inventory_2_outlined, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption(BuildContext ctx, String key, String label, IconData icon, bool isDark) {
    final isSelected = _sortBy == key;
    return InkWell(
      onTap: () {
        setState(() => _sortBy = key);
        Navigator.pop(ctx);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryTeal.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primaryTealLight : (isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? AppColors.primaryTealLight : AppColors.primaryTeal)
                      : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primaryTealLight),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, AppStrings s, bool isDark, List<Medicine> allMeds) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.filterByType,
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    if (_selectedTypeFilter != null)
                      TextButton(
                        onPressed: () {
                          setState(() => _selectedTypeFilter = null);
                          Navigator.pop(ctx);
                        },
                        child: Text(s.resetBtn),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      selected: _selectedTypeFilter == null,
                      label: Text('${s.allTypes} (${allMeds.length})'),
                      onSelected: (_) {
                        setState(() => _selectedTypeFilter = null);
                        Navigator.pop(ctx);
                      },
                    ),
                    ...MedicineType.values.map((type) {
                      final count = allMeds.where((m) => m.type == type).length;
                      return FilterChip(
                        selected: _selectedTypeFilter == type,
                        label: Text('${s.medicineTypeName(type.name)} ($count)'),
                        onSelected: (_) {
                          setState(() => _selectedTypeFilter = type);
                          Navigator.pop(ctx);
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
