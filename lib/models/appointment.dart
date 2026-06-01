class Appointment {
  const Appointment({
    required this.id,
    required this.status,
    this.appointmentType,
    this.fullName,
    this.appointmentReason,
    this.phone,
    this.contactInfo,
    this.targetHospitalName,
    this.targetPhone,
    this.scheduledCallAt,
    this.dateOfBirth,
    this.insuranceProvider,
    this.insuranceMemberId,
    this.callTriggeredAt,
    this.outcomeScheduledTime,
    this.outcomeConfirmationNumber,
    this.createdAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: json['id'] as int,
        status: (json['status'] as String?) ?? 'pending',
        appointmentType: json['appointment_type'] as String?,
        fullName: json['full_name'] as String?,
        appointmentReason: json['appointment_reason'] as String?,
        phone: json['phone'] as String?,
        contactInfo: json['contact_info'] as String?,
        targetHospitalName: json['target_hospital_name'] as String?,
        targetPhone: json['target_phone'] as String?,
        scheduledCallAt: _date(json['scheduled_call_at']),
        dateOfBirth: json['date_of_birth'] as String?,
        insuranceProvider: json['insurance_provider'] as String?,
        insuranceMemberId: json['insurance_member_id'] as String?,
        callTriggeredAt: _date(json['call_triggered_at']),
        outcomeScheduledTime: _date(json['outcome_scheduled_time']),
        outcomeConfirmationNumber: json['outcome_confirmation_number'] as String?,
        createdAt: _date(json['created_at']),
      );

  final int id;
  final String status;
  final String? appointmentType;
  final String? fullName;
  final String? appointmentReason;
  final String? phone;
  final String? contactInfo;
  final String? targetHospitalName;
  final String? targetPhone;
  final DateTime? scheduledCallAt;
  final String? dateOfBirth;
  final String? insuranceProvider;
  final String? insuranceMemberId;
  final DateTime? callTriggeredAt;
  final DateTime? outcomeScheduledTime;
  final String? outcomeConfirmationNumber;
  final DateTime? createdAt;

  String get target => targetHospitalName ?? targetPhone ?? 'the appointment';

  /// Editable only while pending AND before AIVA has started the call.
  bool get isEditable => status == 'pending' && callTriggeredAt == null;

  bool get isPending => status == 'pending';

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
