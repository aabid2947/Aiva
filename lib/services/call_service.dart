import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../core/config.dart';

/// WebRTC client for the in-app proxy call to the VoiceStream server.
///
/// Audio-only and non-trickle, matching VoiceStream's `/api/offer`: we gather
/// ICE fully, POST the offer (with the booking_request_id so the server binds
/// the right `booking_requests` row), then apply the answer. The remote audio
/// (the AIVA agent speaking) plays automatically once the track arrives.
class CallService {
  CallService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.voiceStreamBaseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
              ),
            );

  final Dio _dio;
  RTCPeerConnection? _pc;
  MediaStream? _localStream;

  Future<void> connect(int bookingRequestId) async {
    final iceServers = await _fetchIceServers();
    final pc = await createPeerConnection({
      'iceServers': iceServers,
      'sdpSemantics': 'unified-plan',
    });
    _pc = pc;

    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });
    _localStream = stream;
    for (final track in stream.getTracks()) {
      await pc.addTrack(track, stream);
    }

    final offer = await pc.createOffer(<String, dynamic>{});
    await pc.setLocalDescription(offer);
    await _waitForIceGathering(pc);

    final local = await pc.getLocalDescription();
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/offer',
      queryParameters: {'request_id': bookingRequestId},
      data: {'sdp': local!.sdp, 'type': local.type},
    );
    final answer = res.data!;
    await pc.setRemoteDescription(
      RTCSessionDescription(answer['sdp'] as String, answer['type'] as String),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchIceServers() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/api/ice_servers');
      final servers = (res.data?['iceServers'] as List?) ?? const [];
      return servers
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      // Fall back to a public STUN server so a same-network call still connects.
      return const [
        {'urls': 'stun:stun.l.google.com:19302'},
      ];
    }
  }

  /// Non-trickle: wait until ICE candidate gathering is complete (with a safety
  /// timeout — some networks never report "complete").
  Future<void> _waitForIceGathering(RTCPeerConnection pc) async {
    if (pc.iceGatheringState ==
        RTCIceGatheringState.RTCIceGatheringStateComplete) {
      return;
    }
    final done = Completer<void>();
    pc.onIceGatheringState = (state) {
      if (state == RTCIceGatheringState.RTCIceGatheringStateComplete &&
          !done.isCompleted) {
        done.complete();
      }
    };
    await done.future.timeout(const Duration(seconds: 5), onTimeout: () {});
  }

  Future<void> setMuted(bool muted) async {
    for (final track in _localStream?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = !muted;
    }
  }

  Future<void> setSpeaker(bool on) async {
    try {
      await Helper.setSpeakerphoneOn(on);
    } catch (_) {
      // Speaker routing is best-effort; ignore on platforms that don't support it.
    }
  }

  Future<void> dispose() async {
    try {
      for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
        await track.stop();
      }
      await _localStream?.dispose();
      await _pc?.close();
    } catch (_) {
      // best effort teardown
    }
    _localStream = null;
    _pc = null;
  }
}
