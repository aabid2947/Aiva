import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../services/mail_service.dart';

/// The important mail to spotlight when the screen is opened from a mail
/// notification — carries enough to show the subject/sender and deep-link to it.
class MailHighlight {
  const MailHighlight({required this.subject, this.sender, this.rfc822MsgId});

  factory MailHighlight.fromData(Map<String, dynamic> data) => MailHighlight(
        subject: (data['subject'] as String?)?.trim().isNotEmpty == true
            ? data['subject'] as String
            : 'Important email',
        sender: data['sender'] as String?,
        rfc822MsgId: data['rfc822_msgid'] as String?,
      );

  final String subject;
  final String? sender;
  final String? rfc822MsgId;
}

class MailScreen extends StatefulWidget {
  const MailScreen({super.key, MailService? service, this.highlight})
      : _service = service;

  final MailService? _service;

  /// When set (opened from a mail notification), shows a spotlight card with an
  /// "Open in Gmail" action that deep-links to the exact message.
  final MailHighlight? highlight;

  @override
  State<MailScreen> createState() => _MailScreenState();
}

class _MailScreenState extends State<MailScreen> {
  late final MailService _service = widget._service ?? MailService();
  final _criteriaController = TextEditingController();

  MailStatus? _status;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _criteriaController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final status = await _service.status();
      _criteriaController.text = status.importanceCriteria ?? '';
      if (mounted) setState(() => _status = status);
    } on DioException catch (e) {
      if (mounted) setState(() => _error = _messageFrom(e));
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _connect() async {
    try {
      final url = await _service.connectUrl();
      final launched =
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (launched) {
        AppToast.info(context, 'Finish in your browser — you’ll return to AIVA.');
      } else {
        AppToast.error(context, "Couldn't open the browser.");
      }
    } on DioException catch (e) {
      if (mounted) AppToast.error(context, _messageFrom(e));
    }
  }

  Future<void> _save() async {
    final status = _status;
    if (status == null) return;
    setState(() => _saving = true);
    try {
      final updated = await _service.updateWatch(
        enabled: status.enabled,
        importanceCriteria: _criteriaController.text.trim().isEmpty
            ? null
            : _criteriaController.text.trim(),
      );
      if (mounted) setState(() => _status = updated);
      if (mounted) AppToast.success(context, 'Monitoring preferences saved.');
    } on DioException catch (e) {
      if (mounted) AppToast.error(context, _messageFrom(e));
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _disconnect() async {
    HapticFeedback.mediumImpact();
    try {
      await _service.disconnect();
      if (mounted) AppToast.success(context, 'Gmail disconnected.');
    } on DioException catch (e) {
      if (mounted) AppToast.error(context, _messageFrom(e));
    }
    await _load();
  }

  String _messageFrom(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['detail'] is String) return data['detail'] as String;
    return 'Request failed (${e.response?.statusCode ?? 'network'}).';
  }

  Future<void> _openInGmail(MailHighlight h) async {
    // Deep-link to the exact message via Gmail's rfc822msgid search; fall back to
    // the inbox if we don't have the RFC822 Message-ID.
    final id = h.rfc822MsgId?.trim();
    final url = (id != null && id.isNotEmpty)
        ? 'https://mail.google.com/mail/u/0/#search/${Uri.encodeComponent('rfc822msgid:$id')}'
        : 'https://mail.google.com/mail/u/0/#inbox';
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!ok) AppToast.error(context, "Couldn't open Gmail.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mail monitoring'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const _LoadingBody()
          : _error != null
              ? EmptyState(
                  icon: Icons.error_outline,
                  title: "Couldn't load",
                  message: _error,
                  action: FilledButton(onPressed: _load, child: const Text('Retry')),
                )
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final status = _status!;
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (widget.highlight != null) ...[
          _HighlightCard(
            highlight: widget.highlight!,
            onOpen: () => _openInGmail(widget.highlight!),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        _HeroCard(connected: status.connected),
        const SizedBox(height: AppSpacing.lg),
        if (!status.connected)
          FilledButton.icon(
            onPressed: _connect,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            icon: const Icon(Icons.link),
            label: const Text('Connect Gmail'),
          )
        else ...[
          const SectionHeader('Monitoring'),
          AppCard(
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              title: const Text('Watch my inbox'),
              subtitle: Text(
                'AIVA flags important mail and notifies you.',
                style: theme.textTheme.bodySmall,
              ),
              value: status.enabled,
              onChanged: (v) => setState(() => _status = MailStatus(
                    connected: status.connected,
                    enabled: v,
                    importanceCriteria: status.importanceCriteria,
                  )),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader('What counts as important?'),
          TextField(
            controller: _criteriaController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'e.g. messages from my manager, invoices, anything urgent',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: _saving
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: _disconnect,
            icon: const Icon(Icons.link_off, size: 18),
            label: const Text('Disconnect Gmail'),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          ),
        ],
      ],
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.highlight, required this.onOpen});

  final MailHighlight highlight;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mark_email_unread, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.xs + 2),
              Text('Important email', style: theme.textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            highlight.subject,
            style: theme.textTheme.titleMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (highlight.sender != null && highlight.sender!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'From ${highlight.sender}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Open in Gmail'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.connected});
  final bool connected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: AppRadii.rMd,
            ),
            child: Image.asset('assets/images/aiva_logo.png'),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      connected ? Icons.check_circle : Icons.mark_email_unread_outlined,
                      size: 18,
                      color: connected ? AppColors.success : context.palette.muted,
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
                    Text(
                      connected ? 'Gmail connected' : 'Gmail not connected',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  connected
                      ? 'AIVA can read your inbox to flag important mail.'
                      : 'Connect Gmail so AIVA can watch for important mail.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: const [
        AppCard(
          child: Row(
            children: [
              SkeletonBox(width: 56, height: 56, radius: AppRadii.md),
              SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 16, width: 160),
                    SizedBox(height: AppSpacing.sm),
                    SkeletonBox(height: 12, width: 220),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        SkeletonBox(height: 52, radius: AppRadii.lg),
      ],
    );
  }
}
