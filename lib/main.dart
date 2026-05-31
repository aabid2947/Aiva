import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_keys.dart';
import 'features/auth/auth_state.dart';
import 'features/auth/login_screen.dart';
import 'features/chat/chat_screen.dart';
import 'features/chat/chat_state.dart';

void main() {
  runApp(const AivaApp());
}

class AivaApp extends StatelessWidget {
  const AivaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthState>(
      create: (_) => AuthState()..bootstrap(),
      child: MaterialApp(
        title: 'AIVA',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: scaffoldMessengerKey,
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const _AuthGate(),
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
    switch (status) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.authenticated:
        return ChangeNotifierProvider<ChatState>(
          create: (_) => ChatState()..loadChats(),
          child: const ChatScreen(),
        );
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
