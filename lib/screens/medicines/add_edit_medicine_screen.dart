import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_svg_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../models/medicine.dart';
import '../../models/reminder_time.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/language_provider.dart';
import '../../core/localization/app_strings.dart';

class AddEditMedicineScreen extends StatefulWidget {
  final Medicine? medicineToEdit;

  const AddEditMedicineScreen({super.key, this.medicineToEdit});

  @override
  State<AddEditMedicineScreen> createState() => _AddEditMedicineScreenState();
}

class _AddEditMedicineScreenState extends State<AddEditMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _stockController = TextEditingController(text: '30');
  final _refillThresholdController = TextEditingController(text: '5');
  final _notesController = TextEditingController();

  MedicineType _selectedType = MedicineType.tablet;
  int _selectedColorValue = AppColors.pillColors.first.toARGB32();
  FoodInstruction _selectedInstruction = FoodInstruction.afterMeal;
  String? _selectedProfileId;

  // New Features
  int _durationDays = 0; // 0 = Ongoing / Chronic
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _expiryDate;
  String? _photoPath;

  final List<ReminderTime> _reminders = [];
  String? _selectedFrequencyPreset;

  bool get isEditing => widget.medicineToEdit != null;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();

    if (isEditing) {
      final med = widget.medicineToEdit!;
      _nameController.text = med.name;
      _dosageController.text = med.dosage;
      _stockController.text = med.currentStock.toString();
      _refillThresholdController.text = med.refillThreshold.toString();
      _notesController.text = med.notes;
      _selectedType = med.type;
      _selectedColorValue = med.colorValue;
      _selectedInstruction = med.instruction;
      _selectedProfileId = med.profileId;
      _durationDays = med.durationDays;
      _startDate = med.startDate ?? med.createdAt;
      _endDate = med.endDate;
      _expiryDate = med.expiryDate;
      _photoPath = med.photoPath;

      final existingRems = context.read<MedicineProvider>().getRemindersForMedicine(med.id);
      _reminders.addAll(existingRems);
      _selectedFrequencyPreset = _detectFrequencyPreset();
    } else {
      // Default: Morning 8:00 AM alarm
      _reminders.add(ReminderTime(
        id: const Uuid().v4(),
        medicineId: '',
        hour: 8,
        minute: 0,
        daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
        isAlarm: true,
        notificationId: 10001,
      ));
      _selectedFrequencyPreset = '1-0-0';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _stockController.dispose();
    _refillThresholdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // --- Photo Picker ---
  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _photoPath = picked.path;
        });
      }
    } catch (e) {
      debugPrint('Error picking medicine photo: $e');
    }
  }

  // --- Expiry Date Picker ---
  void _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime(now.year + 1, now.month, 1),
      firstDate: now,
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  // --- Start Date Picker ---
  void _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_durationDays > 0) {
          _endDate = picked.add(Duration(days: _durationDays));
        }
      });
    }
  }

  // --- Custom End Date Picker for Course ---
  void _pickCustomEndDate() async {
    final now = _startDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      final diff = picked.difference(now).inDays;
      setState(() {
        _endDate = picked;
        _durationDays = diff > 0 ? diff : 1;
      });
    }
  }

  // --- Detect Frequency Preset from Current Reminders ---
  String? _detectFrequencyPreset() {
    if (_reminders.length == 1 && _reminders.any((r) => r.hour == 8 && r.minute == 0)) {
      return '1-0-0';
    }
    if (_reminders.length == 2 &&
        _reminders.any((r) => r.hour == 8 && r.minute == 0) &&
        _reminders.any((r) => r.hour == 20 && r.minute == 30)) {
      return '1-0-1';
    }
    if (_reminders.length == 3 &&
        _reminders.any((r) => r.hour == 8 && r.minute == 0) &&
        _reminders.any((r) => r.hour == 13 && r.minute == 30) &&
        _reminders.any((r) => r.hour == 20 && r.minute == 30)) {
      return '1-1-1';
    }
    if (_reminders.length == 4 &&
        _reminders.any((r) => r.hour == 8 && r.minute == 0) &&
        _reminders.any((r) => r.hour == 13 && r.minute == 30) &&
        _reminders.any((r) => r.hour == 17 && r.minute == 30) &&
        _reminders.any((r) => r.hour == 20 && r.minute == 30)) {
      return '1-1-1-1';
    }
    return null;
  }

  // --- Quick Dose Frequency Presets (1+0+0, 1+0+1, 1+1+1, 1+1+1+1) ---
  void _applyQuickFrequency(String preset) {
    setState(() {
      _selectedFrequencyPreset = preset;
      _reminders.clear();
      final now = DateTime.now();
      if (preset == '1-0-0') {
        _reminders.add(ReminderTime(
          id: const Uuid().v4(),
          medicineId: widget.medicineToEdit?.id ?? '',
          hour: 8,
          minute: 0,
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
          isAlarm: true,
          notificationId: now.millisecondsSinceEpoch % 100000,
        ));
      } else if (preset == '1-0-1') {
        _reminders.add(ReminderTime(
          id: const Uuid().v4(),
          medicineId: widget.medicineToEdit?.id ?? '',
          hour: 8,
          minute: 0,
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
          isAlarm: true,
          notificationId: now.millisecondsSinceEpoch % 100000,
        ));
        _reminders.add(ReminderTime(
          id: const Uuid().v4(),
          medicineId: widget.medicineToEdit?.id ?? '',
          hour: 20,
          minute: 30,
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
          isAlarm: true,
          notificationId: (now.millisecondsSinceEpoch + 1) % 100000,
        ));
      } else if (preset == '1-1-1') {
        _reminders.add(ReminderTime(
          id: const Uuid().v4(),
          medicineId: widget.medicineToEdit?.id ?? '',
          hour: 8,
          minute: 0,
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
          isAlarm: true,
          notificationId: now.millisecondsSinceEpoch % 100000,
        ));
        _reminders.add(ReminderTime(
          id: const Uuid().v4(),
          medicineId: widget.medicineToEdit?.id ?? '',
          hour: 13,
          minute: 30,
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
          isAlarm: true,
          notificationId: (now.millisecondsSinceEpoch + 1) % 100000,
        ));
        _reminders.add(ReminderTime(
          id: const Uuid().v4(),
          medicineId: widget.medicineToEdit?.id ?? '',
          hour: 20,
          minute: 30,
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
          isAlarm: true,
          notificationId: (now.millisecondsSinceEpoch + 2) % 100000,
        ));
      } else if (preset == '1-1-1-1') {
        _reminders.add(ReminderTime(
          id: const Uuid().v4(),
          medicineId: widget.medicineToEdit?.id ?? '',
          hour: 8,
          minute: 0,
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
          isAlarm: true,
          notificationId: now.millisecondsSinceEpoch % 100000,
        ));
        _reminders.add(ReminderTime(
          id: const Uuid().v4(),
          medicineId: widget.medicineToEdit?.id ?? '',
          hour: 13,
          minute: 30,
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
          isAlarm: true,
          notificationId: (now.millisecondsSinceEpoch + 1) % 100000,
        ));
        _reminders.add(ReminderTime(
          id: const Uuid().v4(),
          medicineId: widget.medicineToEdit?.id ?? '',
          hour: 17,
          minute: 30,
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
          isAlarm: true,
          notificationId: (now.millisecondsSinceEpoch + 2) % 100000,
        ));
        _reminders.add(ReminderTime(
          id: const Uuid().v4(),
          medicineId: widget.medicineToEdit?.id ?? '',
          hour: 20,
          minute: 30,
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
          isAlarm: true,
          notificationId: (now.millisecondsSinceEpoch + 3) % 100000,
        ));
      }
    });
  }

  // --- Toggle Meal Preset (Add or Remove Time) ---
  void _toggleMealPreset(int hour, int minute) {
    setState(() {
      final existingIndex = _reminders.indexWhere((r) => r.hour == hour && r.minute == minute);
      if (existingIndex >= 0) {
        _reminders.removeAt(existingIndex);
      } else {
        _reminders.add(ReminderTime(
          id: const Uuid().v4(),
          medicineId: widget.medicineToEdit?.id ?? '',
          hour: hour,
          minute: minute,
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
          isAlarm: true,
          notificationId: DateTime.now().millisecondsSinceEpoch % 100000,
        ));
      }
      _selectedFrequencyPreset = _detectFrequencyPreset();
    });
  }

  // --- Add Custom Reminder via TimePicker ---
  void _addCustomReminderTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 20, minute: 0),
    );

    if (pickedTime != null) {
      setState(() {
        _reminders.add(ReminderTime(
          id: const Uuid().v4(),
          medicineId: widget.medicineToEdit?.id ?? '',
          hour: pickedTime.hour,
          minute: pickedTime.minute,
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
          isAlarm: true,
          notificationId: DateTime.now().millisecondsSinceEpoch % 100000,
        ));
        _selectedFrequencyPreset = _detectFrequencyPreset();
      });
    }
  }

  // --- Toggle Day for Reminder ---
  void _toggleDayForReminder(int reminderIdx, int dayOfWeek) {
    setState(() {
      final rem = _reminders[reminderIdx];
      final days = List<int>.from(rem.daysOfWeek);
      if (days.contains(dayOfWeek)) {
        if (days.length > 1) {
          days.remove(dayOfWeek);
        }
      } else {
        days.add(dayOfWeek);
        days.sort();
      }
      _reminders[reminderIdx] = ReminderTime(
        id: rem.id,
        medicineId: rem.medicineId,
        hour: rem.hour,
        minute: rem.minute,
        daysOfWeek: days,
        isAlarm: rem.isAlarm,
        notificationId: rem.notificationId,
      );
    });
  }

  void _saveMedicine(AppStrings s) async {
    if (!_formKey.currentState!.validate()) return;
    if (_reminders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.addAtLeastOneReminder)),
      );
      return;
    }

    final provider = context.read<MedicineProvider>();
    final stock = int.tryParse(_stockController.text) ?? 0;
    final threshold = int.tryParse(_refillThresholdController.text) ?? 5;

    if (isEditing) {
      final updatedMed = widget.medicineToEdit!.copyWith(
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        type: _selectedType,
        colorValue: _selectedColorValue,
        instruction: _selectedInstruction,
        currentStock: stock,
        refillThreshold: threshold,
        notes: _notesController.text.trim(),
        profileId: _selectedProfileId ?? widget.medicineToEdit!.profileId,
        durationDays: _durationDays,
        startDate: _startDate,
        endDate: _endDate,
        expiryDate: _expiryDate,
        photoPath: _photoPath,
      );
      await provider.updateMedicine(medicine: updatedMed, reminders: _reminders);
    } else {
      await provider.addMedicine(
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        type: _selectedType,
        colorValue: _selectedColorValue,
        instruction: _selectedInstruction,
        currentStock: stock,
        refillThreshold: threshold,
        notes: _notesController.text.trim(),
        reminderTimes: _reminders,
        profileId: _selectedProfileId,
        durationDays: _durationDays,
        startDate: _startDate,
        endDate: _endDate,
        expiryDate: _expiryDate,
        photoPath: _photoPath,
      );
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<MedicineProvider>();
    final profiles = provider.profiles;
    final s = context.watch<LanguageProvider>().strings;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? s.editMedicine : s.addNewMedicine),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: () => _saveMedicine(s),
              child: Text(
                s.save,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
          children: [
            // Profile selector if multiple profiles exist
            if (profiles.length > 1) ...[
              _buildSectionHeader(s.assignToFamilyMember),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedProfileId ?? provider.activeProfile?.id ?? profiles.first.id,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                items: profiles.map((p) {
                  return DropdownMenuItem(
                    value: p.id,
                    child: Row(
                      children: [
                        AppSvgIcons.render(p.svgAvatar, width: 20, height: 20),
                        const SizedBox(width: 8),
                        Text('${(p.id == 'default_me' || p.name.toLowerCase() == 'myself') ? s.myself : p.name} (${s.relationName(p.relation)})'),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedProfileId = val),
              ),
              const SizedBox(height: 20),
            ],

            // Edit Mode Hero Preview (Screen 12)
            if (isEditing) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Image.asset(
                        _selectedType.assetPath,
                        width: 64,
                        height: 64,
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, stack) => AppSvgIcons.render(
                          _selectedType.svgString,
                          width: 54,
                          height: 54,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _nameController.text.isNotEmpty ? _nameController.text : s.medicineDetails,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      if (_dosageController.text.isNotEmpty)
                        Text(
                          _dosageController.text,
                          style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w700),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 1. Basic Medicine Info
            _buildSectionHeader(s.medicineDetails),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: s.medicineName,
                hintText: s.medicineNameHint,
                prefixIcon: const Icon(Icons.medication_rounded),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? s.enterNameValidation : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _dosageController,
              decoration: InputDecoration(
                labelText: s.dosageStrength,
                hintText: s.strengthHint,
                prefixIcon: const Icon(Icons.scale_rounded),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? s.enterDosageValidation : null,
            ),
            const SizedBox(height: 24),

            // 2. Medicine Form & 3D Icons (ALL VISIBLE DIRECTLY ON SCREEN - NO HORIZONTAL SLIDE!)
            _buildSectionHeader(s.formAndIcon),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - (3 * 8)) / 4;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: MedicineType.values.map((type) {
                    final isSelected = _selectedType == type;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedType = type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: itemWidth,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12)
                              : (isDark ? AppColors.darkCard : Colors.white),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              type.assetPath,
                              width: 32,
                              height: 32,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => AppSvgIcons.render(
                                type.svgString,
                                width: 28,
                                height: 28,
                                color: isSelected ? AppColors.primary : null,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              s.medicineTypeName(type.name),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? Colors.white70 : Colors.black87),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),

            // 3. Compact Pill Color Tag
            _buildSectionHeader(s.pillColorTag),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: AppColors.pillColors.map((color) {
                  final isSelected = color.toARGB32() == _selectedColorValue;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorValue = color.toARGB32()),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: isDark ? Colors.white : AppColors.primary, width: 2.5)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // 4. Treatment Course Duration
            _buildSectionHeader(s.treatmentCourse),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildCourseChip(0, s.courseOngoing),
                _buildCourseChip(3, s.courseDaysLabel(3)),
                _buildCourseChip(5, s.courseDaysLabel(5)),
                _buildCourseChip(7, s.courseDaysLabel(7)),
                _buildCourseChip(14, s.courseDaysLabel(14)),
                _buildCourseChip(30, s.courseDaysLabel(30)),
                ActionChip(
                  avatar: const Icon(Icons.date_range_rounded, size: 16),
                  label: Text(
                    _durationDays > 0 && ![3, 5, 7, 14, 30].contains(_durationDays)
                        ? s.courseDaysLabel(_durationDays)
                        : s.customEndDate,
                  ),
                  backgroundColor: _durationDays > 0 && ![3, 5, 7, 14, 30].contains(_durationDays)
                      ? AppColors.primary
                      : null,
                  labelStyle: TextStyle(
                    color: _durationDays > 0 && ![3, 5, 7, 14, 30].contains(_durationDays)
                        ? Colors.white
                        : null,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  onPressed: _pickCustomEndDate,
                ),
              ],
            ),
            if (_durationDays > 0 && _endDate != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${s.courseEndsOn}: ${DateFormat('dd MMM, yyyy').format(_endDate!)} (${s.courseDaysLabel(_durationDays)})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Start Date Picker (Step 6)
            _buildSectionHeader(s.code == 'bn' ? 'শুরুর তারিখ (Start Date)' : 'Start Date'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickStartDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _startDate != null
                            ? DateFormat('EEEE, d MMMM yyyy').format(_startDate!)
                            : 'Today',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down_rounded, color: AppColors.lightTextSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 5. Food Instruction
            _buildSectionHeader(s.foodTimingInstruction),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FoodInstruction.values.map((inst) {
                final isSelected = _selectedInstruction == inst;
                return ChoiceChip(
                  selected: isSelected,
                  avatar: AppSvgIcons.render(
                    inst.svgString,
                    width: 16,
                    height: 16,
                    color: isSelected ? Colors.white : AppColors.secondary,
                  ),
                  label: Text(s.foodInstructionName(inst.name)),
                  selectedColor: AppColors.secondary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedInstruction = inst);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // 6. Quick Dose Frequency Shortcuts (1+0+0, 1+0+1, 1+1+1)
            _buildSectionHeader(s.quickDoseFrequency),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFrequencyPresetBtn('1-0-0', s.doseOnceDaily, Icons.wb_sunny_rounded),
                _buildFrequencyPresetBtn('1-0-1', s.doseTwiceDaily, Icons.timelapse_rounded),
                _buildFrequencyPresetBtn('1-1-1', s.doseThriceDaily, Icons.repeat_rounded),
                _buildFrequencyPresetBtn('1-1-1-1', s.doseFourDaily, Icons.alarm_on_rounded),
              ],
            ),
            const SizedBox(height: 24),

            // 7. Routine & Meal Presets
            _buildSectionHeader(s.routineMealSlot),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMealPresetBtn('🍳 ${s.breakfast}', 8, 0),
                _buildMealPresetBtn('🍛 ${s.lunch}', 13, 30),
                _buildMealPresetBtn('☕ ${s.eveningSnacks}', 17, 30),
                _buildMealPresetBtn('🍲 ${s.dinner}', 20, 30),
                _buildMealPresetBtn('🛏️ ${s.bedtimeSlot}', 22, 30),
                ActionChip(
                  avatar: const Icon(Icons.add_alarm_rounded, size: 16, color: AppColors.primary),
                  label: Text(s.customClock),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary),
                  onPressed: _addCustomReminderTime,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 8. Configured Reminders & Day-of-Week Schedule
            _buildSectionHeader(s.reminderSchedules),
            const SizedBox(height: 10),

            ..._reminders.asMap().entries.map((entry) {
              final idx = entry.key;
              final rem = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            rem.formattedTime,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rem.isAlarm ? s.loudAlarm : s.gentleNotification,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                rem.recurrenceSummaryLocalized(s),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: rem.isAlarm,
                          activeTrackColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() {
                              _reminders[idx] = ReminderTime(
                                id: rem.id,
                                medicineId: rem.medicineId,
                                hour: rem.hour,
                                minute: rem.minute,
                                daysOfWeek: rem.daysOfWeek,
                                isAlarm: val,
                                notificationId: rem.notificationId,
                              );
                            });
                          },
                        ),
                        if (_reminders.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                            onPressed: () {
                              setState(() {
                                _reminders.removeAt(idx);
                                _selectedFrequencyPreset = _detectFrequencyPreset();
                              });
                            },
                          ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 8),

                    // Specific Days of the week row for this reminder
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [1, 2, 3, 4, 5, 6, 7].map((day) {
                        final isSelected = rem.daysOfWeek.contains(day);
                        return GestureDetector(
                          onTap: () => _toggleDayForReminder(idx, day),
                          child: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: Text(
                              s.weekdayShort(day),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),

            // 9. Stock & Refill Tracker
            _buildSectionHeader(s.stockInventory),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: s.currentQuantity,
                      hintText: '30',
                      prefixIcon: const Icon(Icons.inventory_2_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextFormField(
                    controller: _refillThresholdController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: s.lowAlertLimit,
                      hintText: '5',
                      prefixIcon: const Icon(Icons.notifications_active_outlined),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 10. Medicine Strip / Box Photo (Attachment)
            _buildSectionHeader(s.medicinePhoto),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: _photoPath != null && File(_photoPath!).existsSync()
                  ? Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_photoPath!),
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.medicinePhoto,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              TextButton.icon(
                                onPressed: () => setState(() => _photoPath = null),
                                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                                label: Text(s.removePhoto, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickPhoto(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_rounded, size: 18),
                            label: Text(s.takePhoto),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickPhoto(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_rounded, size: 18),
                            label: Text(s.chooseFromGallery),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),

            // 11. Expiry Date Tracker
            _buildSectionHeader(s.expiryDateTitle),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.event_available_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _expiryDate != null
                              ? '${s.expiresOn} ${DateFormat('MMMM yyyy').format(_expiryDate!)}'
                              : s.selectExpiryDate,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _expiryDate != null && DateTime.now().isAfter(_expiryDate!)
                                ? AppColors.error
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_expiryDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => setState(() => _expiryDate = null),
                    ),
                  ElevatedButton(
                    onPressed: _pickExpiryDate,
                    style: ElevatedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: Text(s.change),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 12. Doctor Notes & Tips
            _buildSectionHeader(s.doctorNotesOptional),
            const SizedBox(height: 10),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: s.notesHint,
              ),
            ),
            const SizedBox(height: 32),


            // 14. Delete Medicine Button (Screen 12)
            if (isEditing) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDeleteMedicine(context),
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  label: Text(
                    s.deleteMedicine,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.5), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () => _saveMedicine(s),
              child: Text(
                isEditing ? s.updateMedicineBtn : s.saveAndSetReminders,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteMedicine(BuildContext context) {
    final s = context.read<LanguageProvider>().strings;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            Text(s.deleteConfirmTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          s.code == 'bn'
              ? 'আপনি কি নিশ্চিত যে "${widget.medicineToEdit?.name}" মুছে ফেলতে চান?'
              : (s.code == 'hi'
                  ? 'क्या आप वाकई "${widget.medicineToEdit?.name}" को हटाना चाहते हैं?'
                  : 'Are you sure you want to delete "${widget.medicineToEdit?.name}"?'),
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
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              if (widget.medicineToEdit != null) {
                await context.read<MedicineProvider>().deleteMedicine(widget.medicineToEdit!.id);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: Text(s.delete),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextPrimary,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildCourseChip(int days, String label) {
    final isSelected = _durationDays == days;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      onSelected: (val) {
        if (val) {
          setState(() {
            _durationDays = days;
            if (days > 0) {
              _endDate = (_startDate ?? DateTime.now()).add(Duration(days: days));
            } else {
              _endDate = null;
            }
          });
        }
      },
    );
  }

  Widget _buildFrequencyPresetBtn(String presetKey, String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = (_selectedFrequencyPreset == presetKey) ||
        (_selectedFrequencyPreset == null && _detectFrequencyPreset() == presetKey);

    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : AppColors.secondary,
      ),
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.secondary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      onSelected: (val) {
        if (val) {
          _applyQuickFrequency(presetKey);
        } else {
          setState(() => _selectedFrequencyPreset = null);
        }
      },
    );
  }

  Widget _buildMealPresetBtn(String label, int hour, int minute) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _reminders.any((r) => r.hour == hour && r.minute == minute);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.secondary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      onSelected: (_) => _toggleMealPreset(hour, minute),
    );
  }
}
