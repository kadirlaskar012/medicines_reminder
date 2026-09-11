import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_svg_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../models/medicine.dart';
import '../../providers/medicine_provider.dart';
import '../../widgets/pill_icon_badge.dart';
import 'add_edit_medicine_screen.dart';

class MedicinesCabinetScreen extends StatefulWidget {
  const MedicinesCabinetScreen({super.key});

  @override
  State<MedicinesCabinetScreen> createState() => _MedicinesCabinetScreenState();
}

class _MedicinesCabinetScreenState extends State<MedicinesCabinetScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All'; // All, Low Stock, Tablet, Capsule, Syrup

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<MedicineProvider>();
    final allMeds = provider.filteredMedicines;

    // Apply filtering & search
    final filtered = allMeds.where((m) {
      final matchesSearch = m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.dosage.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      if (_selectedFilter == 'Low Stock') return m.isLowStock || m.isOutOfStock;
      if (_selectedFilter == 'Tablet') return m.type == MedicineType.tablet;
      if (_selectedFilter == 'Capsule') return m.type == MedicineType.capsule;
      if (_selectedFilter == 'Syrup') return m.type == MedicineType.syrup;

      return true;
    }).toList();

    final lowStockCount = allMeds.where((m) => m.isLowStock || m.isOutOfStock).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Cabinet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditMedicineScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search medicines...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildFilterChip('All', allMeds.length),
                if (lowStockCount > 0)
                  _buildFilterChip('Low Stock', lowStockCount, isWarning: true),
                _buildFilterChip('Tablet', null, svgIcon: AppSvgIcons.tablet),
                _buildFilterChip('Capsule', null, svgIcon: AppSvgIcons.capsule),
                _buildFilterChip('Syrup', null, svgIcon: AppSvgIcons.syrup),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Medicines List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 60,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _searchQuery.isEmpty ? 'No Medicines Found' : 'No matches found',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Tap the + icon in the top right to add a medicine.'
                              : 'Try searching with another keyword.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final med = filtered[index];
                      final medColor = Color(med.colorValue);
                      final reminders = provider.getRemindersForMedicine(med.id);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: med.isLowStock
                                ? AppColors.warning.withValues(alpha: 0.5)
                                : isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                PillIconBadge(
                                  type: med.type,
                                  color: medColor,
                                  size: 46,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        med.name,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${med.dosage}  •  ${med.instruction.title}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_horiz_rounded),
                                  onSelected: (val) {
                                    if (val == 'edit') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddEditMedicineScreen(medicineToEdit: med),
                                        ),
                                      );
                                    } else if (val == 'delete') {
                                      _confirmDelete(context, med);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_rounded, size: 18),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                          SizedBox(width: 8),
                                          Text('Delete', style: TextStyle(color: AppColors.error)),
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
                                                '${med.currentStock} left',
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
                                                  'Runs out in $daysRemaining d',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: daysRemaining <= 3 ? AppColors.error : const Color(0xFF059669),
                                                  ),
                                                )
                                              else if (med.isLowStock)
                                                const Text(
                                                  'Low Stock',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.warning,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton.filledTonal(
                                            onPressed: () => _showRefillDialog(context, med),
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int? count, {bool isWarning = false, String? svgIcon}) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        avatar: svgIcon != null
            ? AppSvgIcons.render(
                svgIcon,
                width: 14,
                height: 14,
                color: isSelected ? Colors.white : AppColors.primary,
              )
            : null,
        label: Text(count != null ? '$label ($count)' : label),
        selectedColor: isWarning ? AppColors.warning : AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : null,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        onSelected: (_) => setState(() => _selectedFilter = label),
      ),
    );
  }

  void _showRefillDialog(BuildContext context, Medicine med) {
    final qtyCtrl = TextEditingController(text: '30');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Refill ${med.name}', style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current stock: ${med.currentStock} units'),
            const SizedBox(height: 14),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Add Quantity',
                prefixIcon: Icon(Icons.add_circle_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [10, 20, 30, 60].map((qty) {
                return OutlinedButton(
                  onPressed: () => qtyCtrl.text = qty.toString(),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: Text('+$qty'),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final addQty = int.tryParse(qtyCtrl.text) ?? 0;
              if (addQty > 0) {
                context.read<MedicineProvider>().refillStock(med.id, addQty);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added $addQty units to ${med.name} stock.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Refill'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Medicine med) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Medicine?'),
        content: Text('Are you sure you want to delete ${med.name}? All reminder alarms will be cancelled.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              context.read<MedicineProvider>().deleteMedicine(med.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
