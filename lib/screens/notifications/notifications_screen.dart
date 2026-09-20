import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_strings.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/app_notification.dart';
import '../../providers/language_provider.dart';
import '../../providers/medicine_provider.dart';

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
                title: lang == 'bn' ? 'টেস্ট নোটিফিকেশন' : 'Test Notification',
                message: lang == 'bn'
                    ? 'লকস্ক্রিন ও সিস্টেম নোটিফিকেশন টেস্ট সফলভাবে যাচাই করা হয়েছে।'
                    : 'Lock screen & system notification test triggered successfully.',
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
              lang: lang,
              textPrimary: textPrimary,
            ),
          );
        },
        childCount: notifs.length,
      ),
    );
  }

  // ==================== PURE ACTIVITY / NOTIFICATION CARD ====================
  // Strictly notification and activity info: NO TAKE, SNOOZE, or SKIP buttons
  Widget _buildNotificationCard(
    BuildContext context,
    AppNotification notif, {
    required bool isDark,
    required String lang,
    required Color textPrimary,
  }) {
    final formattedTime = _formatNotificationTimestamp(notif.timestamp, lang);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: !notif.isRead
              ? const Color(0xFF3B82F6).withValues(alpha: 0.5)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: !notif.isRead ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTypeIcon(notif.type),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildTypeBadge(notif.type, lang),
                    const Spacer(),
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  notif.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                if (notif.message.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    notif.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 3D SQUIRCLE ICON CONTAINER ====================
  Widget _buildTypeIcon(NotificationType type) {
    final List<Color> gradientColors;
    final IconData iconData;

    switch (type) {
      case NotificationType.doseTaken:
        gradientColors = [const Color(0xFF10B981), const Color(0xFF059669)];
        iconData = Icons.check_circle_rounded;
        break;
      case NotificationType.doseSkipped:
        gradientColors = [const Color(0xFFF59E0B), const Color(0xFFD97706)];
        iconData = Icons.remove_circle_outline_rounded;
        break;
      case NotificationType.doseSnoozed:
        gradientColors = [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)];
        iconData = Icons.snooze_rounded;
        break;
      case NotificationType.doseMissed:
        gradientColors = [const Color(0xFFEF4444), const Color(0xFFB91C1C)];
        iconData = Icons.alarm_off_rounded;
        break;
      case NotificationType.refillAdded:
        gradientColors = [const Color(0xFF2563EB), const Color(0xFF0284C7)];
        iconData = Icons.add_shopping_cart_rounded;
        break;
      case NotificationType.lowStock:
        gradientColors = [const Color(0xFFF97316), const Color(0xFFEA580C)];
        iconData = Icons.warning_amber_rounded;
        break;
      case NotificationType.medicineAdded:
        gradientColors = [const Color(0xFF0D9488), const Color(0xFF14B8A6)];
        iconData = Icons.add_circle_outline_rounded;
        break;
      case NotificationType.medicineUpdated:
        gradientColors = [const Color(0xFF4F46E5), const Color(0xFF6366F1)];
        iconData = Icons.edit_note_rounded;
        break;
      case NotificationType.reminderDue:
      case NotificationType.testAlarm:
        gradientColors = [const Color(0xFF7C3AED), const Color(0xFF9333EA)];
        iconData = Icons.notifications_active_rounded;
        break;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(iconData, color: Colors.white, size: 22),
    );
  }

  // ==================== TYPE BADGE ====================
  Widget _buildTypeBadge(NotificationType type, String lang) {
    String label;
    Color bg;
    Color fg;

    switch (type) {
      case NotificationType.doseTaken:
        label = lang == 'bn' ? 'সম্পন্ন' : 'Taken';
        bg = const Color(0xFF10B981).withValues(alpha: 0.15);
        fg = const Color(0xFF059669);
        break;
      case NotificationType.doseSkipped:
        label = lang == 'bn' ? 'স্কিপ' : 'Skipped';
        bg = const Color(0xFFF59E0B).withValues(alpha: 0.15);
        fg = const Color(0xFFD97706);
        break;
      case NotificationType.doseSnoozed:
        label = lang == 'bn' ? 'স্থগিত' : 'Snoozed';
        bg = const Color(0xFF8B5CF6).withValues(alpha: 0.15);
        fg = const Color(0xFF7C3AED);
        break;
      case NotificationType.doseMissed:
        label = lang == 'bn' ? 'মিসড' : 'Missed';
        bg = const Color(0xFFEF4444).withValues(alpha: 0.15);
        fg = const Color(0xFFDC2626);
        break;
      case NotificationType.refillAdded:
        label = lang == 'bn' ? 'রিফিল' : 'Refill';
        bg = const Color(0xFF3B82F6).withValues(alpha: 0.15);
        fg = const Color(0xFF2563EB);
        break;
      case NotificationType.lowStock:
        label = lang == 'bn' ? 'সতর্কতা' : 'Low Stock';
        bg = const Color(0xFFEA580C).withValues(alpha: 0.15);
        fg = const Color(0xFFC2410C);
        break;
      case NotificationType.medicineAdded:
        label = lang == 'bn' ? 'নতুন ওষুধ' : 'Added';
        bg = const Color(0xFF0D9488).withValues(alpha: 0.15);
        fg = const Color(0xFF0F766E);
        break;
      case NotificationType.medicineUpdated:
        label = lang == 'bn' ? 'আপডেট' : 'Updated';
        bg = const Color(0xFF6366F1).withValues(alpha: 0.15);
        fg = const Color(0xFF4F46E5);
        break;
      case NotificationType.reminderDue:
      case NotificationType.testAlarm:
        label = lang == 'bn' ? 'অ্যালার্ম' : 'Alarm';
        bg = const Color(0xFFEC4899).withValues(alpha: 0.15);
        fg = const Color(0xFFDB2777);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ==================== TIMESTAMP FORMATTER ====================
  String _formatNotificationTimestamp(DateTime dt, String lang) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notifDay = DateTime(dt.year, dt.month, dt.day);
    final diffDays = today.difference(notifDay).inDays;

    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final isPm = hour >= 12;
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayHourStr = displayHour.toString().padLeft(2, '0');

    if (lang == 'bn') {
      final period = hour < 6 ? 'রাত' : (hour < 12 ? 'সকাল' : (hour < 16 ? 'দুপুর' : (hour < 19 ? 'বিকাল' : 'রাত')));
      final bnTime = '$period $displayHourStr:$minute'
          .replaceAll('0', '০')
          .replaceAll('1', '১')
          .replaceAll('2', '২')
          .replaceAll('3', '৩')
          .replaceAll('4', '৪')
          .replaceAll('5', '৫')
          .replaceAll('6', '৬')
          .replaceAll('7', '৭')
          .replaceAll('8', '৮')
          .replaceAll('9', '৯');
      if (diffDays == 0) {
        return 'আজ, $bnTime';
      } else if (diffDays == 1) {
        return 'গতকাল, $bnTime';
      } else {
        final dateFormatted = DateFormat('dd MMM').format(dt);
        return '$dateFormatted, $bnTime';
      }
    } else {
      final period = isPm ? 'PM' : 'AM';
      final enTime = '$displayHourStr:$minute $period';
      if (diffDays == 0) {
        return 'Today, $enTime';
      } else if (diffDays == 1) {
        return 'Yesterday, $enTime';
      } else {
        return '${DateFormat('dd MMM').format(dt)}, $enTime';
      }
    }
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
