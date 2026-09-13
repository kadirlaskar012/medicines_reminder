import '../core/constants/app_svg_icons.dart';

class UserProfile {
  final String id;
  final String name;
  final String relation; // Myself, Mother, Father, Child, Other
  final int colorValue;
  final String avatarEmoji;
  final int? age;

  UserProfile({
    required this.id,
    required this.name,
    required this.relation,
    required this.colorValue,
    required this.avatarEmoji,
    this.age,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? relation,
    int? colorValue,
    String? avatarEmoji,
    int? age,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      relation: relation ?? this.relation,
      colorValue: colorValue ?? this.colorValue,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      age: age ?? this.age,
    );
  }

  String get svgAvatar {
    final rel = relation.toLowerCase();
    if (rel.contains('dad') || rel.contains('father')) return AppSvgIcons.avatarDad;
    if (rel.contains('mom') || rel.contains('mother')) return AppSvgIcons.avatarMom;
    if (rel.contains('child') || rel.contains('kid') || rel.contains('son') || rel.contains('daughter')) {
      return AppSvgIcons.avatarChild;
    }
    return AppSvgIcons.avatarMyself;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'relation': relation,
      'colorValue': colorValue,
      'avatarEmoji': avatarEmoji,
      if (age != null) 'age': age,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      relation: map['relation'] as String,
      colorValue: map['colorValue'] as int,
      avatarEmoji: map['avatarEmoji'] as String? ?? '👤',
      age: map['age'] as int?,
    );
  }

  static UserProfile defaultProfile = UserProfile(
    id: 'default_me',
    name: 'Myself',
    relation: 'Myself',
    colorValue: 0xFFFF6B35, // Warm Orange
    avatarEmoji: '👤',
  );
}


