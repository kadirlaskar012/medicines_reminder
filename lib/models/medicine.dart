import 'package:flutter/material.dart';
import '../core/constants/app_svg_icons.dart';

enum MedicineType {
  tablet('Tablet', Icons.medication_rounded, AppSvgIcons.tablet, 'Tablets', ['Tablets', 'Strips', 'Pills'], 30, 5),
  capsule('Capsule', Icons.medical_services_rounded, AppSvgIcons.capsule, 'Capsules', ['Capsules', 'Strips'], 30, 5),
  syrup('Syrup', Icons.water_drop_rounded, AppSvgIcons.syrup, 'ml', ['ml', 'Bottles', 'Spoons'], 100, 20),
  drops('Drops', Icons.opacity_rounded, AppSvgIcons.drops, 'ml', ['ml', 'Drops', 'Bottles'], 15, 3),
  inhaler('Inhaler', Icons.air_rounded, AppSvgIcons.inhaler, 'Puffs', ['Puffs', 'Canisters'], 200, 30),
  injection('Injection', Icons.vaccines_rounded, AppSvgIcons.injection, 'Vials', ['Vials', 'Ampoules', 'Units'], 5, 1),
  ointment('Ointment', Icons.clean_hands_rounded, AppSvgIcons.ointment, 'Tubes', ['Tubes', 'g'], 2, 1),
  supplement('Supplement', Icons.eco_rounded, AppSvgIcons.supplement, 'Tablets', ['Tablets', 'Capsules', 'Softgels', 'Gummies'], 60, 10),
  other('Other', Icons.healing_rounded, AppSvgIcons.capsule, 'Units', ['Units', 'Doses', 'Packs'], 30, 5);

  final String label;
  final IconData icon;
  final String svgString;
  final String defaultUnit;
  final List<String> availableUnits;
  final int defaultStock;
  final int defaultThreshold;

  const MedicineType(
    this.label,
    this.icon,
    this.svgString,
    this.defaultUnit,
    this.availableUnits,
    this.defaultStock,
    this.defaultThreshold,
  );

  String get assetPath => 'assets/icons/3d/med_3d_$name.png';

  static MedicineType fromString(String val) {
    return MedicineType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => MedicineType.tablet,
    );
  }
}

enum FoodInstruction {
  beforeMeal('Before Meal', 'Take 30 min before eating', Icons.hourglass_bottom_rounded, AppSvgIcons.beforeMeal),
  afterMeal('After Meal', 'Take within 30 min after meal', Icons.done_all_rounded, AppSvgIcons.afterMeal),
  withMeal('With Meal', 'Take during eating', Icons.lunch_dining_rounded, AppSvgIcons.withMeal),
  emptyStomach('Empty Stomach', 'Take with full glass of water', Icons.water_drop_rounded, AppSvgIcons.emptyStomach),
  bedtime('Bedtime', 'Take right before sleeping', Icons.bedtime_rounded, AppSvgIcons.bedtime),
  anytime('Anytime', 'Can be taken anytime', Icons.access_time_filled_rounded, AppSvgIcons.afterMeal);

  final String title;
  final String description;
  final IconData icon;
  final String svgString;
  const FoodInstruction(this.title, this.description, this.icon, this.svgString);

  static FoodInstruction fromString(String val) {
    return FoodInstruction.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => FoodInstruction.afterMeal,
    );
  }
}

class Medicine {
  final String id;
  final String profileId;
  final String name;
  final String dosage;
  final MedicineType type;
  final int colorValue;
  final FoodInstruction instruction;
  final int currentStock;
  final int refillThreshold;
  final String unit;
  final bool isActive;
  final String notes;
  final DateTime createdAt;
  final int durationDays; // 0 = Ongoing / Chronic, 3, 5, 7, 14, 30, etc.
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? expiryDate;
  final String? photoPath;

  Medicine({
    required this.id,
    required this.profileId,
    required this.name,
    required this.dosage,
    required this.type,
    required this.colorValue,
    required this.instruction,
    this.currentStock = 0,
    this.refillThreshold = 5,
    this.unit = '',
    this.isActive = true,
    this.notes = '',
    required this.createdAt,
    this.durationDays = 0,
    this.startDate,
    this.endDate,
    this.expiryDate,
    this.photoPath,
  });

  String get displayUnit => unit.isNotEmpty ? unit : type.defaultUnit;
  String get formattedStock => '$currentStock $displayUnit';

  bool get isLowStock => currentStock <= refillThreshold && currentStock > 0;
  bool get isOutOfStock => currentStock <= 0;
  bool get isCourseOngoing => durationDays == 0;
  bool get isCourseCompleted => durationDays > 0 && endDate != null && DateTime.now().isAfter(endDate!);
  bool get isExpired => expiryDate != null && DateTime.now().isAfter(expiryDate!);

  /// Estimate remaining days based on daily dose count
  int estimatedDaysRemaining(int dailyDoseCount) {
    if (dailyDoseCount <= 0 || currentStock <= 0) return 0;
    return (currentStock / dailyDoseCount).floor();
  }

  /// Estimated date when stock will run out
  DateTime? estimatedRunOutDate(int dailyDoseCount) {
    final days = estimatedDaysRemaining(dailyDoseCount);
    if (days <= 0) return null;
    return DateTime.now().add(Duration(days: days));
  }

  /// Stock Forecast urgency status: 'empty', 'critical', 'warning', 'healthy'
  String stockForecastStatus(int dailyDoseCount) {
    if (currentStock <= 0) return 'empty';
    final days = estimatedDaysRemaining(dailyDoseCount);
    if (days <= 2) return 'critical';
    if (days <= 5 || isLowStock) return 'warning';
    return 'healthy';
  }

  Medicine copyWith({
    String? id,
    String? profileId,
    String? name,
    String? dosage,
    MedicineType? type,
    int? colorValue,
    FoodInstruction? instruction,
    int? currentStock,
    int? refillThreshold,
    String? unit,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
    int? durationDays,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? expiryDate,
    String? photoPath,
  }) {
    return Medicine(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      type: type ?? this.type,
      colorValue: colorValue ?? this.colorValue,
      instruction: instruction ?? this.instruction,
      currentStock: currentStock ?? this.currentStock,
      refillThreshold: refillThreshold ?? this.refillThreshold,
      unit: unit ?? this.unit,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      durationDays: durationDays ?? this.durationDays,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      expiryDate: expiryDate ?? this.expiryDate,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profileId': profileId,
      'name': name,
      'dosage': dosage,
      'type': type.name,
      'colorValue': colorValue,
      'instruction': instruction.name,
      'currentStock': currentStock,
      'refillThreshold': refillThreshold,
      'unit': unit,
      'isActive': isActive ? 1 : 0,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'durationDays': durationDays,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'photoPath': photoPath,
    };
  }

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'] as String,
      profileId: map['profileId'] as String? ?? 'default_me',
      name: map['name'] as String,
      dosage: map['dosage'] as String,
      type: MedicineType.fromString(map['type'] as String? ?? 'tablet'),
      colorValue: map['colorValue'] as int? ?? 0xFF0D9488,
      instruction: FoodInstruction.fromString(map['instruction'] as String? ?? 'afterMeal'),
      currentStock: map['currentStock'] as int? ?? 0,
      refillThreshold: map['refillThreshold'] as int? ?? 5,
      unit: map['unit'] as String? ?? '',
      isActive: (map['isActive'] as int? ?? 1) == 1,
      notes: map['notes'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      durationDays: map['durationDays'] as int? ?? 0,
      startDate: map['startDate'] != null ? DateTime.tryParse(map['startDate'] as String) : null,
      endDate: map['endDate'] != null ? DateTime.tryParse(map['endDate'] as String) : null,
      expiryDate: map['expiryDate'] != null ? DateTime.tryParse(map['expiryDate'] as String) : null,
      photoPath: map['photoPath'] as String?,
    );
  }
}

