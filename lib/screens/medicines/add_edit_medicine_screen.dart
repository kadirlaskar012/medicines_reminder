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
  String _selectedUnit = MedicineType.tablet.defaultUnit;
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
      _selectedUnit = med.displayUnit;
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
    } else {
      _selectedUnit = _selectedType.defaultUnit;
      _selectedColorValue = _getColorForType(_selectedType);
      _stockController.text = _selectedType.defaultStock.toString();
      _refillThresholdController.text = _selectedType.defaultThreshold.toString();

      // Unticked by default: start empty so user chooses their routine slots
      _reminders.clear();
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

  int _getColorForType(MedicineType type) {
    switch (type) {
      case MedicineType.tablet:
        return const Color(0xFF0EA5E9).toARGB32();
      case MedicineType.capsule:
        return const Color(0xFF6366F1).toARGB32();
      case MedicineType.syrup:
        return const Color(0xFFF59E0B).toARGB32();
      case MedicineType.drops:
        return const Color(0xFF10B981).toARGB32();
      case MedicineType.inhaler:
        return const Color(0xFF06B6D4).toARGB32();
      case MedicineType.injection:
        return const Color(0xFFEF4444).toARGB32();
      case MedicineType.ointment:
        return const Color(0xFF8B5CF6).toARGB32();
      case MedicineType.supplement:
        return const Color(0xFF10B981).toARGB32();
      default:
        return const Color(0xFF14B8A6).toARGB32();
    }
  }

  // --- Custom Course Duration Picker ---
  void _pickCustomCourseDays() async {
    final s = context.read<LanguageProvider>().strings;
    final textCtrl = TextEditingController(text: _durationDays > 0 ? '$_durationDays' : '15');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.date_range_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(s.code == 'bn' ? 'কাস্টম কোর্সের মেয়াদ' : 'Custom Course Duration'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.code == 'bn' ? 'কত দিন ওষুধটি চলবে?' : 'How many days should this medicine be taken?',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                suffixText: s.code == 'bn' ? 'দিন' : 'Days',
                hintText: 'e.g. 15, 45, 60',
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: TextButton.icon(
                onPressed: () async {
                  final now = _startDate ?? DateTime.now();
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: _endDate ?? now.add(const Duration(days: 15)),
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 365 * 2)),
                  );
                  if (picked != null) {
                    final diff = picked.difference(now).inDays;
                    if (ctx.mounted) {
                      Navigator.pop(ctx, diff > 0 ? diff : 1);
                    }
                  }
                },
                icon: const Icon(Icons.calendar_month_rounded, size: 18),
                label: Text(s.code == 'bn' ? 'ক্যালেন্ডার থেকে শেষ তারিখ বাছুন' : 'Pick end date from calendar'),
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
            onPressed: () {
              final val = int.tryParse(textCtrl.text.trim());
              if (val != null && val > 0) {
                Navigator.pop(ctx, val);
              } else {
                Navigator.pop(ctx);
              }
            },
            child: Text(s.save),
          ),
        ],
      ),
    );

    if (result != null && result > 0) {
      setState(() {
        _durationDays = result;
        _endDate = (_startDate ?? DateTime.now()).add(Duration(days: result));
      });
    }
  }

  // --- Meal Slot Checkers & Helpers ---
  bool _matchesSlot(ReminderTime r, String slotKey) {
    final totalMinutes = r.hour * 60 + r.minute;
    switch (slotKey) {
      case 'morning':
        // 05:00 to 11:59 (300 to 719 mins)
        return totalMinutes >= 300 && totalMinutes < 720;
      case 'lunch':
        // 12:00 to 15:29 (720 to 929 mins)
        return totalMinutes >= 720 && totalMinutes < 930;
      case 'afternoon':
        // 15:30 to 17:59 (930 to 1079 mins)
        return totalMinutes >= 930 && totalMinutes < 1080;
      case 'evening':
        // 18:00 to 20:29 (1080 to 1229 mins)
        return totalMinutes >= 1080 && totalMinutes < 1230;
      case 'night':
        // 20:30 to 04:59 (1230 to 1439 mins OR 0 to 299 mins)
        return totalMinutes >= 1230 || totalMinutes < 300;
      default:
        return false;
    }
  }

  ReminderTime? _getSlotReminder(String slotKey) {
    for (final r in _reminders) {
      if (_matchesSlot(r, slotKey)) return r;
    }
    return null;
  }

  String _getSlotSubtitle(String slotKey, AppStrings s) {
    final rem = _getSlotReminder(slotKey);
    if (rem == null) {
      return s.code == 'bn' ? 'সেট করুন' : (s.code == 'hi' ? 'सेट करें' : 'Tap to set');
    }
    String mealDesc;
    final totalMins = rem.hour * 60 + rem.minute;
    if (slotKey == 'morning') {
      if (rem.hour < 8) {
        mealDesc = s.code == 'bn' ? 'খাবারের আগে' : 'Before breakfast';
      } else {
        mealDesc = s.code == 'bn' ? 'খাবারের পরে' : 'After breakfast';
      }
    } else if (slotKey == 'lunch') {
      if (totalMins <= 13 * 60 + 15) {
        mealDesc = s.code == 'bn' ? 'খাবারের আগে' : 'Before lunch';
      } else {
        mealDesc = s.code == 'bn' ? 'খাবারের পরে' : 'After lunch';
      }
    } else if (slotKey == 'afternoon') {
      if (totalMins < 17 * 60 + 15) {
        mealDesc = s.code == 'bn' ? 'নাস্তার আগে' : 'Before snacks';
      } else {
        mealDesc = s.code == 'bn' ? 'নাস্তার পরে' : 'After snacks';
      }
    } else if (slotKey == 'evening') {
      if (totalMins < 19 * 60 + 15) {
        mealDesc = s.code == 'bn' ? 'খাবারের আগে' : 'Before snacks';
      } else {
        mealDesc = s.code == 'bn' ? 'খাবারের পরে' : 'After snacks';
      }
    } else {
      if (totalMins >= 22 * 60) {
        mealDesc = s.code == 'bn' ? 'ঘুমানোর আগে' : 'Bedtime';
      } else if (totalMins < 21 * 60) {
        mealDesc = s.code == 'bn' ? 'খাবারের আগে' : 'Before dinner';
      } else {
        mealDesc = s.code == 'bn' ? 'খাবারের পরে' : 'After dinner';
      }
    }
    return '${rem.formattedTime}\n$mealDesc';
  }

  // --- Show Taking Time Modal Popup with Before / After Meal ---
  Future<void> _showTimeSlotModal(String slotKey) async {
    final s = context.read<LanguageProvider>().strings;

    String title;
    IconData slotIcon;
    Color slotColor;
    List<Map<String, dynamic>> options;
    TimeOfDay defaultTime;

    if (slotKey == 'morning') {
      title = s.code == 'bn' ? 'সকালের ওষুধের সময় ও নিয়ম' : 'Morning Dose Timing';
      slotIcon = Icons.wb_sunny_rounded;
      slotColor = const Color(0xFFF59E0B);
      defaultTime = const TimeOfDay(hour: 8, minute: 30);
      options = [
        {
          'label': s.code == 'bn' ? 'খাবারের আগে (Before Breakfast)' : 'Before Breakfast',
          'sub': s.code == 'bn' ? 'সকালের নাস্তার ৩০ মিনিট আগে' : '30 min before breakfast',
          'hour': 7,
          'minute': 30,
          'instruction': FoodInstruction.beforeMeal,
          'icon': Icons.hourglass_bottom_rounded,
        },
        {
          'label': s.code == 'bn' ? 'খাবারের পরে (After Breakfast)' : 'After Breakfast',
          'sub': s.code == 'bn' ? 'সকালের নাস্তার ৩০ মিনিটের মধ্যে' : 'Within 30 min after breakfast',
          'hour': 8,
          'minute': 30,
          'instruction': FoodInstruction.afterMeal,
          'icon': Icons.done_all_rounded,
        },
        {
          'label': s.code == 'bn' ? 'খালি পেটে (Empty Stomach)' : 'Empty Stomach',
          'sub': s.code == 'bn' ? 'সকালে ঘুম থেকে উঠে ১ গ্লাস পানিসহ' : 'Right after waking up with water',
          'hour': 7,
          'minute': 0,
          'instruction': FoodInstruction.emptyStomach,
          'icon': Icons.water_drop_rounded,
        },
      ];
    } else if (slotKey == 'lunch') {
      title = s.code == 'bn' ? 'দুপুরের ওষুধের সময় ও নিয়ম' : 'Lunch Dose Timing';
      slotIcon = Icons.lunch_dining_rounded;
      slotColor = const Color(0xFF3B82F6);
      defaultTime = const TimeOfDay(hour: 14, minute: 0);
      options = [
        {
          'label': s.code == 'bn' ? 'খাবারের আগে (Before Lunch)' : 'Before Lunch',
          'sub': s.code == 'bn' ? 'দুপুরের খাওয়ার ৩০ মিনিট আগে' : '30 min before lunch',
          'hour': 13,
          'minute': 0,
          'instruction': FoodInstruction.beforeMeal,
          'icon': Icons.hourglass_bottom_rounded,
        },
        {
          'label': s.code == 'bn' ? 'খাবারের পরে (After Lunch)' : 'After Lunch',
          'sub': s.code == 'bn' ? 'দুপুরের খাওয়ার ৩০ মিনিটের মধ্যে' : 'Within 30 min after lunch',
          'hour': 14,
          'minute': 0,
          'instruction': FoodInstruction.afterMeal,
          'icon': Icons.done_all_rounded,
        },
        {
          'label': s.code == 'bn' ? 'খাবারের সাথে (With Meal)' : 'With Meal',
          'sub': s.code == 'bn' ? 'দুপুরের খাবার খাওয়ার সাথে' : 'While having lunch',
          'hour': 13,
          'minute': 30,
          'instruction': FoodInstruction.withMeal,
          'icon': Icons.flatware_rounded,
        },
      ];
    } else if (slotKey == 'afternoon') {
      title = s.code == 'bn' ? 'বিকালের ওষুধের সময় ও নিয়ম' : 'Afternoon Dose Timing';
      slotIcon = Icons.coffee_rounded;
      slotColor = const Color(0xFF10B981);
      defaultTime = const TimeOfDay(hour: 17, minute: 0);
      options = [
        {
          'label': s.code == 'bn' ? 'নাস্তার আগে (Before Snacks)' : 'Before Snacks',
          'sub': s.code == 'bn' ? 'বিকালের নাস্তা বা চা খাওয়ার আগে' : 'Before afternoon snacks',
          'hour': 16,
          'minute': 30,
          'instruction': FoodInstruction.beforeMeal,
          'icon': Icons.hourglass_bottom_rounded,
        },
        {
          'label': s.code == 'bn' ? 'নাস্তার পরে (After Snacks)' : 'After Snacks',
          'sub': s.code == 'bn' ? 'বিকালের নাস্তা বা চা খাওয়ার পর' : 'After afternoon snacks',
          'hour': 17,
          'minute': 30,
          'instruction': FoodInstruction.afterMeal,
          'icon': Icons.done_all_rounded,
        },
        {
          'label': s.code == 'bn' ? 'সাধারণ সময় (Anytime)' : 'Anytime Afternoon',
          'sub': s.code == 'bn' ? 'বিকালের যে কোনো সময়' : 'Anytime during afternoon',
          'hour': 17,
          'minute': 0,
          'instruction': FoodInstruction.anytime,
          'icon': Icons.access_time_rounded,
        },
      ];
    } else if (slotKey == 'evening') {
      title = s.code == 'bn' ? 'সন্ধ্যার ওষুধের সময় ও নিয়ম' : (s.code == 'hi' ? 'शाम की दवा का समय और नियम' : 'Evening Dose Timing');
      slotIcon = Icons.wb_twilight_rounded;
      slotColor = const Color(0xFF8B5CF6);
      defaultTime = const TimeOfDay(hour: 19, minute: 0);
      options = [
        {
          'label': s.code == 'bn' ? 'খাবারের আগে (Before Snacks)' : (s.code == 'hi' ? 'नाश्ते से पहले' : 'Before Evening Snacks'),
          'sub': s.code == 'bn' ? 'সন্ধ্যার নাস্তা বা চা খাওয়ার ৩০ মিনিট আগে' : '30 min before evening snacks',
          'hour': 18,
          'minute': 30,
          'instruction': FoodInstruction.beforeMeal,
          'icon': Icons.hourglass_bottom_rounded,
        },
        {
          'label': s.code == 'bn' ? 'খাবারের পরে (After Snacks)' : (s.code == 'hi' ? 'नाश्ते के बाद' : 'After Evening Snacks'),
          'sub': s.code == 'bn' ? 'সন্ধ্যার নাস্তা বা চা খাওয়ার ৩০ মিনিটের মধ্যে' : 'Within 30 min after evening snacks',
          'hour': 19,
          'minute': 30,
          'instruction': FoodInstruction.afterMeal,
          'icon': Icons.done_all_rounded,
        },
        {
          'label': s.code == 'bn' ? 'সাধারণ সময় (Anytime)' : (s.code == 'hi' ? 'सामान्य समय' : 'Anytime Evening'),
          'sub': s.code == 'bn' ? 'সন্ধ্যার যে কোনো সুবিধাজনক সময়' : 'Anytime during evening hours',
          'hour': 19,
          'minute': 0,
          'instruction': FoodInstruction.anytime,
          'icon': Icons.access_time_rounded,
        },
      ];
    } else {
      title = s.code == 'bn' ? 'রাতের ওষুধের সময় ও নিয়ম' : 'Night Dose Timing';
      slotIcon = Icons.bedtime_rounded;
      slotColor = const Color(0xFF6366F1);
      defaultTime = const TimeOfDay(hour: 21, minute: 30);
      options = [
        {
          'label': s.code == 'bn' ? 'খাবারের আগে (Before Dinner)' : 'Before Dinner',
          'sub': s.code == 'bn' ? 'রাতের খাওয়ার ৩০ মিনিট আগে' : '30 min before dinner',
          'hour': 20,
          'minute': 30,
          'instruction': FoodInstruction.beforeMeal,
          'icon': Icons.hourglass_bottom_rounded,
        },
        {
          'label': s.code == 'bn' ? 'খাবারের পরে (After Dinner)' : 'After Dinner',
          'sub': s.code == 'bn' ? 'রাতের খাওয়ার ৩০ মিনিটের মধ্যে' : 'Within 30 min after dinner',
          'hour': 21,
          'minute': 30,
          'instruction': FoodInstruction.afterMeal,
          'icon': Icons.done_all_rounded,
        },
        {
          'label': s.code == 'bn' ? 'ঘুমানোর আগে (At Bedtime)' : 'At Bedtime',
          'sub': s.code == 'bn' ? 'রাতে ঘুমানোর ঠিক আগে' : 'Right before sleeping',
          'hour': 22,
          'minute': 30,
          'instruction': FoodInstruction.bedtime,
          'icon': Icons.nightlight_round,
        },
      ];
    }

    final existingIndex = _reminders.indexWhere((r) => _matchesSlot(r, slotKey));

    int selectedOptionIdx = 1;
    TimeOfDay customTime = defaultTime;
    if (existingIndex >= 0) {
      final curRem = _reminders[existingIndex];
      customTime = TimeOfDay(hour: curRem.hour, minute: curRem.minute);
      final matchIdx = options.indexWhere((opt) => opt['hour'] == curRem.hour && opt['minute'] == curRem.minute);
      if (matchIdx >= 0) {
        selectedOptionIdx = matchIdx;
      } else {
        final instIdx = options.indexWhere((opt) => opt['instruction'] == _selectedInstruction);
        if (instIdx >= 0) selectedOptionIdx = instIdx;
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final isDarkModal = Theme.of(ctx).brightness == Brightness.dark;

            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: isDarkModal ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDarkModal ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: slotColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(slotIcon, color: slotColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                s.code == 'bn' ? 'ওষুধ খাওয়ার নিয়ম বেছে নিন' : 'Choose food timing & instruction',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkModal ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ...options.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final opt = entry.value;
                      final isOptSelected = selectedOptionIdx == idx;

                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selectedOptionIdx = idx;
                            customTime = TimeOfDay(hour: opt['hour'] as int, minute: opt['minute'] as int);
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isOptSelected
                                ? slotColor.withValues(alpha: isDarkModal ? 0.2 : 0.1)
                                : (isDarkModal ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isOptSelected
                                  ? slotColor
                                  : (isDarkModal ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              width: isOptSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                opt['icon'] as IconData,
                                color: isOptSelected ? slotColor : (isDarkModal ? Colors.white54 : Colors.black45),
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      opt['label'] as String,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isOptSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: isOptSelected ? slotColor : null,
                                      ),
                                    ),
                                    Text(
                                      opt['sub'] as String,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDarkModal ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isOptSelected ? slotColor : (isDarkModal ? Colors.white38 : Colors.black38),
                                    width: 2,
                                  ),
                                ),
                                child: isOptSelected
                                    ? Center(
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: slotColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDarkModal ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 20, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                s.code == 'bn' ? 'অ্যালার্মের সময়:' : 'Alarm Time:',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                customTime.format(context),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: customTime,
                              );
                              if (picked != null) {
                                setModalState(() {
                                  customTime = picked;
                                });
                              }
                            },
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: Text(s.change),
                            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        if (existingIndex >= 0) ...[
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _reminders.removeAt(existingIndex);
                              });
                              Navigator.pop(ctx);
                            },
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                            label: Text(s.code == 'bn' ? 'মুছুন' : 'Remove', style: const TextStyle(color: AppColors.error)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final selOpt = options[selectedOptionIdx];
                              final instruction = selOpt['instruction'] as FoodInstruction;
                              setState(() {
                                _selectedInstruction = instruction;
                                final newRem = ReminderTime(
                                  id: existingIndex >= 0 ? _reminders[existingIndex].id : const Uuid().v4(),
                                  medicineId: widget.medicineToEdit?.id ?? '',
                                  hour: customTime.hour,
                                  minute: customTime.minute,
                                  daysOfWeek: existingIndex >= 0 ? _reminders[existingIndex].daysOfWeek : [1, 2, 3, 4, 5, 6, 7],
                                  isAlarm: true,
                                  notificationId: existingIndex >= 0
                                      ? _reminders[existingIndex].notificationId
                                      : (DateTime.now().millisecondsSinceEpoch % 100000),
                                );
                                if (existingIndex >= 0) {
                                  _reminders[existingIndex] = newRem;
                                } else {
                                  _reminders.add(newRem);
                                }
                                _reminders.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
                              });
                              Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: slotColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(
                              s.code == 'bn' ? 'রিমাইন্ডার সেট করুন' : 'Confirm Reminder',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
        _reminders.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
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
        unit: _selectedUnit,
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
        unit: _selectedUnit,
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
                      onTap: () {
                        setState(() {
                          _selectedType = type;
                          _selectedUnit = type.defaultUnit;
                          _selectedColorValue = _getColorForType(type);
                          if (!isEditing) {
                            _stockController.text = type.defaultStock.toString();
                            _refillThresholdController.text = type.defaultThreshold.toString();
                          }
                        });
                      },
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

            // 3. Treatment Course Duration (3d, 7d, 10d, 2w, 21d, 1m, custom, ongoing)
            _buildSectionHeader(s.treatmentCourse),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildCourseChip(3, s.threeDays),
                _buildCourseChip(7, s.sevenDays),
                _buildCourseChip(10, s.tenDays),
                _buildCourseChip(14, s.twoWeeks),
                _buildCourseChip(21, s.twentyOneDays),
                _buildCourseChip(30, s.oneMonth),
                _buildCourseChip(0, s.courseOngoing),
                ActionChip(
                  avatar: const Icon(Icons.edit_calendar_rounded, size: 16),
                  label: Text(
                    _durationDays > 0 && ![3, 7, 10, 14, 21, 30].contains(_durationDays)
                        ? s.courseDaysLabel(_durationDays)
                        : s.customCourse,
                  ),
                  backgroundColor: _durationDays > 0 && ![3, 7, 10, 14, 21, 30].contains(_durationDays)
                      ? AppColors.primary
                      : null,
                  labelStyle: TextStyle(
                    color: _durationDays > 0 && ![3, 7, 10, 14, 21, 30].contains(_durationDays)
                        ? Colors.white
                        : null,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  onPressed: _pickCustomCourseDays,
                ),
              ],
            ),
            if (_durationDays > 0 && _endDate != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_available_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${s.courseEndsOn}: ${DateFormat('dd MMMM, yyyy').format(_endDate!)} (${s.courseDaysLabel(_durationDays)})',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),

            // Start Date Picker
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

            // 4. Taking Time & Routine (Morning, Lunch, Afternoon, Night Slots with Before/After meal popup)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader(s.routineMealSlot),
                TextButton.icon(
                  onPressed: _addCustomReminderTime,
                  icon: const Icon(Icons.add_alarm_rounded, size: 16),
                  label: Text(
                    s.code == 'bn' ? 'কাস্টম সময়' : 'Custom Time',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              ],
            ),
            Text(
              s.code == 'bn'
                  ? 'সকাল, দুপুর, বিকাল, সন্ধ্যা বা রাত্রিতে ট্যাপ করে খাবারের আগে বা পরে সেট করুন'
                  : (s.code == 'hi'
                      ? 'सुबह, दोपहर, शाम या रात पर टैप करके भोजन से पहले या बाद में सेट करें'
                      : 'Tap Morning, Lunch, Afternoon, Evening, or Night to configure food timing'),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 12),

            // 5 Slots: Row 1 (Morning, Lunch, Afternoon) & Row 2 (Evening, Night)
            Row(
              children: [
                _buildSlotCard('morning', s.morningSlot, Icons.wb_sunny_rounded, const Color(0xFFF59E0B), s, isDark),
                const SizedBox(width: 8),
                _buildSlotCard('lunch', s.lunchSlot, Icons.lunch_dining_rounded, const Color(0xFF3B82F6), s, isDark),
                const SizedBox(width: 8),
                _buildSlotCard('afternoon', s.afternoonSlot, Icons.coffee_rounded, const Color(0xFF10B981), s, isDark),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildSlotCard('evening', s.eveningSlot, Icons.wb_twilight_rounded, const Color(0xFF8B5CF6), s, isDark),
                const SizedBox(width: 8),
                _buildSlotCard('night', s.nightSlot, Icons.bedtime_rounded, const Color(0xFF6366F1), s, isDark),
              ],
            ),
            const SizedBox(height: 14),

            // Daily Taking Routine & Measurement Summary Tag
            _buildDailyMeasurementBadge(s, isDark),
            const SizedBox(height: 24),

            if (_reminders.isNotEmpty) ...[
              // 5. Configured Reminders & Day-of-Week Schedule
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
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                          onPressed: () {
                            setState(() {
                              _reminders.removeAt(idx);
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
          ],

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
                      labelText: '${s.currentQuantity} (${s.unitName(_selectedUnit)})',
                      hintText: '${_selectedType.defaultStock}',
                      suffixText: s.unitName(_selectedUnit),
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
                      labelText: '${s.lowAlertLimit} (${s.unitName(_selectedUnit)})',
                      hintText: '${_selectedType.defaultThreshold}',
                      suffixText: s.unitName(_selectedUnit),
                      prefixIcon: const Icon(Icons.notifications_active_outlined),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Unit Selection Chips
            Text(
              s.measurementUnitLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _selectedType.availableUnits.map((u) {
                final isSelected = _selectedUnit.toLowerCase() == u.toLowerCase();
                return ChoiceChip(
                  label: Text(s.unitName(u)),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedUnit = u);
                    }
                  },
                );
              }).toList(),
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

  Widget _buildSlotCard(
    String slotKey,
    String title,
    IconData icon,
    Color color,
    AppStrings s,
    bool isDark,
  ) {
    final rem = _getSlotReminder(slotKey);
    final isConfigured = rem != null;
    final subtitle = _getSlotSubtitle(slotKey, s);

    return Expanded(
      child: GestureDetector(
        onTap: () => _showTimeSlotModal(slotKey),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isConfigured
                ? color.withValues(alpha: isDark ? 0.22 : 0.1)
                : (isDark ? AppColors.darkCard : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isConfigured
                  ? color
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: isConfigured ? 2 : 1,
            ),
            boxShadow: isConfigured
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.3 : 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 17, color: color),
                  ),
                  if (isConfigured)
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
                    )
                  else
                    Icon(Icons.add_rounded, size: 17, color: isDark ? Colors.white38 : Colors.black38),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isConfigured
                      ? (isDark ? Colors.white : color)
                      : (isDark ? Colors.white : Colors.black87),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isConfigured ? FontWeight.w700 : FontWeight.w500,
                  height: 1.25,
                  color: isConfigured
                      ? (isDark ? const Color(0xFFA5B4FC) : color)
                      : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Daily Taking Routine & Measurement Summary Tag ---
  Widget _buildDailyMeasurementBadge(AppStrings s, bool isDark) {
    final count = _reminders.length;
    if (count == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFFDE68A),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.touch_app_rounded, color: Colors.amber, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.code == 'bn'
                        ? 'কোনো সময় এখনও নির্বাচন করা হয়নি'
                        : (s.code == 'hi' ? 'कोई समय अभी तक नहीं चुना गया' : 'No Timing Selected Yet'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.code == 'bn'
                        ? 'ওপরে সকাল, দুপুর, বিকাল, সন্ধ্যা বা রাত্রিতে ট্যাপ করে সময় সেট করুন'
                        : (s.code == 'hi'
                            ? 'समय सेट करने के लिए ऊपर किसी स्लॉट पर टैप करें'
                            : 'Tap any slot above to set routine time'),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextMuted : const Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Active slots
    final hasMorning = _getSlotReminder('morning') != null;
    final hasLunch = _getSlotReminder('lunch') != null;
    final hasAfternoon = _getSlotReminder('afternoon') != null;
    final hasEvening = _getSlotReminder('evening') != null;
    final hasNight = _getSlotReminder('night') != null;

    // Daily prescription formula e.g. "১ + ০ + ১"
    String prescriptionFormula = '';
    final hasOnlyStandard3 = !hasAfternoon && !hasEvening;
    if (hasOnlyStandard3) {
      prescriptionFormula = '${hasMorning ? "১" : "০"} + ${hasLunch ? "১" : "০"} + ${hasNight ? "১" : "০"}';
    } else {
      final parts = <String>[];
      if (hasMorning) parts.add('১');
      if (hasLunch) parts.add('১');
      if (hasAfternoon) parts.add('১');
      if (hasEvening) parts.add('১');
      if (hasNight) parts.add('১');
      prescriptionFormula = parts.join(' + ');
    }

    final countText = s.dailyDoseCount(count);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F2A4A), const Color(0xFF1E1B4B)]
              : [const Color(0xFFEFF6FF), const Color(0xFFF5F3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.4 : 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.medication_liquid_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.code == 'bn'
                          ? 'ওষুধ খাওয়ার দৈনন্দিন নিয়ম ও মাপ'
                          : (s.code == 'hi' ? 'दैनिक खुराक माप' : 'Daily Dose Routine'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          countText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        if (prescriptionFormula.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '• $prescriptionFormula',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF10B981)),
                    const SizedBox(width: 4),
                    Text(
                      s.code == 'bn'
                          ? '${s.formatNumber(count)}টি সময়'
                          : (s.code == 'hi' ? '${s.formatNumber(count)} समय' : '$count Times'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _reminders.map((r) {
              String slotLabel = '';
              Color slotColor = AppColors.primary;
              IconData slotIco = Icons.alarm;
              if (_matchesSlot(r, 'morning')) {
                slotLabel = s.morningSlot;
                slotColor = const Color(0xFFF59E0B);
                slotIco = Icons.wb_sunny_rounded;
              } else if (_matchesSlot(r, 'lunch')) {
                slotLabel = s.lunchSlot;
                slotColor = const Color(0xFF3B82F6);
                slotIco = Icons.lunch_dining_rounded;
              } else if (_matchesSlot(r, 'afternoon')) {
                slotLabel = s.afternoonSlot;
                slotColor = const Color(0xFF10B981);
                slotIco = Icons.coffee_rounded;
              } else if (_matchesSlot(r, 'evening')) {
                slotLabel = s.eveningSlot;
                slotColor = const Color(0xFF8B5CF6);
                slotIco = Icons.wb_twilight_rounded;
              } else {
                slotLabel = s.nightSlot;
                slotColor = const Color(0xFF6366F1);
                slotIco = Icons.bedtime_rounded;
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: slotColor.withValues(alpha: isDark ? 0.22 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: slotColor.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(slotIco, size: 12, color: slotColor),
                    const SizedBox(width: 4),
                    Text(
                      '$slotLabel: ${r.formattedTime}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
