import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_svg_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/medicine_provider.dart';
import '../../widgets/profile_selector_sheet.dart';

class FamilyMembersScreen extends StatelessWidget {
  const FamilyMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<MedicineProvider>();
    final profiles = provider.profiles;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Family', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Column(
              children: profiles.asMap().entries.map((entry) {
                final idx = entry.key;
                final p = entry.value;
                final isMe = p.id == 'default_me' || p.name.toLowerCase() == 'myself';
                final displayName = isMe ? 'Kadir' : p.name;
                final relationName = isMe ? '(You)' : p.relation;
                final colors = [
                  const Color(0xFF3B82F6),
                  const Color(0xFFF97316),
                  const Color(0xFF06B6D4),
                  const Color(0xFFEC4899),
                ];
                final avatarColor = colors[idx % colors.length];

                return Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: avatarColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: (p.avatarEmoji.isNotEmpty && p.avatarEmoji != '👤')
                              ? Text(p.avatarEmoji, style: const TextStyle(fontSize: 22))
                              : (p.svgAvatar.isNotEmpty
                                  ? AppSvgIcons.render(p.svgAvatar, width: 28, height: 28)
                                  : Icon(Icons.person, color: avatarColor, size: 24)),
                        ),
                      ),
                      title: Text(
                        displayName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      subtitle: Text(
                        relationName,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                      onTap: () {
                        provider.switchProfile(p);
                        Navigator.pop(context);
                      },
                    ),
                    if (idx < profiles.length - 1) const Divider(height: 1),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => ProfileSelectorSheet.show(context),
            icon: const Icon(Icons.add_rounded, size: 22),
            label: const Text(
              'Add Family Member',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
          ),
        ),
      ),
    );
  }
}
