import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../models/medicine.dart';
import '../../models/reminder_time.dart';
import '../../providers/language_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../widgets/medicine_visual.dart';
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
    final timeStr = reminders.isNotEmpty
        ? reminders.map((r) => r.formattedTime).join(', ')
        : '08:00 AM';
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
                child: MedicineVisual.fromMedicine(
                  medicine,
                  size: 96,
                  hasGlow: true,
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
                    _buildGridCell('Time', reminders.isNotEmpty ? reminders.first.formattedTime : timeStr, isDark),
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

          const SizedBox(height: 20),

          // ⏰ Scheduled Dose Timings & Alarms Section (Directly Editable)
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.alarm_rounded, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.scheduledAlarmsTitle,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              s.tapToChangeTime,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () => _showAddOrEditReminderSheet(context, provider, s, isDark),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text(s.addTiming),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (reminders.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        s.addAtLeastOneReminder,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ),
                  )
                else
                  ...reminders.map((rem) => _buildReminderTile(
                        context,
                        provider,
                        rem,
                        s,
                        isDark,
                        canDelete: reminders.length > 1,
                      )),
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
                  title: 'Edit Medicine Details',
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

  Widget _buildReminderTile(
    BuildContext context,
    MedicineProvider provider,
    ReminderTime rem,
    AppStrings s,
    bool isDark, {
    required bool canDelete,
  }) {
    final slot = rem.timeSlot;
    final slotColor = slot.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Color.alphaBlend(slotColor.withValues(alpha: 0.1), const Color(0xFF0F172A))
            : Color.alphaBlend(slotColor.withValues(alpha: 0.05), const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: slotColor.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAddOrEditReminderSheet(context, provider, s, isDark, existingReminder: rem),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Squircle Slot Icon
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: slotColor.withValues(alpha: isDark ? 0.25 : 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: slotColor.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Icon(slot.icon, size: 20, color: slotColor),
                ),
                const SizedBox(width: 12),

                // Time and recurrence summary
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            rem.formattedTime,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : slotColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: slotColor.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              slot.title,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: slotColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${rem.recurrenceSummaryLocalized(s)} • ${rem.isAlarm ? s.loudAlarm : s.gentleNotification}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Edit Action Pill Button
                InkWell(
                  onTap: () => _showAddOrEditReminderSheet(context, provider, s, isDark, existingReminder: rem),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: slotColor.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: slotColor.withValues(alpha: 0.35), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_rounded, size: 14, color: slotColor),
                        const SizedBox(width: 4),
                        Text(
                          s.editTiming,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: slotColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (canDelete) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                    tooltip: s.code == 'bn' ? 'সময় মুছুন' : 'Delete Time',
                    onPressed: () => _confirmDeleteReminder(context, provider, rem, s),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddOrEditReminderSheet(
    BuildContext context,
    MedicineProvider provider,
    AppStrings s,
    bool isDark, {
    ReminderTime? existingReminder,
  }) {
    final bool isEditing = existingReminder != null;
    TimeOfDay selectedTime = isEditing
        ? TimeOfDay(hour: existingReminder.hour, minute: existingReminder.minute)
        : TimeOfDay.now();
    bool isAlarm = isEditing ? existingReminder.isAlarm : true;
    List<int> selectedDays = isEditing ? List<int>.from(existingReminder.daysOfWeek) : [1, 2, 3, 4, 5, 6, 7];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final isDarkModal = Theme.of(sheetCtx).brightness == Brightness.dark;
            final now = DateTime.now();
            final dt = DateTime(now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);
            final formattedTime = DateFormat('hh:mm a').format(dt);

            final presets = [
              {'label': s.code == 'bn' ? 'সকাল' : 'Morning', 'hour': 8, 'minute': 0, 'icon': Icons.wb_sunny_rounded},
              {'label': s.code == 'bn' ? 'দুপুর' : 'Lunch', 'hour': 13, 'minute': 0, 'icon': Icons.lunch_dining_rounded},
              {'label': s.code == 'bn' ? 'বিকাল' : 'Afternoon', 'hour': 16, 'minute': 30, 'icon': Icons.coffee_rounded},
              {'label': s.code == 'bn' ? 'সন্ধ্যা' : 'Evening', 'hour': 19, 'minute': 0, 'icon': Icons.wb_twilight_rounded},
              {'label': s.code == 'bn' ? 'রাত' : 'Night', 'hour': 21, 'minute': 30, 'icon': Icons.bedtime_rounded},
            ];

            return Container(
              padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(sheetCtx).viewInsets.bottom + 24),
              decoration: BoxDecoration(
                color: isDarkModal ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: isDarkModal ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.access_time_filled_rounded, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isEditing ? s.updateTiming : s.addTiming,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(sheetCtx),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Big Interactive Digital Clock Card
                    InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: sheetCtx,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setModalState(() {
                            selectedTime = picked;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDarkModal
                                ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                                : [const Color(0xFFEEF2FF), const Color(0xFFF8FAFC)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.tapToChangeTime,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkModal ? const Color(0xFFA5B4FC) : AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formattedTime,
                                  style: GoogleFonts.outfit(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: isDarkModal ? Colors.white : const Color(0xFF1E1B4B),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.touch_app_rounded, color: Colors.white, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    s.change,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Quick Meal Slot Presets
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: presets.map((p) {
                          final pHour = p['hour'] as int;
                          final pMinute = p['minute'] as int;
                          final isSelected = selectedTime.hour == pHour && selectedTime.minute == pMinute;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              avatar: Icon(
                                p['icon'] as IconData,
                                size: 14,
                                color: isSelected ? Colors.white : AppColors.primary,
                              ),
                              label: Text('${p['label']}'),
                              backgroundColor: isSelected
                                  ? AppColors.primary
                                  : (isDarkModal ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? Colors.white : (isDarkModal ? Colors.white70 : Colors.black87),
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onPressed: () {
                                setModalState(() {
                                  selectedTime = TimeOfDay(hour: pHour, minute: pMinute);
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Loud Alarm Toggle Switch
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDarkModal ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDarkModal ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isAlarm ? Icons.alarm_rounded : Icons.notifications_none_rounded,
                                color: isAlarm ? AppColors.primary : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isAlarm ? s.loudAlarm : s.gentleNotification,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          Switch.adaptive(
                            value: isAlarm,
                            activeTrackColor: AppColors.primary,
                            onChanged: (val) {
                              setModalState(() => isAlarm = val);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Days of Week Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [1, 2, 3, 4, 5, 6, 7].map((day) {
                        final isDaySel = selectedDays.contains(day);
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              if (selectedDays.contains(day)) {
                                if (selectedDays.length > 1) selectedDays.remove(day);
                              } else {
                                selectedDays.add(day);
                                selectedDays.sort();
                              }
                            });
                          },
                          child: Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDaySel
                                  ? AppColors.primary
                                  : (isDarkModal ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDaySel
                                    ? AppColors.primary
                                    : (isDarkModal ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: Text(
                              s.weekdayShort(day),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isDaySel
                                    ? Colors.white
                                    : (isDarkModal ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetCtx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(s.cancel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (isEditing) {
                                await provider.updateReminderTime(
                                  medicine: medicine,
                                  oldReminder: existingReminder,
                                  newHour: selectedTime.hour,
                                  newMinute: selectedTime.minute,
                                  daysOfWeek: selectedDays,
                                  isAlarm: isAlarm,
                                );
                              } else {
                                await provider.addReminderTimeToMedicine(
                                  medicine: medicine,
                                  hour: selectedTime.hour,
                                  minute: selectedTime.minute,
                                  daysOfWeek: selectedDays,
                                  isAlarm: isAlarm,
                                );
                              }

                              if (context.mounted) {
                                Navigator.pop(sheetCtx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${s.reminderUpdatedSuccess} (${selectedTime.format(context)})'),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: Text(
                              isEditing ? s.updateTiming : s.addTiming,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteReminder(
    BuildContext context,
    MedicineProvider provider,
    ReminderTime rem,
    AppStrings s,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.code == 'bn' ? 'সময় মুছবেন?' : 'Delete Reminder Time?'),
        content: Text(
          s.code == 'bn'
              ? '${medicine.name} এর ${rem.formattedTime} এর অ্যালার্ম কি মুছে ফেলতে চান?'
              : 'Do you want to remove the ${rem.formattedTime} alarm for ${medicine.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteReminderTimeFromMedicine(
                medicine: medicine,
                reminder: rem,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(s.reminderDeletedSuccess),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(s.code == 'bn' ? 'মুছুন' : 'Delete'),
          ),
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
