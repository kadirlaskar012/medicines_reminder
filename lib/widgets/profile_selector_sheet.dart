import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_svg_icons.dart';
import '../core/theme/app_colors.dart';
import '../providers/language_provider.dart';
import '../providers/medicine_provider.dart';

class ProfileSelectorSheet extends StatelessWidget {
  const ProfileSelectorSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const ProfileSelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<MedicineProvider>();
    final s = context.watch<LanguageProvider>().strings;
    final profiles = provider.profiles;
    final active = provider.activeProfile;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
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
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s.familyProfilesTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showAddProfileDialog(context);
                  },
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: Text(s.addMember),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Option to show "All Members"
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.people_alt_rounded, size: 22, color: AppColors.secondary),
                ),
              ),
              title: Text(s.allFamilyMembersTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(s.allCombinedReminders),
              trailing: active == null
                  ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                  : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              tileColor: active == null
                  ? (isDark ? AppColors.darkCard : AppColors.primaryLight.withValues(alpha: 0.3))
                  : null,
              onTap: () {
                provider.switchProfile(null);
                Navigator.pop(context);
              },
            ),
            const Divider(height: 20),
            ...profiles.map((p) {
              final isSelected = active?.id == p.id;
              final pColor = Color(p.colorValue);

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: pColor.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: pColor, width: 2),
                  ),
                  child: Center(
                    child: (p.avatarEmoji.isNotEmpty && p.avatarEmoji != '👤')
                        ? Text(p.avatarEmoji, style: const TextStyle(fontSize: 22))
                        : AppSvgIcons.render(p.svgAvatar, width: 24, height: 24),
                  ),
                ),
                title: Text(
                  p.name.toLowerCase() == 'myself' ? s.myself : p.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  p.age != null && p.age! > 0
                      ? '${p.age} ${s.ageYears} • ${s.relationName(p.relation)}'
                      : s.relationName(p.relation),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                    : null,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: isSelected
                    ? (isDark ? AppColors.darkCard : AppColors.primaryLight.withValues(alpha: 0.3))
                    : null,
                onTap: () {
                  provider.switchProfile(p);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  static void _showAddProfileDialog(BuildContext context) {
    final s = context.read<LanguageProvider>().strings;
    final nameCtrl = TextEditingController();
    String relation = 'Mother';
    String emoji = '👵';
    int colorValue = 0xFFEC4899;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(s.addFamilyMemberTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: s.newMemberName,
                      hintText: s.memberNameHint,
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: relation,
                    decoration: InputDecoration(
                      labelText: s.relationLabel,
                      prefixIcon: const Icon(Icons.family_restroom_rounded),
                    ),
                    items: [
                      DropdownMenuItem(value: 'Mother', child: Text(s.relationName('Mother'))),
                      DropdownMenuItem(value: 'Father', child: Text(s.relationName('Father'))),
                      DropdownMenuItem(value: 'Partner', child: Text(s.relationName('Partner'))),
                      DropdownMenuItem(value: 'Child', child: Text(s.relationName('Child'))),
                      DropdownMenuItem(value: 'Other', child: Text(s.relationName('Other'))),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          relation = v;
                          if (v == 'Mother') emoji = '👵';
                          if (v == 'Father') emoji = '👴';
                          if (v == 'Partner') emoji = '❤️';
                          if (v == 'Child') emoji = '🧒';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(s.profileColorLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: AppColors.pillColors.take(6).map((c) {
                      final isSelected = c.toARGB32() == colorValue;
                      return GestureDetector(
                        onTap: () => setState(() => colorValue = c.toARGB32()),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                            boxShadow: isSelected
                                ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 8)]
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(s.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.trim().isNotEmpty) {
                    context.read<MedicineProvider>().addProfile(
                          nameCtrl.text.trim(),
                          relation,
                          colorValue,
                          emoji,
                        );
                    Navigator.pop(ctx);
                  }
                },
                child: Text(s.save),
              ),
            ],
          );
        },
      ),
    );
  }
}
