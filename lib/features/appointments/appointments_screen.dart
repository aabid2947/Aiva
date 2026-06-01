import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/motion/page_transitions.dart';
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
import '../../models/appointment.dart';
import '../../services/appointment_service.dart';
import 'appointment_edit_screen.dart';

/// Lists the user's appointment bookings + their status. Booking happens in
/// chat; the call rings the app at the scheduled time and the outcome also
/// arrives as a chat message + push (backend Prompt 11).
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  final AppointmentService _service = AppointmentService();
  late Future<List<Appointment>> _future;

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

  Future<List<Appointment>> _load() async {
    final items = await _service.list();
    if (mounted) _entrance.forward(from: 0);
    return items;
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  Future<void> _cancel(Appointment a) async {
    HapticFeedback.mediumImpact();
    try {
      await _service.cancel(a.id);
      if (mounted) AppToast.success(context, 'Appointment cancelled.');
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, "Couldn't cancel the appointment.");
    }
  }

  Future<void> _edit(Appointment a) async {
    final saved = await Navigator.of(context).push<bool>(
      sharedAxisRoute<bool>((_) => AppointmentEditScreen(appointment: a)),
    );
    if (saved == true) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Appointment>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingList();
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: EmptyState(
                      icon: Icons.error_outline,
                      title: "Couldn't load appointments",
                      message: 'Pull down to try again.',
                    ),
                  ),
                ],
              );
            }
            final items = snapshot.data ?? const <Appointment>[];
            if (items.isEmpty) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: const EmptyState(
                      icon: Icons.event_available_outlined,
                      title: 'No appointments yet',
                      message: 'Ask AIVA in chat to book one for you.',
                    ),
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                const ChatEditTip(example: '"reschedule my dentist call to tomorrow 3pm"'),
                const SizedBox(height: AppSpacing.md),
                for (var i = 0; i < items.length; i++)
                  StaggerIn(
                    controller: _entrance,
                    order: i,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _AppointmentCard(
                        appointment: items[i],
                        onEdit: () => _edit(items[i]),
                        onCancel: () => _cancel(items[i]),
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
    'confirmed' => (color: AppColors.success, icon: Icons.check_circle, label: 'Confirmed'),
    'declined' => (color: AppColors.danger, icon: Icons.cancel, label: 'Declined'),
    'failed' => (color: AppColors.warning, icon: Icons.error_outline, label: 'Failed'),
    'in_progress' => (color: AppColors.info, icon: Icons.call, label: 'In progress'),
    _ => (color: AppColors.neutral, icon: Icons.schedule, label: 'Pending'),
  };
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment, required this.onEdit, required this.onCancel});

  final Appointment appointment;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = appointment;
    final v = _statusVisual(a.status);
    final reason = a.appointmentReason ?? a.appointmentType ?? 'Appointment';
    final when = a.scheduledCallAt;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(a.target,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusChip(label: v.label, color: v.color, icon: v.icon),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            reason,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (when != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: context.palette.muted),
                const SizedBox(width: AppSpacing.xs + 2),
                Text(relativeTime(when), style: theme.textTheme.labelMedium),
              ],
            ),
          ],
          if (a.outcomeConfirmationNumber != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.confirmation_number_outlined,
                    size: 16, color: AppColors.success),
                const SizedBox(width: AppSpacing.xs + 2),
                Text('Confirmation ${a.outcomeConfirmationNumber}',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: AppColors.success)),
              ],
            ),
          ],
          if (a.isPending) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (a.isEditable)
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                const SizedBox(width: AppSpacing.xs),
                TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Cancel'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                ),
              ],
            ),
          ],
        ],
      ),
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
                  Expanded(child: SkeletonBox(height: 18, width: 160)),
                  SizedBox(width: AppSpacing.sm),
                  SkeletonBox(height: 22, width: 84, radius: AppRadii.pill),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              SkeletonBox(height: 12, width: 220),
              SizedBox(height: AppSpacing.sm),
              SkeletonBox(height: 12, width: 120),
            ],
          ),
        ),
      ),
    );
  }
}
