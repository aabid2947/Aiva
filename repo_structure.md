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
├── analysis_options.yaml        ✅ Dart analyzer/lint rules (flutter_lints)
├── README.md                    ✅ Default Flutter readme
├── .gitignore                   ✅ Flutter-generated gitignore
├── .metadata                    ✅ Flutter tooling metadata
├── aiva.iml                     ✅ IDE module file
├── repo_structure.md            ✅ This file
│
├── android/                     ✅ Android project; manifest has INTERNET + usesCleartextTraffic (dev)
├── test/
│   └── widget_test.dart         ✅ Smoke test (auth status enum)
│
└── lib/
    ├── main.dart                ✅ AivaApp + ChangeNotifierProvider + _AuthGate route guard + scaffoldMessengerKey
    ├── core/
    │   ├── config.dart          ✅ AppConfig.apiBaseUrl (default http://10.0.2.2:8000; dart-define override)
    │   └── app_keys.dart        ✅ Global scaffoldMessengerKey (push SnackBars from non-widget code)
    ├── models/
    │   ├── user.dart            ✅ User model + fromJson
    │   ├── chat.dart            ✅ Chat model (+ displayTitle, date parsing)
    │   └── message.dart         ✅ Message model (+ fromJson, Message.local for optimistic bubbles)
    ├── services/
    │   ├── token_storage.dart   ✅ JWT save/read/clear via flutter_secure_storage
    │   ├── api_client.dart      ✅ Dio + interceptor that attaches the Bearer token
    │   ├── auth_service.dart    ✅ signup/login/forgot/reset/me/logout against backend
    │   ├── chat_service.dart    ✅ list/create chats, get messages, send message, uploadFile (multipart→/summarize/upload)
    │   ├── push_service.dart    ✅ FCM: init/permission/token→/fcm/token, foreground SnackBar; degrades if Firebase unconfigured
    │   └── mail_service.dart    ✅ Gmail status/connect-url/update-watch/disconnect (+ MailStatus model)
    └── features/
        ├── auth/
        │   ├── auth_state.dart             ✅ ChangeNotifier: status/user/error/loading; registers FCM on login, unregisters on logout
        │   ├── login_screen.dart           ✅ Login/Signup toggle form, validation, loading/errors
        │   └── forgot_password_screen.dart ✅ Email → reset-link request + confirmation
        ├── chat/
        │   ├── chat_state.dart             ✅ ChangeNotifier: chats/currentChat/messages, optimistic send + attachAndSummarize
        │   └── chat_screen.dart            ✅ Bubbles, composer (attach + send), typing/upload indicator, drawer (chats + Mail + logout)
        └── mail/
            └── mail_screen.dart            ✅ Connect Gmail (url_launcher), toggle monitoring, set importance criteria, disconnect
```

## Dependencies (pubspec.yaml)
- `dio` — HTTP client (+ auth interceptor) · `flutter_secure_storage` — token storage · `provider` — state mgmt.
- `file_picker` — pick files to summarize. **v11 API: `FilePicker.pickFiles(...)` (static, no `.platform`).**
  Forced `win32`→5.x / `flutter_secure_storage_windows`→4.1.0 (unused on Android; harmless).
- `firebase_core` + `firebase_messaging` — push. **Needs one-time Firebase setup (google-services.json +
  Gradle plugin) before push works — see CLAUDE.md. Until then push degrades silently; the rest runs.**
  Manifest adds `POST_NOTIFICATIONS` (Android 13+). Background/terminated pushes auto-display (we send a
  notification payload); foreground pushes show via a SnackBar.
- `url_launcher` — opens the Gmail OAuth consent page in the external browser (connect flow).

## Notes
- Auth state machine: `unknown` (checking token) → `authenticated` | `unauthenticated`; `_AuthGate` picks the screen.
  Authenticated → `ChatScreen` wrapped in a scoped `ChangeNotifierProvider<ChatState>` (fresh per session).
- Chat send is optimistic (user bubble shown immediately, rolled back on error); a chat is auto-created on first send.
- Responses are non-streaming for now (typing indicator gives the live feel); `LLMProvider.stream` exists for later.
- Manifest allows cleartext HTTP for the dev backend — switch to HTTPS and remove for production.
- Run: `flutter run` · Analyze: `flutter analyze` (clean) · Test: `flutter test` (passing).
