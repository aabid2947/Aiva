import 'package:dio/dio.dart';

import '../models/appointment.dart';
import 'api_client.dart';

/// Reads the user's appointment bookings from the AIVA backend. Booking itself
/// happens conversationally in chat; the call + outcome are handled by the
/// VoiceStream worker (see backend Prompts 9–11).
class AppointmentService {
  AppointmentService({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;
  Dio get _dio => _api.dio;

  Future<List<Appointment>> list() async {
    final res = await _dio.get<List<dynamic>>('/appointments');
    return (res.data ?? <dynamic>[])
        .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> cancel(int id) async {
    await _dio.delete<dynamic>('/appointments/$id');
  }

  /// Edit a pending appointment. Only sends the provided fields; `scheduledCallAt`
  /// goes as UTC. The backend enforces the booking rules (e.g. medical needs DOB).
  Future<Appointment> update(int id, Map<String, dynamic> changes) async {
    final body = Map<String, dynamic>.from(changes);
    if (body['scheduled_call_at'] is DateTime) {
      body['scheduled_call_at'] =
          (body['scheduled_call_at'] as DateTime).toUtc().toIso8601String();
    }
    final res = await _dio.put<Map<String, dynamic>>('/appointments/$id', data: body);
    return Appointment.fromJson(res.data!);
  }
}
