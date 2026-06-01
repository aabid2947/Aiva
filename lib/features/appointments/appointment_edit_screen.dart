import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/section_header.dart';
import '../../models/appointment.dart';
import '../../services/appointment_service.dart';

const _types = ['medical', 'meeting', 'service', 'other'];

/// Edit a pending appointment's intake details. Pops `true` when saved. Medical
/// fields (DOB, insurance) only show for the medical type; the backend enforces
/// the same rules (DOB required for medical, who/where required, future time).
class AppointmentEditScreen extends StatefulWidget {
  const AppointmentEditScreen({
    super.key,
    required this.appointment,
    AppointmentService? service,
  }) : _service = service;

  final Appointment appointment;
  final AppointmentService? _service;

  @override
  State<AppointmentEditScreen> createState() => _AppointmentEditScreenState();
}

class _AppointmentEditScreenState extends State<AppointmentEditScreen> {
  late final AppointmentService _service = widget._service ?? AppointmentService();

  late String _type = _normalizedType(widget.appointment.appointmentType);
  late final _fullName = TextEditingController(text: widget.appointment.fullName ?? '');
  late final _reason = TextEditingController(text: widget.appointment.appointmentReason ?? '');
  late final _phone = TextEditingController(text: widget.appointment.phone ?? '');
  late final _contact = TextEditingController(text: widget.appointment.contactInfo ?? '');
  late final _hospital = TextEditingController(text: widget.appointment.targetHospitalName ?? '');
  late final _targetPhone = TextEditingController(text: widget.appointment.targetPhone ?? '');
  late final _dob = TextEditingController(text: widget.appointment.dateOfBirth ?? '');
  late final _insProvider = TextEditingController(text: widget.appointment.insuranceProvider ?? '');
  late final _insMember = TextEditingController(text: widget.appointment.insuranceMemberId ?? '');
  late DateTime? _when = widget.appointment.scheduledCallAt?.toLocal();
  bool _saving = false;

  static String _normalizedType(String? t) {
    final v = (t ?? '').toLowerCase();
    return _types.contains(v) ? v : 'other';
  }

  @override
  void dispose() {
    for (final c in [_fullName, _reason, _phone, _contact, _hospital, _targetPhone, _dob, _insProvider, _insMember]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickWhen() async {
    final now = DateTime.now();
    final base = _when ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: base.isBefore(now) ? now : base,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null || !mounted) return;
    setState(() {
      _when = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  String? _clientValidation() {
    if (_fullName.text.trim().isEmpty) return 'Full name can\'t be empty.';
    if (_reason.text.trim().isEmpty) return 'Reason can\'t be empty.';
    if (_phone.text.trim().isEmpty) return 'Your callback number can\'t be empty.';
    if (_when == null) return 'Pick when AIVA should call.';
    if (!_when!.isAfter(DateTime.now())) return 'The call time must be in the future.';
    if (_hospital.text.trim().isEmpty && _targetPhone.text.trim().isEmpty) {
      return 'Provide who or where to call (a name or a phone number).';
    }
    if (_type == 'medical' && _dob.text.trim().isEmpty) {
      return 'Date of birth is required for medical appointments.';
    }
    return null;
  }

  Future<void> _save() async {
    final err = _clientValidation();
    if (err != null) {
      AppToast.warning(context, err);
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.update(widget.appointment.id, {
        'appointment_type': _type,
        'full_name': _fullName.text.trim(),
        'appointment_reason': _reason.text.trim(),
        'phone': _phone.text.trim(),
        'contact_info': _contact.text.trim(),
        'target_hospital_name': _hospital.text.trim(),
        'target_phone': _targetPhone.text.trim(),
        'scheduled_call_at': _when,
        'date_of_birth': _type == 'medical' ? _dob.text.trim() : '',
        'insurance_provider': _type == 'medical' ? _insProvider.text.trim() : '',
        'insurance_member_id': _type == 'medical' ? _insMember.text.trim() : '',
      });
      if (!mounted) return;
      AppToast.success(context, 'Appointment updated.');
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
    return 'Could not save the appointment.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit appointment')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SectionHeader('Type'),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _type,
                items: _types
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t[0].toUpperCase() + t.substring(1)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          const SectionHeader('Details'),
          _field(_fullName, 'Full name (who AIVA represents)', Icons.person_outline),
          const SizedBox(height: AppSpacing.md),
          _field(_reason, 'Reason for the appointment', Icons.notes_outlined, maxLines: 3),
          const SizedBox(height: AppSpacing.md),
          _field(_phone, 'Your callback number', Icons.phone_outlined,
              keyboard: TextInputType.phone),
          const SizedBox(height: AppSpacing.md),
          _field(_contact, 'Extra contact info (optional)', Icons.alternate_email_outlined),
          const SizedBox(height: AppSpacing.lg),

          const SectionHeader('Who / where to call'),
          _field(_hospital, 'Place or person to call', Icons.local_hospital_outlined),
          const SizedBox(height: AppSpacing.md),
          _field(_targetPhone, 'Their phone number (optional)', Icons.call_outlined,
              keyboard: TextInputType.phone),
          const SizedBox(height: AppSpacing.lg),

          const SectionHeader('When should AIVA call?'),
          AppCard(
            onTap: _pickWhen,
            child: Row(
              children: [
                Icon(Icons.schedule, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    _when == null ? 'Pick a date & time' : _formatDateTime(_when!),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const Icon(Icons.edit_calendar_outlined, size: 20),
              ],
            ),
          ),

          if (_type == 'medical') ...[
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader('Medical'),
            _field(_dob, 'Date of birth (YYYY-MM-DD)', Icons.cake_outlined),
            const SizedBox(height: AppSpacing.md),
            _field(_insProvider, 'Insurance provider (optional)', Icons.shield_outlined),
            const SizedBox(height: AppSpacing.md),
            _field(_insMember, 'Insurance member ID (optional)', Icons.badge_outlined),
          ],

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

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: c,
      minLines: 1,
      maxLines: maxLines,
      keyboardType: keyboard,
      textCapitalization:
          maxLines > 1 ? TextCapitalization.sentences : TextCapitalization.words,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
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
