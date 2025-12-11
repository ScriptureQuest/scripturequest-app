import 'dart:async';
import 'package:flutter/material.dart';
import 'package:level_up_your_faith/theme.dart';

/// Unified, high-contrast reward toast used for achievements, claims, and streaks.
///
/// Placement rules:
/// - Defaults to bottom, floating above system insets.
/// - If a modal bottom sheet is open (tracked via setBottomSheetOpen),
///   the toast renders near the top below the AppBar so it never overlaps
///   primary buttons in the sheet.
class RewardToast {
  RewardToast._();

  static OverlayEntry? _entry;
  static Timer? _timer;
  static bool _bottomSheetOpen = false;

  /// Call when opening/closing a modal bottom sheet so the toast can reposition.
  static void setBottomSheetOpen(bool open) {
    _bottomSheetOpen = open;
  }

  /// Generic reward toast
  static void show(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Duration? duration,
  }) {
    // Remove any existing toast before showing a new one
    _timer?.cancel();
    _entry?.remove();
    _entry = null;

    final overlay = Overlay.of(context, rootOverlay: true);
    if (overlay == null) return;

    final media = MediaQuery.of(context);
    final safeTop = media.padding.top;
    final safeBottom = media.viewPadding.bottom;
    final useTop = _bottomSheetOpen;

    const bg = Color(0xFF171B2A);

    _entry = OverlayEntry(
      builder: (ctx) {
        final width = MediaQuery.of(ctx).size.width;
        final horizontal = 12.0;
        final maxWidth = width - (horizontal * 2);
        return Positioned(
          left: horizontal,
          right: horizontal,
          top: useTop ? safeTop + kToolbarHeight + 10 : null,
          bottom: useTop ? null : safeBottom + 24,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle != null && subtitle.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_entry!);

    final total = duration ?? (useTop ? const Duration(milliseconds: 2200) : const Duration(milliseconds: 2800));
    _timer = Timer(total, () {
      _entry?.remove();
      _entry = null;
      _timer = null;
    });
  }

  /// Achievement unlocked helper (emoji_events icon + XP accent)
  static void showAchievementUnlocked(
    BuildContext context, {
    required String title,
    String? subtitle,
  }) {
    show(
      context,
      icon: Icons.emoji_events,
      iconColor: Theme.of(context).colorScheme.primary,
      title: 'Achievement Unlocked',
      subtitle: subtitle != null && subtitle.isNotEmpty ? '$title  •  $subtitle' : title,
    );
  }

  /// Simple claimed/info toast
  static void showClaimed(
    BuildContext context, {
    required String title,
    String? subtitle,
    IconData icon = Icons.redeem,
    Color? iconColor,
  }) {
    show(
      context,
      icon: icon,
      iconColor: iconColor ?? Theme.of(context).colorScheme.primary,
      title: title,
      subtitle: subtitle,
    );
  }

  /// Success toast variant (e.g., book completed)
  static void showSuccess(
    BuildContext context, {
    required String title,
    String? subtitle,
    IconData icon = Icons.check_circle,
  }) {
    final purple = Theme.of(context).extension<PurpleUi>();
    show(
      context,
      icon: icon,
      iconColor: purple?.success ?? GamerColors.success,
      title: title,
      subtitle: subtitle,
    );
  }
}
