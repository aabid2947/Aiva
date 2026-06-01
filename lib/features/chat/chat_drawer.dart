import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/motion/page_transitions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/util/time_format.dart';
import '../../core/widgets/aiva_wordmark.dart';
import '../../core/widgets/skeleton.dart';
import '../../models/chat.dart';
import '../appointments/appointments_screen.dart';
import '../auth/auth_state.dart';
import '../mail/mail_screen.dart';
import '../notifications/notifications_screen.dart';
import '../reminders/reminders_screen.dart';
import 'chat_state.dart';

/// Navigation drawer: branded account header, searchable chat history with
/// selected-state pills, and a grouped footer. Items stagger in each time the
/// drawer opens (driven by [openSignal] bumped from the Scaffold).
class ChatDrawer extends StatefulWidget {
  const ChatDrawer({super.key, required this.openSignal});

  final ValueListenable<int> openSignal;

  @override
  State<ChatDrawer> createState() => _ChatDrawerState();
}

class _ChatDrawerState extends State<ChatDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  )..forward();

  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    widget.openSignal.addListener(_replay);
  }

  @override
  void dispose() {
    widget.openSignal.removeListener(_replay);
    _entrance.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _replay() {
    _entrance
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatState>();
    final auth = context.watch<AuthState>();
    final theme = Theme.of(context);

    final chats = _query.isEmpty
        ? chat.chats
        : chat.chats
            .where((c) => c.displayTitle.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    var order = 0;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ----- Branded account header -----
            _Stagger(
              controller: _entrance,
              order: order++,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Image.asset('assets/images/aiva_logo.png'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AivaWordmark(fontSize: 18),
                          const SizedBox(height: 2),
                          Text(
                            auth.user?.email ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ----- New chat (primary action) -----
            _Stagger(
              controller: _entrance,
              order: order++,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: FilledButton.icon(
                  onPressed: () {
                    context.read<ChatState>().startNewChat();
                    Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: const RoundedRectangleBorder(borderRadius: AppRadii.rMd),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('New chat'),
                ),
              ),
            ),

            // ----- Search -----
            if (chat.chats.length > 4)
              _Stagger(
                controller: _entrance,
                order: order++,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Search chats',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: AppSpacing.sm),

            // ----- History -----
            Expanded(
              child: chat.loadingChats
                  ? const _ChatListSkeleton()
                  : chats.isEmpty
                      ? _EmptyHistory(searching: _query.isNotEmpty)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                          itemCount: chats.length,
                          itemBuilder: (_, i) {
                            final c = chats[i];
                            return _Stagger(
                              controller: _entrance,
                              order: order + i,
                              child: _ChatRow(
                                chat: c,
                                selected: c.id == chat.currentChat?.id,
                                onTap: () {
                                  context.read<ChatState>().openChat(c);
                                  Navigator.of(context).pop();
                                },
                              ),
                            );
                          },
                        ),
            ),

            // ----- Grouped footer -----
            Divider(color: context.palette.hairline, height: 1),
            _Stagger(
              controller: _entrance,
              order: order++,
              child: Column(
                children: [
                  _NavTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                          sharedAxisRoute<void>((_) => const NotificationsScreen()));
                    },
                  ),
                  _NavTile(
                    icon: Icons.alarm_outlined,
                    label: 'Reminders',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                          sharedAxisRoute<void>((_) => const RemindersScreen()));
                    },
                  ),
                  _NavTile(
                    icon: Icons.mark_email_unread_outlined,
                    label: 'Mail monitoring',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context)
                          .push(sharedAxisRoute<void>((_) => const MailScreen()));
                    },
                  ),
                  _NavTile(
                    icon: Icons.event_outlined,
                    label: 'Appointments',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                          sharedAxisRoute<void>((_) => const AppointmentsScreen()));
                    },
                  ),
                  _NavTile(
                    icon: Icons.logout,
                    label: 'Log out',
                    onTap: () => context.read<AuthState>().logout(),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.sm),
                    child: _ThemeToggle(),
                  ), // _ThemeToggle is const-constructible
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatListSkeleton extends StatelessWidget {
  const _ChatListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      children: List.generate(
        6,
        (i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              const SkeletonBox(width: 20, height: 20, radius: AppRadii.sm),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: SkeletonBox(
                    height: 12, width: i.isEven ? 160 : 120),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({required this.chat, required this.selected, required this.onTap});

  final Chat chat;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = chat.updatedAt ?? chat.createdAt;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? theme.colorScheme.primary.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: AppRadii.rMd,
        child: InkWell(
          borderRadius: AppRadii.rMd,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md - 2),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 20,
                  color: selected
                      ? theme.colorScheme.primary
                      : context.palette.muted,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    chat.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? theme.colorScheme.primary : null,
                    ),
                  ),
                ),
                if (time != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(relativeTime(time), style: theme.textTheme.labelSmall),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      visualDensity: VisualDensity.compact,
      onTap: onTap,
    );
  }
}

/// Segmented system / light / dark theme switch (persisted via ThemeController).
class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    final theme = Theme.of(context);

    Widget seg(ThemeMode mode, IconData icon, String tip) {
      final selected = controller.mode == mode;
      return Expanded(
        child: Tooltip(
          message: tip,
          child: InkWell(
            borderRadius: AppRadii.rMd,
            onTap: () => context.read<ThemeController>().setMode(mode),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primary.withValues(alpha: 0.14)
                    : Colors.transparent,
                borderRadius: AppRadii.rMd,
              ),
              child: Icon(icon,
                  size: 20,
                  color: selected
                      ? theme.colorScheme.primary
                      : context.palette.muted),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: AppRadii.rMd,
        border: Border.all(color: context.palette.hairline),
      ),
      child: Row(
        children: [
          seg(ThemeMode.system, Icons.brightness_auto_outlined, 'System theme'),
          seg(ThemeMode.light, Icons.light_mode_outlined, 'Light theme'),
          seg(ThemeMode.dark, Icons.dark_mode_outlined, 'Dark theme'),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.searching});
  final bool searching;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(searching ? Icons.search_off : Icons.forum_outlined,
                size: 40, color: context.palette.muted),
            const SizedBox(height: AppSpacing.sm),
            Text(
              searching ? 'No matching chats' : 'No chats yet',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Applies an interval-based fade + slide based on [order] so a column of items
/// staggers in as [controller] runs.
class _Stagger extends StatelessWidget {
  const _Stagger({
    required this.controller,
    required this.order,
    required this.child,
  });

  final AnimationController controller;
  final int order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = (order * 0.06).clamp(0.0, 0.6);
    final anim = CurvedAnimation(
      parent: controller,
      curve: Interval(start, (start + 0.5).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        return Opacity(
          opacity: anim.value,
          child: Transform.translate(
            offset: Offset(0, (1 - anim.value) * 8),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
