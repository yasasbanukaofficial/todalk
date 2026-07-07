import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import '../models/task.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/morphing_blob.dart';

enum ConvoState { greeting, awaitingTask, awaitingDate, awaitingPriority, saving, done }

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final String _deepgramApiKey = dotenv.env['DEEPGRAM_API_KEY'] ?? '';

  late AnimationController _animController;

  ConvoState _step = ConvoState.greeting;
  String _taskTitle = '';
  DateTime? _dueDate;
  String _priority = 'Medium';
  String _currentText = '';
  String _lastPartial = '';
  double _soundLevel = 0;
  int _retryCount = 0;

  bool _isListening = false;
  bool _isHolding = false;
  bool _available = false;
  DateTime? _tapStart;

  WebSocket? _ws;
  StreamSubscription<Uint8List>? _audioSub;

  static const int _maxRetries = 2;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _init();
  }

  Future<void> _init() async {
    if (_deepgramApiKey.isEmpty) {
      debugPrint('Deepgram API key missing');
      return;
    }
    final hasMic = await _recorder.hasPermission();
    if (!mounted) return;
    final user = context.read<AuthProvider>().user?.name ?? 'there';
    setState(() => _available = hasMic);
    if (hasMic) {
      _speakAndAdvance(
        'Hey $user, what is up with your mind today?',
        ConvoState.awaitingTask,
      );
    }
  }

  Future<void> _speak(String text) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.deepgram.com/v1/speak?model=aura-2-orion-en'),
        headers: {
          'Authorization': 'Token $_deepgramApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'text': text}),
      );
      if (response.statusCode != 200) return;

      final dir = await Directory.systemTemp.createTemp('todalk_tts_');
      final file = File('${dir.path}/audio.mp3');
      try {
        await file.writeAsBytes(response.bodyBytes);
        await _player.setAudioSource(AudioSource.file(file.path));
        await _player.play();
        await _player.processingStateStream.firstWhere(
          (s) => s == ProcessingState.completed,
        );
        await _player.stop();
      } finally {
        try { await file.delete(); } catch (_) {}
        try { await dir.delete(); } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> _speakAndAdvance(String text, ConvoState nextStep) async {
    setState(() {
      _currentText = '';
      _lastPartial = '';
      _step = nextStep;
      _retryCount = 0;
    });
    await _speak(text);
  }

  void _onTapDown() {
    if (_step != ConvoState.awaitingTask &&
        _step != ConvoState.awaitingDate &&
        _step != ConvoState.awaitingPriority) return;
    if (!_available) return;

    HapticFeedback.lightImpact();
    _tapStart = DateTime.now();
    setState(() => _isHolding = true);
    _lastPartial = '';
    _startDeepgramRecording();
  }

  Future<void> _startDeepgramRecording() async {
    try {
      _ws = await WebSocket.connect(
        'wss://api.deepgram.com/v1/listen'
        '?model=nova-3'
        '&smart_format=true'
        '&interim_results=true'
        '&punctuate=true'
        '&encoding=linear16'
        '&sample_rate=16000'
        '&channels=1',
        headers: {'Authorization': 'Token $_deepgramApiKey'},
      );

      _ws!.listen(
        (data) {
          if (data is String) {
            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              if (json['type'] == 'Results') {
                final transcript = json['channel']?['alternatives']?[0]?['transcript'] as String? ?? '';
                if (transcript.isNotEmpty) {
                  _lastPartial = transcript;
                  if (mounted) setState(() => _currentText = transcript);
                }
              }
            } catch (_) {}
          }
        },
        onError: (error) => debugPrint('Deepgram WS error: $error'),
        onDone: () => debugPrint('Deepgram WS closed'),
      );

      final stream = await _recorder.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      _audioSub = stream.listen((chunk) {
        _ws?.add(chunk);
        _soundLevel = _computeRms(chunk);
      });

      setState(() => _isListening = true);
    } catch (e) {
      debugPrint('Failed to start Deepgram recording: $e');
      setState(() {
        _isListening = false;
        _isHolding = false;
      });
    }
  }

  double _computeRms(Uint8List data) {
    if (data.length < 2) return 0;
    final byteData = data.buffer.asByteData(data.offsetInBytes, data.length);
    final count = data.length ~/ 2;
    double sumSquares = 0;
    for (int i = 0; i < count; i++) {
      final sample = byteData.getInt16(i * 2, Endian.little);
      sumSquares += (sample * sample).toDouble();
    }
    return sqrt(sumSquares / count) / 32767;
  }

  void _onTapUp() {
    if (!_isListening || _tapStart == null) return;

    HapticFeedback.lightImpact();
    final elapsed = DateTime.now().difference(_tapStart!);
    _tapStart = null;

    if (elapsed < const Duration(milliseconds: 300)) {
      _cleanupDeepgram();
      setState(() {
        _isListening = false;
        _isHolding = false;
      });
      return;
    }

    _finishDeepgramRecording();
  }

  Future<void> _finishDeepgramRecording() async {
    await _audioSub?.cancel();
    _audioSub = null;
    await _recorder.stop();

    try {
      _ws?.add(jsonEncode({'type': 'CloseStream'}));
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (_) {}

    await _ws?.close();
    _ws = null;

    setState(() {
      _isListening = false;
      _isHolding = false;
    });

    _onSpeechResult(_lastPartial);
  }

  void _onTapCancel() {
    if (!_isListening) return;
    _cleanupDeepgram();
    setState(() {
      _isListening = false;
      _isHolding = false;
    });
  }

  void _cleanupDeepgram() {
    _audioSub?.cancel();
    _audioSub = null;
    try { _recorder.stop(); } catch (_) {}
    try { _ws?.add(jsonEncode({'type': 'CloseStream'})); } catch (_) {}
    try { _ws?.close(); } catch (_) {}
    _ws = null;
  }

  void _onSpeechResult(String text) {
    if (!mounted) return;
    final trimmed = text.trim();
    final currentStep = _step;

    if (trimmed.isEmpty) {
      if (_retryCount < _maxRetries) {
        setState(() => _retryCount++);
        _speakAndAdvance(
          "Sorry, I didn't catch that. Try again?",
          currentStep,
        );
      }
      return;
    }

    setState(() => _retryCount = 0);

    switch (currentStep) {
      case ConvoState.awaitingTask:
        _taskTitle = trimmed;
        _speakAndAdvance(
          'Alright, I recorded the task: $trimmed. When is it due?',
          ConvoState.awaitingDate,
        );
      case ConvoState.awaitingDate:
        final parsed = _parseDate(trimmed);
        if (parsed != null) {
          _dueDate = parsed;
          final dateStr = _formatDateShort(parsed);
          _speakAndAdvance(
            'Got it, due $dateStr. What priority? Low, Medium, or High?',
            ConvoState.awaitingPriority,
          );
        } else if (_retryCount < _maxRetries) {
          setState(() => _retryCount++);
          _speakAndAdvance(
            "I didn't get the date. Try 'tomorrow at 5pm' or 'next Monday'.",
            ConvoState.awaitingDate,
          );
        } else {
          _dueDate = null;
          _speakAndAdvance(
            "No problem, no due date. What priority? Low, Medium, or High?",
            ConvoState.awaitingPriority,
          );
        }
      case ConvoState.awaitingPriority:
        _priority = _parsePriority(trimmed);
        _finalizeTask();
      default:
        break;
    }
  }

  Future<void> _finalizeTask() async {
    setState(() => _step = ConvoState.saving);
    await _speak('Perfect! I have saved the task: $_taskTitle.');

    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _taskTitle,
      dueDate: _dueDate,
      priority: _priority,
      source: 'Voice',
      createdAt: DateTime.now(),
    );
    await context.read<TaskProvider>().addTask(task);

    setState(() => _step = ConvoState.done);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.of(context).pop(true);
  }

  DateTime? _parseDate(String text) {
    final lower = text.toLowerCase();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lower.contains('today')) return _extractTime(today, lower);
    if (lower.contains('tomorrow')) return _extractTime(today.add(const Duration(days: 1)), lower);
    if (lower.contains('next week')) return _extractTime(today.add(const Duration(days: 7)), lower);

    const weekdays = {
      'monday': 1, 'tuesday': 2, 'wednesday': 3, 'thursday': 4,
      'friday': 5, 'saturday': 6, 'sunday': 7,
    };
    for (final entry in weekdays.entries) {
      if (lower.contains(entry.key)) {
        final target = entry.value;
        final current = today.weekday;
        var diff = target - current;
        if (diff <= 0) diff += 7;
        return _extractTime(today.add(Duration(days: diff)), lower);
      }
    }

    final dateRegex = RegExp(
      r'(january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{1,2})(?:st|nd|rd|th)?',
      caseSensitive: false,
    );
    final match = dateRegex.firstMatch(lower);
    if (match != null) {
      const months = {
        'january': 1, 'february': 2, 'march': 3, 'april': 4, 'may': 5, 'june': 6,
        'july': 7, 'august': 8, 'september': 9, 'october': 10, 'november': 11, 'december': 12,
      };
      final month = months[match.group(1)!.toLowerCase()]!;
      final day = int.parse(match.group(2)!);
      var year = today.year;
      if (month < today.month || (month == today.month && day < today.day)) year += 1;
      return _extractTime(DateTime(year, month, day), lower);
    }

    return null;
  }

  DateTime _extractTime(DateTime date, String text) {
    final lower = text.toLowerCase();
    final timeRegex = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)');
    final match = timeRegex.firstMatch(lower);
    if (match != null) {
      var hour = int.parse(match.group(1)!);
      final min = match.group(2) != null ? int.parse(match.group(2)!) : 0;
      final ampm = match.group(3)!.toLowerCase();
      if (ampm == 'pm' && hour < 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;
      return DateTime(date.year, date.month, date.day, hour, min);
    }
    if (lower.contains('morning')) return DateTime(date.year, date.month, date.day, 9);
    if (lower.contains('afternoon')) return DateTime(date.year, date.month, date.day, 14);
    if (lower.contains('evening')) return DateTime(date.year, date.month, date.day, 18);
    return DateTime(date.year, date.month, date.day, 12);
  }

  String _formatDateShort(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diff = date.difference(today).inDays;

    if (diff == 0) {
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      return 'today at $hour $amPm';
    }
    if (diff == 1) {
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      return 'tomorrow at $hour $amPm';
    }
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final suffix = _daySuffix(dt.day);
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}$suffix at $hour:$min $amPm';
  }

  String _daySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  String _parsePriority(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('high') || lower.contains('urgent') || lower.contains('important')) return 'High';
    if (lower.contains('low') || lower.contains('minor') || lower.contains('easy')) return 'Low';
    return 'Medium';
  }

  void _cancel() {
    _cleanupDeepgram();
    _player.stop();
    Navigator.of(context).pop(null);
  }

  @override
  void dispose() {
    _animController.dispose();
    _cleanupDeepgram();
    _player.dispose();
    _recorder.dispose();
    super.dispose();
  }

  bool get _isAwaitingInput =>
      _step == ConvoState.awaitingTask ||
      _step == ConvoState.awaitingDate ||
      _step == ConvoState.awaitingPriority;

  String _statusText() {
    if (_step == ConvoState.done) return 'Task saved';
    if (_step == ConvoState.saving) return 'Saving...';
    if (_isHolding) return 'Release when done';
    if (_isAwaitingInput) return 'Hold to speak';
    return '';
  }

  String _promptText() {
    switch (_step) {
      case ConvoState.awaitingTask: return 'What is the task?';
      case ConvoState.awaitingDate: return 'When is it due?';
      case ConvoState.awaitingPriority: return 'Low, Medium, or High?';
      default: return '';
    }
  }

  double get _blobScale {
    if (_isHolding) return 1.0;
    if (_isAwaitingInput) return 0.92;
    return 1.0;
  }

  double get _blobAmplitude {
    if (_step == ConvoState.done || _step == ConvoState.saving) return 0.05;
    if (_isHolding) {
      final fromSound = _soundLevel * 0.7;
      final pulse = sin(_animController.value * pi * 2) * 0.15 + 0.15;
      return (pulse + fromSound).clamp(0.0, 1.0);
    }
    return 0.08;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.voiceOverlay,
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: AnimatedBuilder(
          animation: _animController,
          builder: (_, __) {
            final phase = _animController.value;
            final amplitude = _blobAmplitude;
            final scale = _blobScale;

            return Stack(
              children: [
                SafeArea(
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      Expanded(
                        child: Center(
                          child: GestureDetector(
                            onTapDown: (_) => _onTapDown(),
                            onTapUp: (_) => _onTapUp(),
                            onTapCancel: () => _onTapCancel(),
                            child: AnimatedScale(
                              scale: scale,
                              duration: const Duration(milliseconds: 200),
                              child: MorphingBlob(
                                amplitude: amplitude,
                                phase: phase,
                                soundLevel: _soundLevel,
                                size: 200,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _isHolding && _currentText.isNotEmpty
                            ? Padding(
                                key: const ValueKey('transcript'),
                                padding: const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  _currentText,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.white,
                                  ),
                                ),
                              )
                            : Padding(
                                key: const ValueKey('prompt'),
                                padding: const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  _isHolding ? '' : _promptText(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.grey.withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 18,
                        child: Text(
                          _statusText(),
                          style: TextStyle(
                            fontSize: 13,
                            color: _isHolding
                                ? AppColors.white.withValues(alpha: 0.6)
                                : AppColors.grey.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 4,
                  right: 8,
                  child: IconButton(
                    icon: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: AppColors.grey, size: 20),
                    ),
                    onPressed: _cancel,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
