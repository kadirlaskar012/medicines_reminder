import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/medicine.dart';
import '../../providers/language_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../widgets/dual_tone_capsule.dart';
import '../history/history_screen.dart';
import 'add_edit_medicine_screen.dart';

class MedicineDetailsScreen extends StatelessWidget {
  final Medicine medicine;
  const MedicineDetailsScreen({super.key, required this.medicine});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<MedicineProvider>();
    final s = context.watch<LanguageProvider>().strings;

    final reminders = provider.getRemindersForMedicine(medicine.id);
    final timeStr = reminders.isNotEmpty ? reminders.first.formattedTime : '08:00 AM';
    final dateStr = DateFormat('dd MMM, yyyy').format(medicine.startDate ?? medicine.createdAt);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Medicine Details'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddEditMedicineScreen(medicineToEdit: medicine)),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Active Badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: (medicine.isActive ? AppColors.accentMint : AppColors.error).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: medicine.isActive ? AppColors.accentMint : AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    medicine.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: medicine.isActive ? AppColors.accentMint : AppColors.error,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 3D Angled Dual-Tone Capsule Hero
          Center(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: DualToneCapsule.fromIndex(
                  medicine.colorValue,
                  size: 96,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Medicine Name & Dosage
          Center(
            child: Text(
              medicine.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              '${medicine.dosage.isNotEmpty ? medicine.dosage : "500 mg"} (${s.medicineTypeName(medicine.type.name)})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // 4-Box Summary Grid
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildGridCell('Category', s.medicineTypeName(medicine.type.name), isDark),
                    _buildGridCell('Frequency', '${reminders.length} times/day', isDark),
                    _buildGridCell('Time', timeStr, isDark),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildGridCell('Start Date', dateStr, isDark),
                    _buildGridCell(
                      'Notes',
                      s.foodInstructionName(medicine.instruction.name).isNotEmpty
                          ? s.foodInstructionName(medicine.instruction.name)
                          : (medicine.notes.isNotEmpty ? medicine.notes : 'After food'),
                      isDark,
                    ),
                    _buildGridCell('Stock', medicine.formattedStock, isDark),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Tiles (Edit, History, Share, Delete)
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildActionTile(
                  icon: Icons.edit_outlined,
                  title: 'Edit Medicine',
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddEditMedicineScreen(medicineToEdit: medicine)),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildActionTile(
                  icon: Icons.history_rounded,
                  title: 'View History',
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildActionTile(
                  icon: Icons.share_outlined,
                  title: 'Share Prescription',
                  isDark: isDark,
                  onTap: () {
                    Clipboard.setData(ClipboardData(
                      text: 'MediRemind: ${medicine.name} (${medicine.dosage}) - ${s.foodInstructionName(medicine.instruction.name)} at $timeStr.',
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          s.code == 'bn'
                              ? '📋 ওষুধের প্রেসক্রিপশন ক্লিপবোর্ডে কপি হয়েছে!'
                              : (s.code == 'hi'
                                  ? '📋 दवा का विवरण क्लिपबोर्ड पर कॉपी किया गया!'
                                  : '📋 Prescription copied to clipboard!'),
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildActionTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'Delete Medicine',
                  isDark: isDark,
                  isDestructive: true,
                  onTap: () => _confirmDelete(context, provider),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildGridCell(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDestructive ? AppColors.error : AppColors.primary).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDestructive ? AppColors.error : AppColors.primary,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isDestructive ? AppColors.error : (isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A)),
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
      onTap: onTap,
    );
  }

  void _confirmDelete(BuildContext context, MedicineProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Medicine'),
        content: Text('Are you sure you want to delete ${medicine.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteMedicine(medicine.id);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
