import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_strings.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/app_notification.dart';
import '../../providers/language_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../widgets/luxury_notification_card.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Filters: all, doses, stock, medicines
  String _selectedFilter = 'all';
  bool _isFilterExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MedicineProvider>().markNotificationHubAsRead();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = context.watch<LanguageProvider>().languageCode;
    final s = AppStrings.of(lang);
    final medProvider = context.watch<MedicineProvider>();

    final allNotifs = medProvider.notificationsList;

    // Filter counts
    final dosesCount = allNotifs.where((n) =>
        n.type == NotificationType.doseTaken ||
        n.type == NotificationType.doseSkipped ||
        n.type == NotificationType.doseSnoozed ||
        n.type == NotificationType.doseMissed ||
        n.type == NotificationType.reminderDue
    ).length;

    final stockCount = allNotifs.where((n) =>
        n.type == NotificationType.refillAdded ||
        n.type == NotificationType.lowStock
    ).length;

    final medsCount = allNotifs.where((n) =>
        n.type == NotificationType.medicineAdded ||
        n.type == NotificationType.medicineUpdated
    ).length;

    // Filtered list
    final List<AppNotification> filteredNotifs = allNotifs.where((n) {
      if (_selectedFilter == 'doses') {
        return n.type == NotificationType.doseTaken ||
            n.type == NotificationType.doseSkipped ||
            n.type == NotificationType.doseSnoozed ||
            n.type == NotificationType.doseMissed ||
            n.type == NotificationType.reminderDue;
      } else if (_selectedFilter == 'stock') {
        return n.type == NotificationType.refillAdded ||
            n.type == NotificationType.lowStock;
      } else if (_selectedFilter == 'medicines') {
        return n.type == NotificationType.medicineAdded ||
            n.type == NotificationType.medicineUpdated;
      }
      return true; // 'all'
    }).toList();

    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          s.notifHubTitle,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          // Live Test Alarm Button
          IconButton(
            tooltip: s.notifTestTooltip,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 20),
            ),
            onPressed: () async {
              await NotificationService.instance.showTestNotification();
              await medProvider.logAppNotification(
                type: NotificationType.testAlarm,
                title: s.notifTestTitle,
                message: s.notifTestBody,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF0F172A),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.accentMint, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s.notifTestTriggered,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
          // Clear All Button
          if (allNotifs.isNotEmpty)
            IconButton(
              tooltip: s.notifClearAll,
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
              ),
              onPressed: () => _confirmClearAll(context, s, medProvider),
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. NON-SLIDING COMPACT FILTER BOX (Collapsed by default)
          SliverToBoxAdapter(
            child: _buildFilterBox(
              isDark: isDark,
              s: s,
              allCount: allNotifs.length,
              dosesCount: dosesCount,
              stockCount: stockCount,
              medsCount: medsCount,
              textPrimary: textPrimary,
            ),
          ),

          // 2. PURE NOTIFICATION & ACTIVITY FEED ITEMS
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
            sliver: _buildNotificationItems(
              context,
              notifs: filteredNotifs,
              isDark: isDark,
              lang: lang,
              s: s,
              textPrimary: textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== NON-SLIDING COMPACT FILTER BOX ====================
  Widget _buildFilterBox({
    required bool isDark,
    required AppStrings s,
    required int allCount,
    required int dosesCount,
    required int stockCount,
    required int medsCount,
    required Color textPrimary,
  }) {
    // Determine active filter name & count
    String activeLabel = s.notifFilterAll;
    int activeCount = allCount;
    if (_selectedFilter == 'doses') {
      activeLabel = s.notifFilterDoses;
      activeCount = dosesCount;
    } else if (_selectedFilter == 'stock') {
      activeLabel = s.notifFilterStockRefill;
      activeCount = stockCount;
    } else if (_selectedFilter == 'medicines') {
      activeLabel = s.notifFilterMedicines;
      activeCount = medsCount;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expandable / Collapsible Header Tile
          InkWell(
            onTap: () => setState(() => _isFilterExpanded = !_isFilterExpanded),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 16,
                    color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.notifFilterBoxTitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const Spacer(),
                  // Active Filter Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: _selectedFilter == 'all'
                          ? (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9))
                          : AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedFilter == 'all'
                            ? (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))
                            : AppColors.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '$activeLabel ($activeCount)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _selectedFilter == 'all'
                            ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                            : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isFilterExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Categories Grid
          if (_isFilterExpanded) ...[
            const Divider(height: 1, indent: 12, endIndent: 12),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Row 1: All & Doses
                  Row(
                    children: [
                      Expanded(
                        child: _buildFilterBoxItem(
                          label: s.notifFilterAll,
                          count: allCount,
                          filterKey: 'all',
                          icon: Icons.all_inbox_rounded,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFilterBoxItem(
                          label: s.notifFilterDoses,
                          count: dosesCount,
                          filterKey: 'doses',
                          icon: Icons.medication_rounded,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Row 2: Stock & Refill + Medicines Info
                  Row(
                    children: [
                      Expanded(
                        child: _buildFilterBoxItem(
                          label: s.notifFilterStockRefill,
                          count: stockCount,
                          filterKey: 'stock',
                          icon: Icons.inventory_2_rounded,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFilterBoxItem(
                          label: s.notifFilterMedicines,
                          count: medsCount,
                          filterKey: 'medicines',
                          icon: Icons.edit_note_rounded,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterBoxItem({
    required String label,
    required int count,
    required String filterKey,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _selectedFilter == filterKey;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = filterKey),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3B82F6)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.darkTextMuted : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppColors.darkTextPrimary : const Color(0xFF334155)),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : const Color(0xFF334155)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== NOTIFICATION ITEMS LIST ====================
  Widget _buildNotificationItems(
    BuildContext context, {
    required List<AppNotification> notifs,
    required bool isDark,
    required String lang,
    required AppStrings s,
    required Color textPrimary,
  }) {
    if (notifs.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 40, bottom: 40),
          child: Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    size: 44,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  s.notifAllCaughtUpTitle,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    s.notifAllCaughtUpSub,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final notif = notifs[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildNotificationCard(
              context,
              notif,
              isDark: isDark,
              s: s,
              textPrimary: textPrimary,
            ),
          );
        },
        childCount: notifs.length,
      ),
    );
  }

  // ==================== LUXURY GLASSMORPHIC NOTIFICATION CARD ====================
  Widget _buildNotificationCard(
    BuildContext context,
    AppNotification notif, {
    required bool isDark,
    required AppStrings s,
    required Color textPrimary,
  }) {
    final medProvider = context.read<MedicineProvider>();

    VoidCallback? onTake;
    VoidCallback? onSnooze;
    VoidCallback? onSkip;

    if (notif.type == NotificationType.reminderDue) {
      final medId = notif.medicineId ?? (notif.metadata?['medicineId'] as String?);
      final remId = notif.metadata?['reminderTimeId'] as String?;
      final med = medId != null
          ? medProvider.medicines.where((m) => m.id == medId).firstOrNull
          : null;
      final remList = med != null ? (medProvider.remindersByMedicine[med.id] ?? []) : [];
      final rem = (med != null && remId != null)
          ? remList.where((r) => r.id == remId).firstOrNull
          : (remList.isNotEmpty ? remList.first : null);

      if (med != null && rem != null) {
        onTake = () async {
          await medProvider.markAsTaken(med, rem, DateTime.now());
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${med.name}: ${s.taken} 🎉'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: const Color(0xFF0D9488),
              ),
            );
          }
        };

        onSnooze = () async {
          await medProvider.snoozeDose(med, rem, minutes: 10);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(s.snoozedMessage(med.name, 10)),
                behavior: SnackBarBehavior.floating,
                backgroundColor: const Color(0xFF8B5CF6),
              ),
            );
          }
        };

        onSkip = () async {
          await medProvider.markAsSkipped(med, rem, DateTime.now());
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${med.name}: ${s.skipped}'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: const Color(0xFFEF4444),
              ),
            );
          }
        };
      } else {
        // Fallback for test / demo reminders
        onTake = () {
          NotificationService.triggerHaptic(isSuccess: true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${notif.localizedTitle(s)}: ${s.taken} 🎉'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF0D9488),
            ),
          );
        };
        onSnooze = () {
          NotificationService.triggerHaptic(isSuccess: false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(s.snooze10m),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF8B5CF6),
            ),
          );
        };
        onSkip = () {
          NotificationService.triggerHaptic(isSuccess: false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(s.skip),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        };
      }
    }

    return LuxuryNotificationCard(
      notification: notif,
      s: s,
      isDark: isDark,
      onTake: onTake,
      onSnooze: onSnooze,
      onSkip: onSkip,
    );
  }

  // ==================== CLEAR ALL CONFIRMATION ====================
  Future<void> _confirmClearAll(BuildContext context, AppStrings s, MedicineProvider medProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.notifClearAll, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(s.notifClearAllConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.notifCancelBtn),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.notifClearBtn, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await medProvider.clearAllNotifications();
    }
  }
}
