import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/util/time_format.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/chat_edit_tip.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/stagger_in.dart';
import '../../core/widgets/status_chip.dart';
import '../../core/motion/page_transitions.dart';
import '../../models/reminder.dart';
import '../../services/reminder_service.dart';
import 'reminder_edit_screen.dart';

/// Lists the user's reminders. Creation happens in chat; at the due time the
/// worker sends an FCM push (which also lands in the notification feed).
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key, ReminderService? service}) : _service = service;

  final ReminderService? _service;

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen>
    with SingleTickerProviderStateMixin {
  late final ReminderService _service = widget._service ?? ReminderService();
  late Future<List<Reminder>> _future;

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

  Future<List<Reminder>> _load() async {
    final items = await _service.list();
    // Pending first, then by soonest due.
    items.sort((a, b) {
      if (a.isPending != b.isPending) return a.isPending ? -1 : 1;
      return a.dueAt.compareTo(b.dueAt);
    });
    if (mounted) _entrance.forward(from: 0);
    return items;
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  Future<void> _cancel(Reminder r) async {
    HapticFeedback.mediumImpact();
    try {
      await _service.cancel(r.id);
      if (mounted) AppToast.success(context, 'Reminder cancelled.');
      await _refresh();
    } catch (_) {
      if (mounted) AppToast.error(context, "Couldn't cancel the reminder.");
    }
  }

  Future<void> _edit(Reminder r) async {
    final saved = await Navigator.of(context).push<bool>(
      sharedAxisRoute<bool>((_) => ReminderEditScreen(reminder: r)),
    );
    if (saved == true) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Reminder>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingList();
            }
            if (snapshot.hasError) {
              return _FullScreenState(
                icon: Icons.error_outline,
                title: "Couldn't load reminders",
                message: 'Pull down to try again.',
              );
            }
            final items = snapshot.data ?? const <Reminder>[];
            if (items.isEmpty) {
              return const _FullScreenState(
                icon: Icons.alarm_outlined,
                title: 'No reminders yet',
                message: 'Ask AIVA in chat, e.g. "remind me to call mom at 6pm".',
              );
            }
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                const ChatEditTip(example: '"move my dentist reminder to 6pm"'),
                const SizedBox(height: AppSpacing.md),
                for (var i = 0; i < items.length; i++)
                  StaggerIn(
                    controller: _entrance,
                    order: i,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _ReminderCard(
                        reminder: items[i],
                        onEdit: items[i].isPending ? () => _edit(items[i]) : null,
                        onCancel: items[i].isPending ? () => _cancel(items[i]) : null,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

({Color color, IconData icon, String label}) _statusVisual(String status) {
  return switch (status) {
    'sent' => (color: AppColors.success, icon: Icons.check_circle, label: 'Sent'),
    'cancelled' => (color: AppColors.neutral, icon: Icons.cancel, label: 'Cancelled'),
    _ => (color: AppColors.info, icon: Icons.schedule, label: 'Pending'),
  };
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.reminder, this.onEdit, this.onCancel});

  final Reminder reminder;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = reminder;
    final v = _statusVisual(r.status);
    final due = r.dueAt.toLocal();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(r.content,
                    style: theme.textTheme.titleMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusChip(label: v.label, color: v.color, icon: v.icon),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.alarm, size: 16, color: context.palette.muted),
              const SizedBox(width: AppSpacing.xs + 2),
              Expanded(
                child: Text(
                  '${_formatDate(due)}  ·  ${relativeTime(r.dueAt)}',
                  style: theme.textTheme.labelMedium,
                ),
              ),
            ],
          ),
          if (onEdit != null || onCancel != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onEdit != null)
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                if (onCancel != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Cancel'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

String _formatDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  final ampm = d.hour < 12 ? 'AM' : 'PM';
  return '${months[d.month - 1]} ${d.day}, $h:$m $ampm';
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
      itemCount: 4,
      itemBuilder: (_, _) => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.md),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: SkeletonBox(height: 18, width: 180)),
                  SizedBox(width: AppSpacing.sm),
                  SkeletonBox(height: 22, width: 78, radius: AppRadii.pill),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              SkeletonBox(height: 12, width: 160),
            ],
          ),
        ),
      ),
    );
  }
}
