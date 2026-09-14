import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../models/medicine.dart';
import '../../providers/language_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../widgets/dual_tone_capsule.dart';
import '../../widgets/empty_medicines_view.dart';
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
    final filtered = allMeds.where((m) {
      final matchesSearch = m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.dosage.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      if (_selectedStatusTab == 'Active') return !m.isExpired;
      if (_selectedStatusTab == 'Completed') return m.isExpired;

      return true;
    }).toList();

    final activeCount = allMeds.where((m) => !m.isExpired).length;
    final completedCount = allMeds.where((m) => m.isExpired).length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC),
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
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

          // 2. Status Segmented Tabs [All (N)] | [Active (N)] | [Completed (N)]
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildTabItem('All', 'All', allMeds.length, isDark),
                  _buildTabItem('Active', 'Active', activeCount, isDark),
                  _buildTabItem('Completed', 'Completed', completedCount, isDark),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

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
                      final timeStr = reminders.isNotEmpty ? reminders.first.formattedTime : '08:00 AM';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
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
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    DualToneCapsule.fromIndex(
                                      med.colorValue,
                                      size: 46,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            med.name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${med.dosage.isNotEmpty ? med.dosage : "500 mg"} (${s.medicineTypeName(med.type.name)})',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            timeStr,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch.adaptive(
                                      value: !med.isExpired,
                                      activeTrackColor: AppColors.accentMint,
                                      onChanged: (val) {
                                        // toggle active state
                                      },
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_horiz_rounded),
                                      onSelected: (val) {
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
                                const SizedBox(height: 12),
                                const Divider(height: 1, thickness: 0.8),
                                const SizedBox(height: 12),

                                // Reminders row & Stock status
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Reminders times badges
                                    Expanded(
                                      child: Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: reminders.map((r) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              r.formattedTime,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),

                                    // Stock Info & Dynamic Refill Forecast
                                    Builder(
                                      builder: (context) {
                                        final dailyDoses = provider.getDailyDoseCount(med.id);
                                        final daysRemaining = med.estimatedDaysRemaining(dailyDoses);

                                        return Row(
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '${med.currentStock} ${s.leftCount}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: med.isLowStock
                                                        ? AppColors.warning
                                                        : isDark
                                                            ? AppColors.darkTextPrimary
                                                            : AppColors.lightTextPrimary,
                                                  ),
                                                ),
                                                if (daysRemaining > 0 && dailyDoses > 0)
                                                  Text(
                                                    '${s.runsOutIn} $daysRemaining ${s.days}',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w700,
                                                      color: daysRemaining <= 3 ? AppColors.error : const Color(0xFF059669),
                                                    ),
                                                  )
                                                else if (med.isLowStock)
                                                  Text(
                                                    s.lowStock,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColors.warning,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton.filledTonal(
                                              onPressed: () => _showRefillDialog(context, med, s),
                                              icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                                              visualDensity: VisualDensity.compact,
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
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
    final qtyCtrl = TextEditingController(text: '30');

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
            Text('${s.currentQuantity}: ${med.currentStock}'),
            const SizedBox(height: 16),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: s.addedPillsCount,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.deleteConfirmTitle),
        content: Text('${s.deleteConfirmMessage} "${med.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
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
