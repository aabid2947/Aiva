import '../../core/app_keys.dart';
import '../../core/motion/page_transitions.dart';
import '../appointments/appointments_screen.dart';
import '../mail/mail_screen.dart';
import '../reminders/reminders_screen.dart';

/// Routes a notification (by its `data` payload) to the right screen. Shared by
/// the push handler (tap on a system notification) and the in-app notification
/// feed (tap on a row). Uses the global navigator so it works from non-widget code.
///
/// `incoming_call` is handled separately by PushService (it opens the live call
/// UI); from the feed an old call simply lands on the appointments list.
void routeNotification(Map<String, dynamic> data) {
  final nav = navigatorKey.currentState;
  if (nav == null) return;
  final type = data['type'] as String?;

  switch (type) {
    case 'reminder':
      nav.push(sharedAxisRoute<void>((_) => const RemindersScreen()));
    case 'mail':
      nav.push(sharedAxisRoute<void>(
          (_) => MailScreen(highlight: MailHighlight.fromData(data))));
    case 'mail_reauth':
      nav.push(sharedAxisRoute<void>((_) => const MailScreen()));
    case 'appointment_outcome':
    case 'incoming_call':
      nav.push(sharedAxisRoute<void>((_) => const AppointmentsScreen()));
    case 'summary_ready':
      // The summary lives in a chat — drop any open sub-routes so the chat home is
      // visible, then ask it to open the specific chat (the chat screen listens).
      final chatId = data['chat_id'] as String?;
      if (chatId != null && chatId.isNotEmpty) {
        nav.popUntil((r) => r.isFirst);
        openChatRequest.value = chatId;
      }
    default:
      break;
  }
}
