import 'package:flutter/material.dart';

import '../../core/app_keys.dart';
import '../../core/motion/page_transitions.dart';
import '../../services/notification_service.dart';
import 'notifications_screen.dart';

/// App-bar bell with an unread badge. Refreshes its count on mount, whenever a
/// push arrives (via [notificationPing]), and after the user views the feed.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key, NotificationService? service})
      : _service = service;

  final NotificationService? _service;

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  late final NotificationService _service = widget._service ?? NotificationService();
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    notificationPing.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    notificationPing.removeListener(_load);
    super.dispose();
  }

  void _load() {
    _service.unreadCount().then((count) {
      if (mounted) setState(() => _unread = count);
    }).catchError((_) {});
  }

  void _open() {
    navigatorKey.currentState
        ?.push(sharedAxisRoute<void>((_) => const NotificationsScreen()))
        .then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Notifications',
      onPressed: _open,
      icon: Badge(
        isLabelVisible: _unread > 0,
        label: Text(_unread > 99 ? '99+' : '$_unread'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
