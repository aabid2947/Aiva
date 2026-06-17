import 'package:flutter/material.dart';

/// Global messenger so non-widget code (push handler) can show SnackBars.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Global navigator so non-widget code (the push handler) can push routes —
/// e.g. open the full-screen call UI when an 'incoming_call' push arrives.
final navigatorKey = GlobalKey<NavigatorState>();

/// Bumped by the push handler whenever a notification arrives, so the
/// notification bell badge / feed can refresh without a global state object.
final notificationPing = ValueNotifier<int>(0);

/// Set with a chat id when a notification should open a specific chat (e.g. tapping
/// a 'summary_ready' push). The chat screen listens and opens that chat, then clears
/// it. Lives here so non-widget code (the push handler / notification routing) can
/// request it without a global state object.
final openChatRequest = ValueNotifier<String?>(null);

/// Set with an 'incoming_call' FCM data payload when the app is COLD-STARTED by
/// tapping a call notification (detected in main() before the UI builds). The auth
/// gate shows the CallScreen directly when this is set, so the user lands on the
/// pick-up screen instead of flashing through splash -> home -> call. Cleared when
/// the call ends. (Warm taps, where sub-routes may be open, push the CallScreen on
/// top instead — see PushService.)
final incomingCall = ValueNotifier<Map<String, dynamic>?>(null);
