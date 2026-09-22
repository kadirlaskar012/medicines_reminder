import 'dart:async';
import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';
import '../models/app_notification.dart';
import 'luxury_notification_card.dart';

/// Floating in-app Heads-Up Push Notification Banner.
/// Drops down gracefully from the top of the screen when a push notification triggers
/// while the app is in the foreground, delivering the exact luxury glassmorphism design.
class LuxuryHeadsUpBanner {
  static OverlayEntry? _activeEntry;
  static Timer? _autoDismissTimer;

  static void show({
    required BuildContext context,
    required AppNotification notification,
    required AppStrings s,
    VoidCallback? onTake,
    VoidCallback? onSnooze,
    VoidCallback? onSkip,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 7),
  }) {
    dismiss();

    final overlayState = Overlay.of(context, rootOverlay: true);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _HeadsUpBannerWidget(
        notification: notification,
        s: s,
        onTake: () {
          dismiss();
          onTake?.call();
        },
        onSnooze: () {
          dismiss();
          onSnooze?.call();
        },
        onSkip: () {
          dismiss();
          onSkip?.call();
        },
        onTap: () {
          dismiss();
          onTap?.call();
        },
        onDismiss: dismiss,
      ),
    );

    _activeEntry = entry;
    overlayState.insert(entry);

    _autoDismissTimer = Timer(duration, () {
      dismiss();
    });
  }

  static void dismiss() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    if (_activeEntry != null) {
      _activeEntry?.remove();
      _activeEntry = null;
    }
  }
}

class _HeadsUpBannerWidget extends StatefulWidget {
  final AppNotification notification;
  final AppStrings s;
  final VoidCallback onTake;
  final VoidCallback onSnooze;
  final VoidCallback onSkip;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _HeadsUpBannerWidget({
    required this.notification,
    required this.s,
    required this.onTake,
    required this.onSnooze,
    required this.onSkip,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_HeadsUpBannerWidget> createState() => _HeadsUpBannerWidgetState();
}

class _HeadsUpBannerWidgetState extends State<_HeadsUpBannerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 300),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _controller.forward();
  }

  Future<void> _animateAndDismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.paddingOf(context).top;

    return Positioned(
      top: topPadding + 8,
      left: 14,
      right: 14,
      child: SlideTransition(
        position: _offsetAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta != null && details.primaryDelta! < -6) {
                _animateAndDismiss();
              }
            },
            child: Material(
              color: Colors.transparent,
              child: LuxuryNotificationCard(
                notification: widget.notification,
                s: widget.s,
                isDark: isDark,
                onTake: widget.onTake,
                onSnooze: widget.onSnooze,
                onSkip: widget.onSkip,
                onTap: widget.onTap,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
