import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/section_header.dart';
import '../../models/reminder.dart';
import '../../services/reminder_service.dart';

/// Edit a pending reminder's text and time. Pops `true` when saved.
class ReminderEditScreen extends StatefulWidget {
  const ReminderEditScreen({super.key, required this.reminder, ReminderService? service})
      : _service = service;

  final Reminder reminder;
  final ReminderService? _service;

  @override
  State<ReminderEditScreen> createState() => _ReminderEditScreenState();
}

class _ReminderEditScreenState extends State<ReminderEditScreen> {
  late final ReminderService _service = widget._service ?? ReminderService();
  late final TextEditingController _content =
      TextEditingController(text: widget.reminder.content);
  late DateTime _due = widget.reminder.dueAt.toLocal();
  bool _saving = false;

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _due.isBefore(now) ? now : _due,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_due),
    );
    if (time == null || !mounted) return;
    setState(() {
      _due = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    final text = _content.text.trim();
    if (text.isEmpty) {
      AppToast.warning(context, 'Reminder text can\'t be empty.');
      return;
    }
    if (!_due.isAfter(DateTime.now())) {
      AppToast.warning(context, 'Pick a time in the future.');
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.update(widget.reminder.id, content: text, dueAt: _due);
      if (!mounted) return;
      AppToast.success(context, 'Reminder updated.');
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (mounted) AppToast.error(context, _messageFrom(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _messageFrom(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['detail'] is String) return data['detail'] as String;
    return 'Could not save the reminder.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit reminder')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SectionHeader('Reminder'),
          TextField(
            controller: _content,
            minLines: 1,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'e.g. Call mom'),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader('When'),
          AppCard(
            onTap: _pickDateTime,
            child: Row(
              children: [
                Icon(Icons.alarm, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(_formatDateTime(_due), style: theme.textTheme.titleMedium)),
                const Icon(Icons.edit_calendar_outlined, size: 20),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: _saving
                ? const SizedBox(
                    height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save changes'),
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  final ampm = d.hour < 12 ? 'AM' : 'PM';
  return '${months[d.month - 1]} ${d.day}, ${d.year}  ·  $h:$m $ampm';
}
