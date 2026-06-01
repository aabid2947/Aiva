import 'package:flutter/material.dart';

import '../../core/app_keys.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/util/time_format.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/stagger_in.dart';
import '../../models/app_notification.dart';
import '../../services/notification_service.dart';
import 'notification_routing.dart';

/// The notification center: every push the user received, newest first, with
/// read/unread state. Tapping a row marks it read and routes to its target.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, NotificationService? service})
      : _service = service;

  final NotificationService? _service;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final NotificationService _service = widget._service ?? NotificationService();
  late Future<List<AppNotification>> _future;

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Future<List<AppNotification>> _load() async {
    final feed = await _service.list();
    if (mounted) _entrance.forward(from: 0);
    return feed.items;
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  void _onTap(AppNotification n) {
    if (!n.read) {
      _service.markRead(n.id).then((_) {
        notificationPing.value++;
      }).catchError((_) {});
    }
    routeNotification(n.data);
  }

  Future<void> _markAllRead() async {
    try {
      await _service.markAllRead();
      notificationPing.value++;
      await _refresh();
    } catch (_) {
      if (mounted) AppToast.error(context, "Couldn't update notifications.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Mark all read',
            onPressed: _markAllRead,
            icon: const Icon(Icons.done_all),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<AppNotification>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingList();
            }
            if (snapshot.hasError) {
              return const _FullScreenState(
                icon: Icons.error_outline,
                title: "Couldn't load notifications",
                message: 'Pull down to try again.',
              );
            }
            final items = snapshot.data ?? const <AppNotification>[];
            if (items.isEmpty) {
              return const _FullScreenState(
                icon: Icons.notifications_none,
                title: 'No notifications yet',
                message: 'Reminders, important mail, and appointment updates show up here.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: items.length,
              itemBuilder: (_, i) => StaggerIn(
                controller: _entrance,
                order: i,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _NotificationCard(
                    notification: items[i],
                    onTap: () => _onTap(items[i]),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

({Color color, IconData icon}) _visualFor(String type) {
  return switch (type) {
    'reminder' => (color: AppColors.info, icon: Icons.alarm),
    'mail' => (color: AppColors.brandBlue, icon: Icons.mark_email_unread),
    'mail_reauth' => (color: AppColors.warning, icon: Icons.link_off),
    'incoming_call' => (color: AppColors.success, icon: Icons.call),
    'appointment_outcome' => (color: AppColors.success, icon: Icons.event_available),
    _ => (color: AppColors.neutral, icon: Icons.notifications),
  };
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final n = notification;
    final v = _visualFor(n.type);

    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: v.color.withValues(alpha: 0.14),
              borderRadius: AppRadii.rMd,
            ),
            child: Icon(v.icon, size: 20, color: v.color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        n.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: n.read ? FontWeight.w500 : FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!n.read) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                if (n.body != null && n.body!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    n.body!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (n.createdAt != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(relativeTime(n.createdAt!), style: theme.textTheme.labelSmall),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 20, color: context.palette.muted),
        ],
      ),
    );
  }
}

class _FullScreenState extends StatelessWidget {
  const _FullScreenState({required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: EmptyState(icon: icon, title: title, message: message),
        ),
      ],
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 6,
      itemBuilder: (_, _) => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.sm),
        child: AppCard(
          child: Row(
            children: [
              SkeletonBox(width: 40, height: 40, radius: AppRadii.md),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 14, width: 140),
                    SizedBox(height: AppSpacing.sm),
                    SkeletonBox(height: 12, width: 220),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
