import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/app_keys.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/widgets/app_toast.dart';
import 'core/widgets/branded_splash.dart';
import 'features/appointments/call_screen.dart';
import 'features/auth/auth_state.dart';
import 'features/auth/login_screen.dart';
import 'features/chat/chat_screen.dart';
import 'features/chat/chat_state.dart';
import 'features/mail/mail_connect_state.dart';
import 'features/notifications/notification_routing.dart';
import 'services/call_kit_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Edge-to-edge: content draws under the status/nav bars; bar icon colors are
  // driven per-screen by AppBarTheme.systemOverlayStyle.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  // Handle accept/decline from the native incoming-call UI (CallKit). Started
  // early so an "accept" that relaunched the app is caught once we're running.
  CallKitService.instance.listen();
  // If the app was COLD-STARTED by tapping a call notification, detect it now —
  // concurrently with auth bootstrap — so the auth gate can show the CallScreen
  // directly instead of flashing splash -> home -> (seconds later) the call.
  _preloadInitialCall();
  runApp(const AivaApp());
}

/// Fast path for a cold start from a call notification: init Firebase and read
/// the launch message immediately (no waiting on token registration), so the
/// pick-up screen is the FIRST authed screen. Fire-and-forget; failures (push
/// not configured / no launch message) just leave `incomingCall` null.
Future<void> _preloadInitialCall() async {
  try {
    await Firebase.initializeApp();
    final message = await FirebaseMessaging.instance.getInitialMessage();
    final data = message?.data;
    if (data == null) return;
    if (data['type'] == 'incoming_call') {
      incomingCall.value = Map<String, dynamic>.from(data); // -> CallScreen directly
    } else {
      // A non-call notification cold-started the app (reminder, mail, …). Route it
      // once the authed home is up. (This is the single getInitialMessage read — the
      // push handler no longer reads it, so there's no double handling.)
      _coldStartRoute = Map<String, dynamic>.from(data);
    }
  } catch (_) {
    // No Firebase / no launch message — normal start.
  }
}

/// A non-call notification payload that cold-started the app, consumed by the
/// authed home's first frame to deep-link to the right screen.
Map<String, dynamic>? _coldStartRoute;

class AivaApp extends StatelessWidget {
  const AivaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthState>(create: (_) => AuthState()..bootstrap()),
        ChangeNotifierProvider<ThemeController>(create: (_) => ThemeController()..load()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) => MaterialApp(
          title: 'AIVA',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          scaffoldMessengerKey: scaffoldMessengerKey,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeController.mode,
          home: const _AuthGate(),
        ),
      ),
    );
  }
}

/// Route guard: shows login, home, or a loading spinner based on auth status.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthState>().status;
    return AnimatedSwitcher(
      duration: AppMotion.base,
      switchInCurve: AppMotion.standard,
      switchOutCurve: AppMotion.standard,
      child: KeyedSubtree(
        key: ValueKey(status),
        child: _screenFor(status),
      ),
    );
  }

  Widget _screenFor(AuthStatus status) {
    switch (status) {
      case AuthStatus.unknown:
        return const BrandedSplash();
      case AuthStatus.authenticated:
        // A call-notification cold start lands straight on the pick-up screen
        // (no home flash). When the call ends, `incomingCall` clears and the
        // normal home builds.
        return ValueListenableBuilder<Map<String, dynamic>?>(
          valueListenable: incomingCall,
          builder: (context, call, _) {
            if (call != null) return _IncomingCallHost(data: call);
            return MultiProvider(
              providers: [
                ChangeNotifierProvider<ChatState>(create: (_) => ChatState()..loadChats()),
                ChangeNotifierProvider<MailConnectState>(
                  create: (_) => MailConnectState()..refresh(),
                ),
              ],
              child: const _AuthedHome(),
            );
          },
        );
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}

/// Authenticated home: hosts the chat UI and listens for the OAuth deep link
/// (aiva://mail-connected) so the Gmail flow returns into the app.
class _AuthedHome extends StatefulWidget {
  const _AuthedHome();

  @override
  State<_AuthedHome> createState() => _AuthedHomeState();
}

class _AuthedHomeState extends State<_AuthedHome> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = _appLinks.uriLinkStream.listen(_onDeepLink);
    // Handle the case where the deep link cold-started the app.
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _onDeepLink(uri);
    });
    // If the app was relaunched by accepting a call from the lock screen, the
    // call is already active — route into it once the first frame is up.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CallKitService.instance.handleColdStart();
      // Deep-link a non-call notification that cold-started the app (reminder, mail…).
      final route = _coldStartRoute;
      if (route != null) {
        _coldStartRoute = null;
        routeNotification(route);
      }
    });
  }

  void _onDeepLink(Uri uri) {
    if (uri.scheme != 'aiva' || uri.host != 'mail-connected' || !mounted) return;
    if (uri.queryParameters['status'] == 'success') {
      context.read<MailConnectState>().markConnected();
      context.read<ChatState>().announceGmailConnected();
      AppToast.successGlobal('Gmail connected.');
    } else {
      AppToast.errorGlobal('Could not connect Gmail. Please try again.');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const ChatScreen();
}

/// Full-screen pick-up UI for a call that cold-started the app. Parses the FCM
/// data payload and clears [incomingCall] when the call ends, returning to home.
class _IncomingCallHost extends StatelessWidget {
  const _IncomingCallHost({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final id = int.tryParse('${data['booking_request_id'] ?? ''}');
    if (id == null) {
      // Malformed payload — fall back to home on the next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => incomingCall.value = null);
      return const SizedBox.shrink();
    }
    final target = '${data['target'] ?? ''}'.trim();
    final caller = '${data['caller_name'] ?? ''}'.trim();
    return CallScreen(
      bookingRequestId: id,
      target: target.isEmpty ? 'the appointment' : target,
      callerName: caller.isEmpty ? null : caller,
      autoConnect: false,
      onEnd: () => incomingCall.value = null,
    );
  }
}
