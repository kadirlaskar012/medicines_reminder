import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'All'; // All, Reminders, Updates

  final List<Map<String, dynamic>> _notifications = [
    {
      'type': 'reminder',
      'title': 'Paracetamol Reminder',
      'body': 'Time to take your medicine',
      'time': '08:30 AM',
      'icon': Icons.notifications_active_rounded,
      'color': const Color(0xFF2563EB),
    },
    {
      'type': 'taken',
      'title': 'Medicine Taken',
      'body': 'Paracetamol marked as taken',
      'time': '08:30 AM',
      'icon': Icons.check_circle_rounded,
      'color': const Color(0xFF10B981),
    },
    {
      'type': 'upcoming',
      'title': 'Upcoming Reminder',
      'body': 'Vitamin D3 at 01:00 PM',
      'time': '12:30 PM',
      'icon': Icons.schedule_rounded,
      'color': const Color(0xFFF59E0B),
    },
    {
      'type': 'missed',
      'title': 'Missed Reminder',
      'body': 'Amoxicillin was missed',
      'time': 'Yesterday',
      'icon': Icons.cancel_rounded,
      'color': const Color(0xFFEF4444),
    },
    {
      'type': 'update',
      'title': 'Weekly Report',
      'body': 'Your health report is ready',
      'time': '2 days ago',
      'icon': Icons.description_rounded,
      'color': const Color(0xFF10B981),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = _notifications.where((n) {
      if (_selectedFilter == 'Reminders') {
        return n['type'] == 'reminder' || n['type'] == 'upcoming' || n['type'] == 'missed';
      }
      if (_selectedFilter == 'Updates') {
        return n['type'] == 'update' || n['type'] == 'taken';
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter Chips ([All] [Reminders] [Updates])
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: ['All', 'Reminders', 'Updates'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : (isDark ? AppColors.darkCard : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : (isDark ? AppColors.darkTextMuted : const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Notification List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (ctx, idx) {
                final item = filtered[idx];
                final color = item['color'] as Color;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item['icon'] as IconData, color: color, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] as String,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item['body'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        item['time'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
