import 'package:flutter/material.dart';

/// Global messenger so non-widget code (push handler) can show SnackBars.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Global navigator so non-widget code (the push handler) can push routes —
/// e.g. open the full-screen call UI when an 'incoming_call' push arrives.
final navigatorKey = GlobalKey<NavigatorState>();

/// Bumped by the push handler whenever a notification arrives, so the
/// notification bell badge / feed can refresh without a global state object.
final notificationPing = ValueNotifier<int>(0);
