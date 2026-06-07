import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../core/app_keys.dart';
import '../core/motion/page_transitions.dart';
import '../core/widgets/app_toast.dart';
import '../features/appointments/call_screen.dart';
import '../features/notifications/notification_routing.dart';
import 'api_client.dart';

/// Top-level FCM background handler, run in its own isolate.
///
/// Intentionally a no-op: every push (calls included) now carries a NOTIFICATION
/// payload, so the OS renders + sounds it while the app is backgrounded/terminated
/// and the tap routes in via onMessageOpenedApp / getInitialMessage. We deliberately
/// do NOT raise the native CallKit ring here — the OS notification (high-importance
/// `incoming_calls` channel, see MainActivity) is the SINGLE ring. Raising CallKit
/// too made the phone play two overlapping ringtones at once.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No background work needed; the OS handles notification display + sound.
}

/// Firebase Cloud Messaging integration.
///
/// Degrades gracefully: if Firebase isn't configured yet (no google-services.json),
/// init fails quietly and push is simply disabled — the rest of the app still works.
/// See CLAUDE.md "Firebase / FCM setup" for the one-time configuration steps.
class PushService {
  PushService({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;
  bool _initialized = false;
  String? _token;

  Future<void> initAndRegister() async {
    if (_initialized) {
      // Already wired up. If we never got a token (e.g. FCM SERVICE_NOT_AVAILABLE
      // on a previous attempt), try again now; otherwise just re-register.
      if (_token != null) {
        await _registerToken(_token!);
      } else {
        await _fetchTokenAndRegister(FirebaseMessaging.instance);
      }
      return;
    }

    try {
      await Firebase.initializeApp();
      debugPrint('AIVA/FCM: Firebase initialized');
    } catch (e) {
      debugPrint('AIVA/FCM: Firebase not configured — push disabled ($e)');
      return;
    }
    _initialized = true;

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      debugPrint('AIVA/FCM: notification permission = '
          '${settings.authorizationStatus}');

      // Token fetch is isolated + retried: SERVICE_NOT_AVAILABLE is a common,
      // usually-transient FCM error and must NOT abort the listener setup below.
      await _fetchTokenAndRegister(messaging);

      messaging.onTokenRefresh.listen((t) {
        debugPrint('AIVA/FCM: token refreshed = $t');
        _token = t;
        _registerToken(t);
      });

      FirebaseMessaging.onMessage.listen(_onForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(_onOpened);
      final initial = await messaging.getInitialMessage();
      if (initial != null) _onOpened(initial);
    } catch (e) {
      debugPrint('AIVA/FCM: push setup failed ($e)');
    }
  }

  /// Fetch the FCM token with a few retries, then register it. FCM commonly
  /// throws `SERVICE_NOT_AVAILABLE` transiently (no network to Google's servers,
  /// Play Services warming up) and succeeds on a later attempt.
  Future<void> _fetchTokenAndRegister(FirebaseMessaging messaging) async {
    const attempts = 3;
    for (var i = 1; i <= attempts; i++) {
      try {
        _token = await messaging.getToken();
        if (_token != null) {
          debugPrint('AIVA/FCM: device token = $_token');
          await _registerToken(_token!);
          return;
        }
        debugPrint('AIVA/FCM: getToken() returned null (attempt $i/$attempts)');
      } catch (e) {
        debugPrint('AIVA/FCM: getToken() failed (attempt $i/$attempts): $e');
      }
      if (i < attempts) {
        await Future<void>.delayed(Duration(seconds: 2 * i));
      }
    }
    debugPrint('AIVA/FCM: could not obtain a token after $attempts attempts — '
        'will retry on next login/init. Check device internet + Google Play services.');
  }

  Future<void> unregister() async {
    final token = _token;
    if (token == null) return;
    try {
      await _api.dio.delete<dynamic>('/fcm/token', queryParameters: {'token': token});
    } catch (_) {
      // best effort
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      await _api.dio.post<dynamic>('/fcm/token', data: {'token': token});
      debugPrint('AIVA/FCM: token registered with backend OK');
    } catch (e) {
      // backend unreachable / not authed yet — will retry on next initAndRegister()
      debugPrint('AIVA/FCM: token registration FAILED ($e)');
    }
  }

  // A push arriving while the app is foregrounded.
  void _onForeground(RemoteMessage message) {
    debugPrint('AIVA/FCM: foreground push received '
        'data=${message.data} notif=${message.notification?.title}');
    notificationPing.value++; // refresh the in-app bell badge / feed
    if (_maybeIncomingCall(message)) return;
    final notification = message.notification;
    final title = notification?.title ?? 'AIVA';
    final body = notification?.body ?? '';
    AppToast.infoGlobal(body.isEmpty ? title : '$title: $body');
  }

  // The user tapped the notification (app was backgrounded/terminated).
  void _onOpened(RemoteMessage message) {
    notificationPing.value++;
    if (_maybeIncomingCall(message)) return;
    // Non-call notifications route to their target screen (reminders, mail, etc.).
    routeNotification(message.data);
  }

  /// If this is an 'incoming_call' push, open the in-app call screen directly
  /// (its 'incoming' phase rings with Accept/Decline, then WebRTC-connects on
  /// accept). We route straight to CallScreen rather than depending on the
  /// native CallKit UI, which doesn't reliably fire on every device. Returns
  /// true when handled so the caller skips the default toast/route.
  bool _maybeIncomingCall(RemoteMessage message) {
    final data = message.data;
    if (data['type'] != 'incoming_call') return false;
    _openCallScreen(data);
    return true;
  }

  void _openCallScreen(Map<String, dynamic> data) {
    final id = int.tryParse('${data['booking_request_id'] ?? ''}');
    if (id == null) return;
    final target = '${data['target'] ?? ''}'.trim();
    final caller = '${data['caller_name'] ?? ''}'.trim();
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    nav.push(
      fadeThroughRoute<void>(
        (_) => CallScreen(
          bookingRequestId: id,
          target: target.isEmpty ? 'the appointment' : target,
          callerName: caller.isEmpty ? null : caller,
          autoConnect: false, // show the in-app incoming UI; user taps Accept
        ),
      ),
    );
  }
}
