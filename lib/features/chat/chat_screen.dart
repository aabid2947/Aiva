import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/util/time_format.dart';
import '../../core/widgets/aiva_wordmark.dart';
import '../../core/widgets/app_toast.dart';
import '../../models/message.dart';
import '../../services/voice_service.dart';
import '../mail/mail_connect_state.dart';
import '../notifications/notification_bell.dart';
import 'chat_drawer.dart';
import 'chat_state.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  final _drawerOpenTick = ValueNotifier<int>(0);
  final _voice = VoiceService();
  bool _showJump = false;
  bool _bannerDismissed = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    _drawerOpenTick.dispose();
    _voice.dispose();
    super.dispose();
  }

  void _onScroll() {
    // reverse:true list → offset grows as you scroll up away from newest.
    final show = _scrollController.hasClients && _scrollController.offset > 240;
    if (show != _showJump) setState(() => _showJump = show);
  }

  void _jumpToLatest() {
    _scrollController.animateTo(0,
        duration: AppMotion.base, curve: AppMotion.standard);
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    _controller.clear();
    context.read<ChatState>().sendMessage(text);
  }

  /// Voice-initiated send: same as _send, but speaks AIVA's reply back.
  Future<void> _sendVoice() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    _controller.clear();
    final reply = await context.read<ChatState>().sendMessage(text);
    if (mounted && reply != null && reply.isNotEmpty) {
      await _voice.speak(reply);
    }
  }

  void _prefill(String text) {
    _controller
      ..text = text
      ..selection = TextSelection.collapsed(offset: text.length);
    _focusNode.requestFocus();
  }

  Future<void> _attach() async {
    final result = await FilePicker.pickFiles(withData: true);
    if (!mounted || result == null || result.files.isEmpty) return;
    final picked = result.files.single;
    final bytes = picked.bytes;
    if (bytes == null) {
      AppToast.error(context, "Couldn't read that file.");
      return;
    }
    context.read<ChatState>().attachAndSummarize(bytes, picked.name);
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatState>();
    return Scaffold(
      appBar: AppBar(
        title: chat.currentChat != null
            ? Text(chat.currentChat!.displayTitle,
                maxLines: 1, overflow: TextOverflow.ellipsis)
            : const AivaWordmark(fontSize: 20),
        actions: const [NotificationBell()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: context.palette.hairline),
        ),
      ),
      onDrawerChanged: (open) {
        if (open) _drawerOpenTick.value++;
      },
      drawer: ChatDrawer(openSignal: _drawerOpenTick),
      body: Column(
        children: [
          _GmailConnectBanner(
            dismissed: _bannerDismissed,
            onDismiss: () => setState(() => _bannerDismissed = true),
          ),
          AnimatedSize(
            duration: AppMotion.base,
            curve: AppMotion.standard,
            child: chat.error == null
                ? const SizedBox(width: double.infinity)
                : _ErrorBanner(
                    message: chat.error!,
                    onDismiss: () => context.read<ChatState>().clearError(),
                  ),
          ),
          Expanded(
            child: Stack(
              children: [
                _MessageList(
                  chat: chat,
                  scrollController: _scrollController,
                  onSuggest: _handleSuggestion,
                ),
                Positioned(
                  right: AppSpacing.lg,
                  bottom: AppSpacing.md,
                  child: _JumpToLatest(
                    visible: _showJump,
                    onTap: _jumpToLatest,
                  ),
                ),
              ],
            ),
          ),
          _Composer(
            controller: _controller,
            focusNode: _focusNode,
            onSend: _send,
            onSendVoice: _sendVoice,
            onAttach: _attach,
            voice: _voice,
            busy: chat.busy,
            uploading: chat.uploading,
          ),
        ],
      ),
    );
  }

  void _handleSuggestion(_Suggestion s) {
    switch (s) {
      case _Suggestion.summarize:
        _attach();
      case _Suggestion.remind:
        _prefill('Remind me to ');
      case _Suggestion.mail:
        _prefill('Watch my email for important mail');
      case _Suggestion.appointment:
        _prefill('Book an appointment ');
    }
  }
}

// ---------------------------------------------------------------------------
// Message list
// ---------------------------------------------------------------------------
class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.chat,
    required this.scrollController,
    required this.onSuggest,
  });

  final ChatState chat;
  final ScrollController scrollController;
  final ValueChanged<_Suggestion> onSuggest;

  @override
  Widget build(BuildContext context) {
    if (chat.loadingMessages) {
      return const Center(child: CircularProgressIndicator());
    }
    if (chat.messages.isEmpty && !chat.busy) {
      return _EmptyState(onSuggest: onSuggest);
    }

    final msgs = chat.messages;
    // Build in natural order so we can look back for "first of a run", then
    // reverse the widget list for the reverse:true ListView (newest at bottom).
    final items = <Widget>[];
    for (var i = 0; i < msgs.length; i++) {
      final m = msgs[i];
      final prev = i > 0 ? msgs[i - 1] : null;
      final firstOfRun = prev == null || prev.role != m.role;
      items.add(_FadeSlideIn(
        key: ValueKey('${m.role}-${m.id}-$i'),
        child: _Bubble(message: m, showAvatar: !m.isUser && firstOfRun),
      ));
    }
    if (chat.busy) {
      items.add(const _FadeSlideIn(key: ValueKey('typing'), child: _TypingBubble()));
    }

    final reversed = items.reversed.toList();
    return ListView.builder(
      controller: scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      itemCount: reversed.length,
      itemBuilder: (_, i) => reversed[i],
    );
  }
}

/// One-shot fade + slide-up entrance for a newly inserted message.
class _FadeSlideIn extends StatefulWidget {
  const _FadeSlideIn({super.key, required this.child});
  final Widget child;

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.base,
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: AppMotion.standard);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(curved),
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bubble
// ---------------------------------------------------------------------------
class _Bubble extends StatefulWidget {
  const _Bubble({required this.message, required this.showAvatar});

  final Message message;
  final bool showAvatar;

  @override
  State<_Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<_Bubble> {
  bool _showTime = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    final m = widget.message;
    final isUser = m.isUser;

    // When AIVA replies about mail but Gmail isn't connected yet, offer the
    // connect action right here in the chat instead of pointing at a menu.
    final isMailIntent = !isUser && m.intent == 'mail';
    final showConnectMail =
        isMailIntent && context.watch<MailConnectState>().needsConnect;

    final bubbleColor = isUser ? palette.userBubble : palette.aivaBubble;
    final textColor = isUser ? palette.onUserBubble : palette.onAivaBubble;
    final radius = Radius.circular(AppRadii.xl);
    final squared = const Radius.circular(AppRadii.sm);

    final bubble = GestureDetector(
      onTap: () => setState(() => _showTime = !_showTime),
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: m.content));
        HapticFeedback.selectionClick();
        AppToast.success(context, 'Copied to clipboard');
      },
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: radius,
            topRight: radius,
            bottomLeft: isUser ? radius : squared,
            bottomRight: isUser ? squared : radius,
          ),
        ),
        child: _MessageText(
          content: m.content,
          style: theme.textTheme.bodyLarge!.copyWith(color: textColor),
        ),
      ),
    );

    final time = m.createdAt;
    final timeLabel = (_showTime && time != null)
        ? Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs, left: 4, right: 4),
            child: Text(relativeTime(time), style: theme.textTheme.labelSmall),
          )
        : const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                _AivaAvatar(visible: widget.showAvatar),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(child: bubble),
            ],
          ),
          if (showConnectMail)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm, left: 40),
              child: const _ConnectMailButton(),
            ),
          AnimatedSize(
            duration: AppMotion.fast,
            child: Padding(
              padding: EdgeInsets.only(left: isUser ? 0 : 40),
              child: timeLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _AivaAvatar extends StatelessWidget {
  const _AivaAvatar({required this.visible});
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox(width: 32);
    return CircleAvatar(
      radius: 16,
      backgroundColor: context.palette.aivaBubble,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Image.asset('assets/images/aiva_logo.png'),
      ),
    );
  }
}

/// Inline call-to-action shown under a mail reply when Gmail isn't connected,
/// so the user can start the OAuth flow straight from the chat.
class _ConnectMailButton extends StatelessWidget {
  const _ConnectMailButton();

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () async {
        HapticFeedback.lightImpact();
        final ok = await context.read<MailConnectState>().connect();
        if (!ok) AppToast.errorGlobal("Couldn't open the browser.");
      },
      icon: const Icon(Icons.mark_email_unread_outlined, size: 18),
      label: const Text('Connect Gmail'),
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      ),
    );
  }
}

/// Lightweight formatting: paragraphs + "- "/"* "/"• " bullets. No heavy markdown.
class _MessageText extends StatelessWidget {
  const _MessageText({required this.content, required this.style});

  final String content;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    final lines = content.split('\n');
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('- ') ||
          trimmed.startsWith('* ') ||
          trimmed.startsWith('• ')) {
        spans.add(TextSpan(text: '•  ${trimmed.substring(2)}'));
      } else {
        spans.add(TextSpan(text: line));
      }
      if (i != lines.length - 1) spans.add(const TextSpan(text: '\n'));
    }
    return SelectableText.rich(
      TextSpan(style: style, children: spans),
    );
  }
}

// ---------------------------------------------------------------------------
// Typing indicator
// ---------------------------------------------------------------------------
class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Row(
        children: [
          _AivaAvatar(visible: true),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md + 2),
            decoration: BoxDecoration(
              color: palette.aivaBubble,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadii.xl),
                topRight: Radius.circular(AppRadii.xl),
                bottomRight: Radius.circular(AppRadii.xl),
                bottomLeft: Radius.circular(AppRadii.sm),
              ),
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.palette.muted;
    return SizedBox(
      width: 36,
      height: 10,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (i) {
              final t = (_c.value + i * 0.2) % 1.0;
              final opacity = 0.3 + 0.7 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
              return Opacity(
                opacity: opacity,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state + suggestions
// ---------------------------------------------------------------------------
enum _Suggestion { summarize, remind, mail, appointment }

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onSuggest});
  final ValueChanged<_Suggestion> onSuggest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/aiva_logo.png', height: 72),
            const SizedBox(height: AppSpacing.lg),
            Text('How can I help?',
                style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Summarize a file, set a reminder, watch your inbox for important mail, '
              'or book an appointment by phone.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _SuggestionChip(
                  icon: Icons.description_outlined,
                  label: 'Summarize a file',
                  onTap: () => onSuggest(_Suggestion.summarize),
                ),
                _SuggestionChip(
                  icon: Icons.alarm_outlined,
                  label: 'Remind me…',
                  onTap: () => onSuggest(_Suggestion.remind),
                ),
                _SuggestionChip(
                  icon: Icons.mark_email_unread_outlined,
                  label: 'Watch my email',
                  onTap: () => onSuggest(_Suggestion.mail),
                ),
                _SuggestionChip(
                  icon: Icons.event_outlined,
                  label: 'Book an appointment',
                  onTap: () => onSuggest(_Suggestion.appointment),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

// ---------------------------------------------------------------------------
// Jump to latest
// ---------------------------------------------------------------------------
class _JumpToLatest extends StatelessWidget {
  const _JumpToLatest({required this.visible, required this.onTap});
  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: visible ? 1 : 0,
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      child: FloatingActionButton.small(
        heroTag: 'jumpToLatest',
        tooltip: 'Jump to latest',
        onPressed: onTap,
        child: const Icon(Icons.keyboard_arrow_down),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Composer
// ---------------------------------------------------------------------------
class _Composer extends StatefulWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onSendVoice,
    required this.onAttach,
    required this.voice,
    required this.busy,
    required this.uploading,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onSendVoice;
  final VoidCallback onAttach;
  final VoiceService voice;
  final bool busy;
  final bool uploading;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  bool _hasText = false;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    if (_listening) widget.voice.stopListening();
    super.dispose();
  }

  void _onChanged() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  // ----- voice input -----
  void _onMicPressed() {
    if (_listening) {
      _endMic(send: true); // tap again = stop & send what was heard
    } else {
      _startMic();
    }
  }

  Future<void> _startMic() async {
    widget.voice.onStatus = (status) {
      // The recognizer stopped on its own (silence) → send what we have.
      if (mounted && (status == 'notListening' || status == 'done')) {
        _endMic(send: true);
      }
    };
    widget.voice.onError = (_) {
      if (!mounted) return;
      _endMic(send: false);
      AppToast.warning(context, "Didn't catch that — try again.");
    };

    final ok = await widget.voice.startListening(
      onResult: (text, isFinal) {
        if (!mounted) return;
        widget.controller
          ..text = text
          ..selection = TextSelection.collapsed(offset: text.length);
        if (isFinal) _endMic(send: true);
      },
    );
    if (!mounted) return;
    if (!ok) {
      AppToast.error(context, 'Microphone not available. Enable the mic permission.');
      return;
    }
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus(); // hide the keyboard while talking
    setState(() => _listening = true);
  }

  void _endMic({required bool send}) {
    if (!_listening) return; // guard against double-fire (final result + status)
    setState(() => _listening = false);
    widget.voice.stopListening();
    if (send && widget.controller.text.trim().isNotEmpty) {
      widget.onSendVoice();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final canSend = _hasText && !widget.busy;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.uploading)
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: AppRadii.rXl,
                border: Border.all(color: palette.hairline),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'Attach a file to summarize',
                    onPressed: widget.busy ? null : widget.onAttach,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      minLines: 1,
                      maxLines: 5,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: _listening ? 'Listening…' : 'Message AIVA…',
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      ),
                    ),
                  ),
                  // Voice input: tap to speak, tap again (or pause) to send.
                  IconButton(
                    tooltip: _listening ? 'Stop' : 'Speak',
                    onPressed: (widget.busy && !_listening) ? null : _onMicPressed,
                    icon: Icon(
                      _listening ? Icons.stop_circle_rounded : Icons.mic_none_rounded,
                      color: _listening ? theme.colorScheme.error : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: AnimatedScale(
                      scale: canSend ? 1 : 0.85,
                      duration: AppMotion.fast,
                      curve: AppMotion.standard,
                      child: IconButton.filled(
                        tooltip: 'Send',
                        onPressed: canSend ? widget.onSend : null,
                        icon: widget.busy && !widget.uploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.arrow_upward),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gmail connect banner
// ---------------------------------------------------------------------------

/// A friendly, dismissible error banner that also auto-dismisses after a few
/// seconds so it never gets stuck on screen. (P11)
class _ErrorBanner extends StatefulWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  State<_ErrorBanner> createState() => _ErrorBannerState();
}

class _ErrorBannerState extends State<_ErrorBanner> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didUpdateWidget(_ErrorBanner old) {
    super.didUpdateWidget(old);
    if (old.message != widget.message) _arm(); // new error → restart the countdown
  }

  void _arm() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 6), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: AppRadii.rLg,
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 20, color: scheme.onErrorContainer),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                widget.message,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.onErrorContainer),
              ),
            ),
            IconButton(
              tooltip: 'Dismiss',
              visualDensity: VisualDensity.compact,
              onPressed: widget.onDismiss,
              icon: Icon(Icons.close, size: 18, color: scheme.onErrorContainer),
            ),
          ],
        ),
      ),
    );
  }
}

class _GmailConnectBanner extends StatelessWidget {
  const _GmailConnectBanner({required this.dismissed, required this.onDismiss});

  final bool dismissed;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final mail = context.watch<MailConnectState>();
    final show = mail.needsConnect && !dismissed;
    final theme = Theme.of(context);

    return AnimatedSize(
      duration: AppMotion.base,
      curve: AppMotion.standard,
      child: !show
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: AppRadii.rLg,
                ),
                child: Row(
                  children: [
                    Icon(Icons.mark_email_unread_outlined,
                        color: theme.colorScheme.onSecondaryContainer),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Connect Gmail so AIVA can alert you about important mail.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton(
                      onPressed: () async {
                        final ok = await context.read<MailConnectState>().connect();
                        if (!ok) {
                          AppToast.errorGlobal("Couldn't open the browser.");
                        }
                      },
                      style: FilledButton.styleFrom(
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                      ),
                      child: const Text('Connect'),
                    ),
                    IconButton(
                      tooltip: 'Dismiss',
                      visualDensity: VisualDensity.compact,
                      onPressed: onDismiss,
                      icon: Icon(Icons.close,
                          color: theme.colorScheme.onSecondaryContainer),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

