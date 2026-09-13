import 'package:flutter/material.dart';
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

  final List<ReminderTime> _reminders = [];

  bool get isEditing => widget.medicineToEdit != null;

  @override
  void initState() {
    super.initState();
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

      // Load existing reminders
      final existingRems = context.read<MedicineProvider>().getRemindersForMedicine(med.id);
      _reminders.addAll(existingRems);
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

  void _addReminderTime() async {
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
      });
    }
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
          padding: const EdgeInsets.all(20),
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

            // Basic Info
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

            // Form / Type Selector
            _buildSectionHeader(s.formAndIcon),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: MedicineType.values.map((type) {
                  final isSelected = _selectedType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      selected: isSelected,
                      avatar: Image.asset(
                        type.assetPath,
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => AppSvgIcons.render(
                          type.svgString,
                          width: 18,
                          height: 18,
                          color: isSelected ? Colors.white : AppColors.primary,
                        ),
                      ),
                      label: Text(s.medicineTypeName(type.name)),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedType = type);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Color Picker
            _buildSectionHeader(s.pillColorTag),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: AppColors.pillColors.map((color) {
                final isSelected = color.toARGB32() == _selectedColorValue;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColorValue = color.toARGB32()),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: isDark ? Colors.white : Colors.black87, width: 3)
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
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Food Instruction
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
            const SizedBox(height: 28),

            // Reminders & Alarm Schedules
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader(s.reminderSchedules),
                TextButton.icon(
                  onPressed: _addReminderTime,
                  icon: const Icon(Icons.add_alarm_rounded, size: 18),
                  label: Text(s.addTime),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ..._reminders.asMap().entries.map((entry) {
              final idx = entry.key;
              final rem = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            rem.formattedTime,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
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
                                  fontSize: 12,
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
                              setState(() => _reminders.removeAt(idx));
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),

            // Stock & Refill Tracker
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
            const SizedBox(height: 20),

            // Notes
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

            // Submit Button
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: () => _saveMedicine(s),
                child: Text(
                  isEditing ? s.updateMedicineBtn : s.saveAndSetReminders,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextPrimary,
        letterSpacing: 0.2,
      ),
    );
  }
}
