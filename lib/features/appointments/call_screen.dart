import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../services/call_service.dart';

/// Full-screen, phone-call-style UI for the in-app proxy call.
///
/// Reached when an FCM `incoming_call` data message arrives (foreground) or the
/// user taps the call notification (background). The AIVA agent (on the
/// VoiceStream server) speaks AS the user; the user plays the receptionist.
class CallScreen extends StatefulWidget {
  const CallScreen({
    super.key,
    required this.bookingRequestId,
    required this.target,
    this.callerName,
    this.autoConnect = false,
  });

  final int bookingRequestId;
  final String target;
  final String? callerName;

  /// When true the call was already accepted on the native CallKit UI, so we
  /// skip the in-app "incoming" phase and connect straight away.
  final bool autoConnect;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

enum _Phase { incoming, connecting, inCall, error }

class _CallScreenState extends State<CallScreen>
    with SingleTickerProviderStateMixin {
  final CallService _call = CallService();
  _Phase _phase = _Phase.incoming;
  String? _error;
  bool _muted = false;
  bool _speaker = true;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void initState() {
    super.initState();
    if (widget.autoConnect) {
      _phase = _Phase.connecting;
      WidgetsBinding.instance.addPostFrameCallback((_) => _accept());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    _call.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    HapticFeedback.mediumImpact();
    setState(() => _phase = _Phase.connecting);
    try {
      await _call.connect(widget.bookingRequestId);
      await _call.setSpeaker(_speaker);
      if (!mounted) return;
      setState(() => _phase = _Phase.inCall);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _error = '$e';
      });
    }
  }

  Future<void> _hangUp() async {
    HapticFeedback.mediumImpact();
    _timer?.cancel();
    await _call.dispose();
    await _clearNativeCall();
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _decline() async {
    HapticFeedback.mediumImpact();
    await _clearNativeCall();
    if (mounted) Navigator.of(context).maybePop();
  }

  /// Clear any lingering CallKit ongoing-call notification for this booking.
  Future<void> _clearNativeCall() async {
    try {
      await FlutterCallkitIncoming.endCall('${widget.bookingRequestId}');
    } catch (_) {
      // best effort
    }
  }

  Future<void> _toggleMute() async {
    HapticFeedback.selectionClick();
    setState(() => _muted = !_muted);
    await _call.setMuted(_muted);
  }

  Future<void> _toggleSpeaker() async {
    HapticFeedback.selectionClick();
    setState(() => _speaker = !_speaker);
    await _call.setSpeaker(_speaker);
  }

  String get _statusText {
    switch (_phase) {
      case _Phase.incoming:
        return 'AIVA wants to call on your behalf';
      case _Phase.connecting:
        return 'Connecting…';
      case _Phase.inCall:
        return _fmt(_elapsed);
      case _Phase.error:
        return _error ?? 'Call failed';
    }
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ringing = _phase == _Phase.incoming || _phase == _Phase.connecting;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.callBackdrop, AppColors.callBackdropDeep],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                _PulsingAvatar(pulse: _pulse, active: ringing),
                const SizedBox(height: AppSpacing.xxl),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Text(
                    widget.target,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(color: AppColors.callOn),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AnimatedSwitcher(
                  duration: AppMotion.base,
                  child: Text(
                    _statusText,
                    key: ValueKey(_statusText),
                    textAlign: TextAlign.center,
                    style: (_phase == _Phase.inCall
                            ? theme.textTheme.headlineSmall
                            : theme.textTheme.titleMedium)
                        ?.copyWith(
                      color: _phase == _Phase.error
                          ? AppColors.callDangerSoft
                          : AppColors.callOnFaint,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                AnimatedSwitcher(
                  duration: AppMotion.base,
                  child: _controls(),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _controls() {
    switch (_phase) {
      case _Phase.incoming:
        return Row(
          key: const ValueKey('incoming'),
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _CallButton(
                icon: Icons.call_end,
                color: AppColors.danger,
                label: 'Decline',
                onTap: _decline),
            _CallButton(
                icon: Icons.call,
                color: AppColors.success,
                label: 'Accept',
                onTap: _accept),
          ],
        );
      case _Phase.connecting:
        return const SizedBox(
          key: ValueKey('connecting'),
          height: 64,
          width: 64,
          child: CircularProgressIndicator(color: AppColors.callOn),
        );
      case _Phase.inCall:
        return Column(
          key: const ValueKey('inCall'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ToggleButton(
                  icon: _muted ? Icons.mic_off : Icons.mic,
                  label: _muted ? 'Unmute' : 'Mute',
                  active: _muted,
                  onTap: _toggleMute,
                ),
                const SizedBox(width: AppSpacing.xxl),
                _ToggleButton(
                  icon: _speaker ? Icons.volume_up : Icons.hearing,
                  label: _speaker ? 'Speaker' : 'Earpiece',
                  active: _speaker,
                  onTap: _toggleSpeaker,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _CallButton(
                icon: Icons.call_end,
                color: AppColors.danger,
                label: 'End',
                onTap: _hangUp),
          ],
        );
      case _Phase.error:
        return _CallButton(
          key: const ValueKey('error'),
          icon: Icons.close,
          color: AppColors.callControl,
          label: 'Close',
          onTap: _decline,
        );
    }
  }
}

class _PulsingAvatar extends StatelessWidget {
  const _PulsingAvatar({required this.pulse, required this.active});

  final AnimationController pulse;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              if (active)
                for (final i in [0, 1])
                  _ring((pulse.value + i * 0.5) % 1.0),
              child!,
            ],
          );
        },
        child: Container(
          width: 104,
          height: 104,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: const BoxDecoration(
            color: AppColors.callControl,
            shape: BoxShape.circle,
          ),
          child: Image.asset('assets/images/aiva_logo.png'),
        ),
      ),
    );
  }

  Widget _ring(double t) {
    final size = 104 + t * 76;
    return Opacity(
      opacity: (1 - t) * 0.35,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.brandBlueSoft, width: 2),
        ),
      ),
    );
  }
}

/// Big circular primary call action (accept / decline / end).
class _CallButton extends StatelessWidget {
  const _CallButton({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Icon(icon, color: AppColors.callOn, size: 30),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(label, style: const TextStyle(color: AppColors.callOnMuted)),
      ],
    );
  }
}

/// In-call toggle (mute / speaker) — filled when active, outlined when not.
class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: active ? AppColors.callOn : AppColors.callControl,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Icon(icon,
                  size: 26,
                  color: active ? AppColors.callBackdrop : AppColors.callOn),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(label, style: const TextStyle(color: AppColors.callOnMuted)),
      ],
    );
  }
}
