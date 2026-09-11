import 'package:flutter/material.dart';
import '../core/constants/app_svg_icons.dart';

enum MedicineType {
  tablet('Tablet', Icons.medication_rounded, AppSvgIcons.tablet),
  capsule('Capsule', Icons.medical_services_rounded, AppSvgIcons.capsule),
  syrup('Syrup', Icons.water_drop_rounded, AppSvgIcons.syrup),
  drops('Drops', Icons.opacity_rounded, AppSvgIcons.drops),
  inhaler('Inhaler', Icons.air_rounded, AppSvgIcons.inhaler),
  injection('Injection', Icons.vaccines_rounded, AppSvgIcons.injection),
  ointment('Ointment', Icons.clean_hands_rounded, AppSvgIcons.ointment),
  supplement('Supplement', Icons.eco_rounded, AppSvgIcons.supplement),
  other('Other', Icons.healing_rounded, AppSvgIcons.capsule);

  final String label;
  final IconData icon;
  final String svgString;
  const MedicineType(this.label, this.icon, this.svgString);

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
  final bool isActive;
  final String notes;
  final DateTime createdAt;

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
    this.isActive = true,
    this.notes = '',
    required this.createdAt,
  });

  bool get isLowStock => currentStock <= refillThreshold && currentStock > 0;
  bool get isOutOfStock => currentStock <= 0;

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
    bool? isActive,
    String? notes,
    DateTime? createdAt,
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
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
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
      'isActive': isActive ? 1 : 0,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
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
      isActive: (map['isActive'] as int? ?? 1) == 1,
      notes: map['notes'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
