# app/ — repo structure (Flutter)

Single source of truth for the Flutter app file tree. **Update this whenever a file is
added/renamed/removed** (CLAUDE.md standing instruction #1). Each entry has a one-line summary.

Package id: `com.example.aiva` · project name: `aiva` · **Android-only** platform scaffolded
(no ios/web/desktop yet — add later with `flutter create --platforms=ios,web .` if needed).

Legend: ✅ generated/implemented · 🚧 placeholder (built in a later prompt; see prompt.md)

```
app/
├── pubspec.yaml                 ✅ Flutter manifest: deps, assets, SDK constraints
├── pubspec.lock                 ✅ Locked dependency versions
├── UI_GUIDE.md                  ✅ (P8) design-system reference: palette, type scale, tokens, widgets, "no hardcoded styles" rule
├── analysis_options.yaml        ✅ Dart analyzer/lint rules (flutter_lints)
├── README.md                    ✅ Default Flutter readme
├── .gitignore                   ✅ Flutter-generated gitignore
├── .metadata                    ✅ Flutter tooling metadata
├── aiva.iml                     ✅ IDE module file
├── repo_structure.md            ✅ This file
│
├── android/                     ✅ Android project; manifest has INTERNET + usesCleartextTraffic (dev); release lint disabled
├── assets/
│   └── images/
│       ├── aiva_logo.png         ✅ Robot-head brand logo (used on login screen + chat drawer header)
│       └── aiva_text.png         ✅ "AIVA" cursive wordmark (used on login screen + chat drawer header)
├── test/
│   └── widget_test.dart         ✅ Smoke test (auth status enum)
│
└── lib/
    ├── main.dart                ✅ AivaApp (MultiProvider AuthState+ThemeController → MaterialApp light/dark via themeMode, edge-to-edge) + _AuthGate (AnimatedSwitcher cross-fade → BrandedSplash/Login/authed); authed = MultiProvider(ChatState, MailConnectState) + _AuthedHome (app_links deep-link listener for aiva://mail-connected)
    ├── core/
    │   ├── config.dart          ✅ AppConfig.apiBaseUrl + voiceStreamBaseUrl (dart-define overrides)
    │   ├── app_keys.dart        ✅ Global scaffoldMessengerKey + navigatorKey + notificationPing (ValueNotifier bumped on each push → bell badge refresh)
    │   ├── theme/               ✅ Centralized design system (UI revamp Prompt 1) — screens MUST read from here, never hardcode
    │   │   ├── app_colors.dart       ✅ AppColors (brand+semantic+neutral palette) + light/dark ColorSchemes + AppPalette ThemeExtension + context.palette
    │   │   ├── app_typography.dart   ✅ AppTypography.textTheme(scheme) — Plus Jakarta Sans headings + Inter body (google_fonts)
    │   │   ├── app_spacing.dart      ✅ AppSpacing / AppRadii / AppMotion tokens (spacing, radii, durations+curves)
    │   │   ├── app_theme.dart        ✅ AppTheme.light/.dark — ThemeData + component themes + FadeThrough page transitions
    │   │   └── theme_controller.dart ✅ (P8) ThemeController — persists system/light/dark (secure storage); drives MaterialApp.themeMode
    │   ├── motion/              ✅ (UI revamp Prompt 2) shared navigation motion
    │   │   └── page_transitions.dart ✅ fadeThroughRoute() / sharedAxisRoute() — reduce-motion aware route builders (animations pkg)
    │   ├── util/
    │   │   └── time_format.dart      ✅ relativeTime(DateTime) — "just now / 5m ago / 3d ago / date" (chat + drawer)
    │   └── widgets/             ✅ Reusable presentational widgets
    │       ├── app_toast.dart        ✅ AppToast — semantic toasts (success/error/warning/info) as themed floating SnackBars; context + *Global variants (push/deep-link). ALL transient feedback goes through this
    │       ├── aiva_wordmark.dart    ✅ AivaWordmark — "AIVA" as real text (Plus Jakarta Sans w800, brand blue) replacing the old aiva_text.png; scales crisply (login/splash/chat appbar/drawer)
    │       ├── branded_splash.dart   ✅ BrandedSplash — pulsing logo loading screen for AuthStatus.unknown
    │       ├── gradient_background.dart ✅ (P3) themed gradient + blurred brand blobs backdrop (auth screens)
    │       ├── app_card.dart         ✅ (P6) AppCard — surface + hairline border + rounded, optional tap
    │       ├── status_chip.dart      ✅ (P6) StatusChip — semantic-colored pill (label + icon)
    │       ├── skeleton.dart         ✅ (P6/P7) SkeletonBox — shimmer loader (reduce-motion → static)
    │       ├── empty_state.dart      ✅ (P6) EmptyState — icon + title + message + optional action
    │       ├── section_header.dart   ✅ (P6) SectionHeader — small uppercase group label
    │       ├── stagger_in.dart       ✅ (P6) StaggerIn — interval fade+slide entrance (reduce-motion aware)
    │       └── chat_edit_tip.dart    ✅ ChatEditTip — subtle "ask AIVA in chat to change this" hint (reminders + appointments lists)
    ├── models/
    │   ├── user.dart            ✅ User model + fromJson (incl. timezone)
    │   ├── chat.dart            ✅ Chat model (+ displayTitle, date parsing)
    │   ├── message.dart         ✅ Message model (+ fromJson, Message.local for optimistic bubbles)
    │   ├── appointment.dart     ✅ Appointment model (booking_requests row: status, target, scheduled_call_at, outcome, + editable fields phone/contact/dob/insurance + callTriggeredAt; isEditable)
    │   ├── reminder.dart        ✅ Reminder model (id, content, dueAt(UTC), status) + fromJson
    │   └── app_notification.dart ✅ AppNotification model (id, type, title, body, data map, read, createdAt) — notification feed item
    ├── services/
    │   ├── token_storage.dart   ✅ JWT save/read/clear via flutter_secure_storage
    │   ├── api_client.dart      ✅ Dio + interceptor that attaches the Bearer token
    │   ├── auth_service.dart    ✅ signup/login/forgot/reset/me/logout; reportTimezone (device IANA tz → PUT /auth/timezone)
    │   ├── chat_service.dart    ✅ list/create chats, get messages, send message, uploadFile (multipart→/summarize/upload)
    │   ├── push_service.dart    ✅ FCM: token→/fcm/token (3x retry on SERVICE_NOT_AVAILABLE); foreground toast + bell ping; 'incoming_call' (fg + background isolate) → showIncomingCall (native CallKit ring); other taps route via routeNotification (reminder/mail/outcome→screens)
    │   ├── mail_service.dart    ✅ Gmail status/connect-url/update-watch/disconnect (+ MailStatus model)
    │   ├── appointment_service.dart ✅ GET /appointments (list) + PUT /appointments/{id} (edit) + DELETE /appointments/{id} (cancel pending)
    │   ├── reminder_service.dart    ✅ GET /reminders (list) + PUT /reminders/{id} (edit content/time, UTC) + DELETE /reminders/{id} (cancel)
    │   ├── notification_service.dart ✅ GET /notifications (feed + unread) + mark-read / mark-all-read / delete (NotificationFeed)
    │   ├── voice_service.dart   ✅ Voice chat: device speech-to-text (mic→text, partial+final) + flutter_tts (speak AIVA's reply); on-device, no API/key
    │   ├── call_service.dart    ✅ WebRTC client to VoiceStream: ICE → getUserMedia(audio) → /api/offer?request_id → answer; mute/speaker
    │   └── call_kit_service.dart ✅ Native incoming-call UI (flutter_callkit_incoming): ringtone+vibrate+full-screen even when killed/locked; listen() routes accept→CallScreen(autoConnect), decline/end→clear; handleColdStart() for lock-screen-accept relaunch
    └── features/
        ├── auth/
        │   ├── auth_state.dart             ✅ ChangeNotifier: status/user/error/loading; registers FCM on login, unregisters on logout
        │   ├── login_screen.dart           ✅ (redesigned P3) gradient backdrop, logo+wordmark, animated login↔signup toggle (name field collapse, label cross-fade), pill button, password reveal, keyboard-safe
        │   └── forgot_password_screen.dart ✅ (redesigned P3) same language; animated form↔success-card switch
        ├── chat/
        │   ├── chat_state.dart             ✅ ChangeNotifier: chats/currentChat/messages, optimistic send + attachAndSummarize
        │   ├── chat_drawer.dart            ✅ (P5) ChatDrawer — branded account header, searchable chat history, grouped footer (Notifications/Reminders/Mail/Appointments/Logout), staggered entrance on open
        │   └── chat_screen.dart            ✅ (redesigned P4) asymmetric bubbles + AIVA avatar, fade/slide message entrance, animated 3-dot typing, suggestion-chip empty state, jump-to-latest, rounded composer, animated dismissible Gmail banner, hairline app bar (wordmark) with NotificationBell; inline "Connect Gmail" button under assistant mail-intent messages while unconnected
        ├── notifications/
        │   ├── notifications_screen.dart   ✅ Notification center — feed of all pushes (newest first), unread dot, tap→mark-read+route, mark-all-read, pull-to-refresh, skeleton/empty
        │   ├── notification_bell.dart      ✅ NotificationBell — app-bar icon + unread Badge; refreshes on mount / notificationPing / after viewing the feed
        │   └── notification_routing.dart   ✅ routeNotification(data) — maps a notification's data payload → target screen (reminder→Reminders, mail→Mail highlight, outcome/call→Appointments); shared by push handler + feed
        ├── reminders/
        │   ├── reminders_screen.dart       ✅ Lists all reminders (pending-first), StatusChip + local due time + relative, Edit + cancel pending, skeleton/empty, pull-to-refresh
        │   └── reminder_edit_screen.dart   ✅ Edit a pending reminder: content + date/time picker (sends UTC); backend rejects past times
        ├── mail/
        │   ├── mail_connect_state.dart     ✅ ChangeNotifier: Gmail connected status + connect() (OAuth launch) + markConnected() (from deep link)
        │   └── mail_screen.dart            ✅ (redesigned P6) status hero, monitoring toggle, criteria, disconnect; + optional MailHighlight spotlight card (subject/sender + "Open in Gmail" deep-link via rfc822msgid) when opened from a mail notification
        └── appointments/
            ├── call_screen.dart            ✅ (redesigned P6) gradient backdrop, pulsing-ring avatar, big circular accept/decline (haptics), in-call toggles + elapsed timer, animated phase transitions; `autoConnect` skips the in-app incoming phase when accepted via native CallKit; clears the CallKit call on end/decline
            ├── appointment_edit_screen.dart ✅ Edit a pending+not-yet-called appointment: type dropdown, name/reason/phone/contact, who-where, date/time (UTC), conditional medical (DOB/insurance); backend enforces same rules
            └── appointments_screen.dart    ✅ (redesigned P6) card list + StatusChip + relative time, Edit (when editable) + cancel pending (haptic), pull-to-refresh, skeleton loaders, empty/error states, staggered cards
```

## Dependencies (pubspec.yaml)
- `dio` — HTTP client (+ auth interceptor) · `flutter_secure_storage` — token storage · `provider` — state mgmt.
- `file_picker` — pick files to summarize. **v11 API: `FilePicker.pickFiles(...)` (static, no `.platform`).**
  Forced `win32`→5.x / `flutter_secure_storage_windows`→4.1.0 (unused on Android; harmless).
- `firebase_core` + `firebase_messaging` — push. **Needs one-time Firebase setup (google-services.json +
  Gradle plugin) before push works — see CLAUDE.md. Until then push degrades silently; the rest runs.**
  Manifest adds `POST_NOTIFICATIONS` (Android 13+). Background/terminated pushes auto-display (we send a
  notification payload); foreground pushes show via a SnackBar.
- `google_fonts` — centralized typography (Plus Jakarta Sans headings + Inter body) in `core/theme/`.
  Fonts are fetched+cached at runtime on first use. **UI revamp Prompt 1 done:** the whole app now
  runs on `AppTheme` (light+dark, system mode, edge-to-edge); feature screens carry **no hardcoded
  colors** (all via `AppColors` / `ColorScheme` / `context.palette`). See `ui_improve.md` for Prompts 2–8.
- `animations` — Material motion. **UI revamp Prompt 2 done:** all route pushes go through
  `core/motion/page_transitions.dart` (fade-through / shared-axis, reduce-motion aware); the theme's default
  PageTransitionsBuilder is FadeThrough; `_AuthGate` cross-fades between splash/login/chat.
- `url_launcher` — opens the Gmail OAuth consent page in the external browser (connect flow).
- `app_links` — deep links. The OAuth web callback bounces the browser back via `aiva://mail-connected`
  (intent-filter in AndroidManifest). `main._AuthedHome` listens; on success it hides the chat's
  "Connect Gmail" banner and posts an AIVA confirmation bubble. A "Connect Gmail" banner now shows
  directly atop the chat (via `MailConnectState`) instead of being buried in the drawer.
- `flutter_webrtc` — in-app WebRTC voice call to the VoiceStream proxy caller (Feature 4). Manifest adds
  `RECORD_AUDIO` + `MODIFY_AUDIO_SETTINGS`; **Android `minSdk` raised to 23** (flutter_webrtc requirement, in
  `android/app/build.gradle.kts`). `AppConfig.voiceStreamBaseUrl` points at the VoiceStream server
  (default `https://callbot.duckdns.org`).
- `flutter_callkit_incoming` — native full-screen incoming-call UI (ringtone + vibration) that shows even when
  the app is killed or the screen is locked. The `incoming_call` push is sent **data-only + high priority** (see
  backend `notifications/fcm.py`) so the FCM background isolate runs and `services/call_kit_service.dart` raises
  the ring; accept → the in-app `CallScreen` (WebRTC). Manifest adds `USE_FULL_SCREEN_INTENT` (the plugin merges
  its own services/receivers + foreground/wake-lock perms).
- `flutter_timezone` — reads the device's IANA timezone (e.g. `Asia/Kolkata`). `AuthState._afterLogin`
  fire-and-forgets `AuthService.reportTimezone()` → `PUT /auth/timezone`, so the backend interprets clock
  times ("remind me at 2pm") in the user's local zone. (This build's `getLocalTimezone()` returns a `String`.)

## Notes
- Auth state machine: `unknown` (checking token) → `authenticated` | `unauthenticated`; `_AuthGate` picks the screen.
  Authenticated → `ChatScreen` wrapped in a scoped `ChangeNotifierProvider<ChatState>` (fresh per session).
- Chat send is optimistic (user bubble shown immediately, rolled back on error); a chat is auto-created on first send.
- Responses are non-streaming for now (typing indicator gives the live feel); `LLMProvider.stream` exists for later.
- Manifest allows cleartext HTTP for the dev backend — switch to HTTPS and remove for production.
- **Feature 4 call flow:** a booking is made in chat → at `scheduled_call_at` the worker sends a **data-only**
  high-priority FCM `incoming_call` → the app (foreground OR killed/locked, via the FCM background isolate) raises
  a **native full-screen ringing UI** (CallKit: ringtone + vibration). On Accept it opens `CallScreen` with
  `autoConnect` and WebRTC-connects to VoiceStream (`/api/offer?request_id=…`); the user plays the receptionist,
  the AIVA agent speaks as the caller. Decline/timeout clears the call. The outcome returns as a chat message + push.
- Run: `flutter run` · Analyze: `flutter analyze` (clean) · Test: `flutter test` (passing).
