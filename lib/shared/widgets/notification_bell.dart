import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thryfto/core/providers/notification_providers.dart';

class NotificationBell extends ConsumerWidget {
  final VoidCallback onPressed;

  const NotificationBell({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);
    const ink = Color(0xFF17131F);
    const line = Color(0xFFE5DFEC);
    const surface = Color(0xFFFBFAFC);

    return unreadCountAsync.when(
      data: (unreadCount) {
        return Stack(
          children: [
            // Bell icon button
            IconButton(
              icon: const Icon(
                Icons.notifications_none_rounded,
                size: 22,
                color: ink,
              ),
              onPressed: onPressed,
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                backgroundColor: surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: line),
                ),
              ),
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
            ),
            // Badge with unread count
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFD94A4A),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => IconButton(
        icon: const Icon(Icons.notifications_none_rounded,
            size: 22, color: ink),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
      ),
      error: (_, __) => IconButton(
        icon: const Icon(Icons.notifications_none_rounded,
            size: 22, color: ink),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
      ),
    );
  }
}
