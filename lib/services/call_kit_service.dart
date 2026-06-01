import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

import '../core/app_keys.dart';
import '../core/motion/page_transitions.dart';
import '../features/appointments/call_screen.dart';

/// Native incoming-call experience (ringtone + vibration + full-screen UI that
/// shows even when the app is killed or the screen is locked), backed by the
/// `flutter_callkit_incoming` plugin.
///
/// Flow: an FCM `incoming_call` data message (sent DATA-ONLY + high priority so
/// the OS wakes the app) → [showIncomingCall] raises the native ringing UI →
/// the user accepts/declines on that UI → [CallKitService.listen] turns an
/// "accept" into the in-app [CallScreen] (which WebRTC-connects to VoiceStream).

CallKitParams _paramsFromData(Map<String, dynamic> data) {
  final id = '${data['booking_request_id'] ?? ''}';
  final target = (data['target']?.toString())?.trim() ?? '';
  final caller = (data['caller_name']?.toString())?.trim() ?? '';
  return CallKitParams(
    id: id.isEmpty ? 'aiva-call' : id,
    nameCaller: caller.isEmpty ? 'AIVA' : caller,
    appName: 'AIVA',
    handle: target.isEmpty ? 'Appointment call' : target,
    type: 0, // audio
    duration: 45000, // auto-miss after 45s of ringing
    textAccept: 'Accept',
    textDecline: 'Decline',
    missedCallNotification: const NotificationParams(
      showNotification: true,
      isShowCallback: false,
      subtitle: 'Missed appointment call',
    ),
    extra: <String, dynamic>{
      'booking_request_id': id,
      'target': target,
      'caller_name': caller,
    },
    android: const AndroidParams(
      isCustomNotification: true,
      isShowLogo: false,
      ringtonePath: 'system_ringtone_default',
      backgroundColor: '#0E1116',
      actionColor: '#5865F2',
      incomingCallNotificationChannelName: 'Incoming calls',
      isShowFullLockedScreen: true,
    ),
  );
}

/// Raise the native incoming-call UI for an FCM data payload. Safe to call from
/// the FCM background isolate — it only talks to the CallKit method channel.
Future<void> showIncomingCall(Map<String, dynamic> data) async {
  await FlutterCallkitIncoming.showCallkitIncoming(_paramsFromData(data));
}

class CallKitService {
  CallKitService._();
  static final CallKitService instance = CallKitService._();

  bool _listening = false;

  /// Start handling accept/decline events from the native call UI. Idempotent;
  /// call once early (events fire here whether the app was foreground, background,
  /// or relaunched by the user accepting from the lock screen).
  void listen() {
    if (_listening) return;
    _listening = true;
    FlutterCallkitIncoming.onEvent.listen(_onEvent);
  }

  Future<void> _onEvent(CallEvent? event) async {
    if (event == null) return;
    switch (event.event) {
      case Event.actionCallAccept:
        _openCallScreen(event.body);
      case Event.actionCallDecline:
      case Event.actionCallEnded:
      case Event.actionCallTimeout:
        await _endNative(event.body);
      default:
        break;
    }
  }

  /// If the app was killed and the user accepted from the native UI, the call is
  /// already active by the time our first screen builds — route straight into it.
  Future<void> handleColdStart() async {
    try {
      final calls = await FlutterCallkitIncoming.activeCalls();
      if (calls is List && calls.isNotEmpty) {
        _openCallScreen(calls.first);
      }
    } catch (_) {
      // best effort
    }
  }

  void _openCallScreen(dynamic body) {
    final map = _extra(body);
    final id = int.tryParse('${map['booking_request_id'] ?? ''}');
    if (id == null) return;
    final target = '${map['target'] ?? ''}'.trim();
    final caller = '${map['caller_name'] ?? ''}'.trim();
    navigatorKey.currentState?.push(
      fadeThroughRoute<void>(
        (_) => CallScreen(
          bookingRequestId: id,
          target: target.isEmpty ? 'the appointment' : target,
          callerName: caller.isEmpty ? null : caller,
          autoConnect: true, // already accepted natively → connect immediately
        ),
      ),
    );
  }

  Future<void> _endNative(dynamic body) async {
    try {
      final map = _extra(body);
      final id = '${map['booking_request_id'] ?? (body is Map ? body['id'] : '') ?? ''}';
      if (id.isNotEmpty) {
        await FlutterCallkitIncoming.endCall(id);
      } else {
        await FlutterCallkitIncoming.endAllCalls();
      }
    } catch (_) {
      // best effort
    }
  }

  Map _extra(dynamic body) {
    if (body is Map) {
      final extra = body['extra'];
      if (extra is Map) return extra;
      return body;
    }
    return const {};
  }
}
