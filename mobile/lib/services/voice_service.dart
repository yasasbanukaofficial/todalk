import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum VoiceEventType {
  transcript,
  stateChange,
  audioChunk,
  audioEnd,
  taskCreated,
  error,
  connected,
}

class VoiceEvent {
  final VoiceEventType type;
  final dynamic data;

  VoiceEvent({required this.type, this.data});
}

class VoiceService {
  WebSocket? _ws;
  StreamSubscription? _wsSubscription;
  final StreamController<VoiceEvent> _eventController =
      StreamController<VoiceEvent>.broadcast();
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  Stream<VoiceEvent> get events => _eventController.stream;
  bool get isConnected => _ws != null;

  final String _baseUrl;
  final String? _userName;

  VoiceService({required String baseUrl, String? userName})
      : _baseUrl = baseUrl,
        _userName = userName;

  Future<void> connect() async {
    _reconnectAttempts = 0;
    return _connectWithRetry();
  }

  Future<void> _connectWithRetry() async {
    final wsUrl = _baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    try {
      _ws = await WebSocket.connect('$wsUrl/voice/stream')
          .timeout(const Duration(seconds: 10));

      _reconnectAttempts = 0;

      if (_userName != null && _userName != 'there') {
        _ws!.add(jsonEncode({
          'event': 'set_user',
          'data': {'name': _userName},
        }));
      }

      _wsSubscription = _ws!.listen(
        (data) {
          if (data is String) {
            _handleTextMessage(data);
          } else if (data is List<int>) {
            _eventController.add(VoiceEvent(
              type: VoiceEventType.audioChunk,
              data: Uint8List.fromList(data),
            ));
          }
        },
        onError: (error) {
          _eventController.add(VoiceEvent(
            type: VoiceEventType.error,
            data: error.toString(),
          ));
        },
        onDone: () {
          debugPrint('Voice WS closed');
          _scheduleReconnect();
        },
      );

      _eventController.add(VoiceEvent(type: VoiceEventType.connected));
    } catch (e) {
      _eventController.add(VoiceEvent(
        type: VoiceEventType.error,
        data: e.toString(),
      ));
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) return;
    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts);
    debugPrint('Voice WS reconnecting in ${delay.inSeconds}s '
        '(attempt $_reconnectAttempts/$_maxReconnectAttempts)');
    Future.delayed(delay, _connectWithRetry);
  }

  void _handleTextMessage(String text) {
    try {
      final json = jsonDecode(text) as Map<String, dynamic>;
      final type = json['type'] as String;

      switch (type) {
        case 'transcript':
          _eventController.add(VoiceEvent(
            type: VoiceEventType.transcript,
            data: json,
          ));
        case 'state_change':
          _eventController.add(VoiceEvent(
            type: VoiceEventType.stateChange,
            data: json['state'],
          ));
        case 'audio_end':
          _eventController.add(VoiceEvent(
            type: VoiceEventType.audioEnd,
          ));
        case 'task_created':
          _eventController.add(VoiceEvent(
            type: VoiceEventType.taskCreated,
            data: json['task'],
          ));
      }
    } catch (_) {}
  }

  void sendAudioChunk(Uint8List chunk) {
    _ws?.add(chunk);
  }

  void closeStream() {
    _ws?.add(jsonEncode({'event': 'close_stream'}));
  }

  void cancel() {
    try {
      _ws?.add(jsonEncode({'event': 'cancel'}));
    } catch (_) {}
  }

  Future<void> disconnect() async {
    await _wsSubscription?.cancel();
    try {
      await _ws?.close();
    } catch (_) {}
    _ws = null;
  }

  void dispose() {
    _eventController.close();
  }

  static Future<VoiceService> create({String? userName}) async {
    final baseUrl = (dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000')
        .replaceAll(RegExp(r'/+$'), '');
    return VoiceService(baseUrl: baseUrl, userName: userName);
  }
}
