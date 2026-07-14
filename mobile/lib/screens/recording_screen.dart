import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import '../models/task.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../services/voice_service.dart';
import '../widgets/morphing_blob.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  VoiceService? _voice;

  late AnimationController _animController;

  String _currentState = 'connecting';
  String _currentText = '';
  double _soundLevel = 0;

  bool _isListening = false;
  bool _isHolding = false;
  bool _available = false;
  DateTime? _tapStart;

  StreamSubscription<dynamic>? _audioSub;
  StreamSubscription<VoiceEvent>? _voiceSub;
  List<Uint8List> _audioBuffer = [];
  bool _isSpeaking = false;
  bool _taskSaved = false;

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
    final hasMic = await _recorder.hasPermission();
    if (!mounted) return;
    setState(() => _available = hasMic);

    if (!hasMic) return;

    final user = context.read<AuthProvider>().user?.name;

    _voice = await VoiceService.create(userName: user);
    _voiceSub = _voice!.events.listen(_onVoiceEvent);
    await _voice!.connect();
  }

  void _onVoiceEvent(VoiceEvent event) {
    if (!mounted) return;

    switch (event.type) {
      case VoiceEventType.connected:
        break;

      case VoiceEventType.stateChange:
        setState(() {
          _currentState = event.data as String;
          _currentText = '';
        });
        break;

      case VoiceEventType.transcript:
        final json = event.data as Map<String, dynamic>;
        final text = json['text'] as String? ?? '';
        if (text.isNotEmpty) {
          setState(() => _currentText = text);
        }
        break;

      case VoiceEventType.audioChunk:
        _audioBuffer.add(event.data as Uint8List);
        break;

      case VoiceEventType.audioEnd:
        _playBufferedAudio();
        break;

      case VoiceEventType.taskCreated:
        _onTaskCreated(event.data as Map<String, dynamic>);
        break;

      case VoiceEventType.error:
        debugPrint('Voice error: ${event.data}');
        break;
    }
  }

  Future<void> _playBufferedAudio() async {
    if (_audioBuffer.isEmpty) return;

    setState(() => _isSpeaking = true);

    try {
      final buffer = _mergeAudioBuffers();
      final dir = await Directory.systemTemp.createTemp('todalk_tts_');
      final file = File('${dir.path}/audio.mp3');
      await file.writeAsBytes(buffer);
      await _player.setAudioSource(AudioSource.file(file.path));
      await _player.play();
      await _player.processingStateStream.firstWhere(
        (s) => s == ProcessingState.completed,
      );
      await _player.stop();
      try { await file.delete(); } catch (_) {}
      try { await dir.delete(); } catch (_) {}
    } catch (_) {}

    _audioBuffer.clear();
    setState(() => _isSpeaking = false);

    if (_taskSaved && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Uint8List _mergeAudioBuffers() {
    int totalSize = 0;
    for (final chunk in _audioBuffer) {
      totalSize += chunk.length;
    }
    final merged = Uint8List(totalSize);
    int offset = 0;
    for (final chunk in _audioBuffer) {
      merged.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return merged;
  }

  void _onTaskCreated(Map<String, dynamic> taskData) {
    final title = taskData['title'] as String? ?? '';
    final dueDateStr = taskData['dueDate'] as String?;
    final priority = taskData['priority'] as String? ?? 'MEDIUM';

    DateTime? dueDate;
    if (dueDateStr != null) {
      dueDate = DateTime.tryParse(dueDateStr);
    }

    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      dueDate: dueDate,
      priority: priority == 'HIGH'
          ? 'High'
          : priority == 'LOW'
              ? 'Low'
              : 'Medium',
      source: 'Voice',
      createdAt: DateTime.now(),
    );
    context.read<TaskProvider>().addTask(task);
    _taskSaved = true;
    setState(() => _currentState = 'done');

    if (!_isSpeaking && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _onTapDown() {
    if (_currentState != 'awaitingTask' &&
        _currentState != 'awaitingDate' &&
        _currentState != 'awaitingTime' &&
        _currentState != 'awaitingPriority') return;
    if (!_available || _isSpeaking) return;

    HapticFeedback.lightImpact();
    _tapStart = DateTime.now();
    setState(() => _isHolding = true);

    _startRecording();
  }

  Future<void> _startRecording() async {
    try {
      final stream = await _recorder.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      _audioSub = stream.listen((chunk) {
        _voice?.sendAudioChunk(chunk);
        _soundLevel = _computeRms(chunk);
      });

      setState(() => _isListening = true);
    } catch (e) {
      debugPrint('Failed to start recording: $e');
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
      _cleanup();
      setState(() {
        _isListening = false;
        _isHolding = false;
      });
      return;
    }

    _finishRecording();
  }

  Future<void> _finishRecording() async {
    await _audioSub?.cancel();
    _audioSub = null;
    await _recorder.stop();
    _voice?.closeStream();

    setState(() {
      _isListening = false;
      _isHolding = false;
    });
  }

  void _onTapCancel() {
    if (!_isListening) return;
    _cleanup();
    setState(() {
      _isListening = false;
      _isHolding = false;
    });
  }

  void _cleanup() {
    _audioSub?.cancel();
    _audioSub = null;
    try { _recorder.stop(); } catch (_) {}
    _voice?.closeStream();
  }

  void _cancel() {
    _voice?.cancel();
    _player.stop();
    Navigator.of(context).pop(null);
  }

  @override
  void dispose() {
    _animController.dispose();
    _audioSub?.cancel();
    _voiceSub?.cancel();
    _voice?.disconnect();
    _player.dispose();
    _recorder.dispose();
    super.dispose();
  }

  bool get _isAwaitingInput =>
      _currentState == 'awaitingTask' ||
      _currentState == 'awaitingDate' ||
      _currentState == 'awaitingTime' ||
      _currentState == 'awaitingPriority';

  String _statusText() {
    if (_currentState == 'done') return 'TASK SAVED';
    if (_currentState == 'saving') return 'SAVING...';
    if (_isSpeaking) return '';
    if (_isHolding) return 'RELEASE WHEN DONE';
    if (_isAwaitingInput) return 'HOLD TO SPEAK';
    if (_currentState == 'connecting' || _currentState == 'greeting') return 'CONNECTING...';
    return '';
  }

  String _promptText() {
    switch (_currentState) {
      case 'awaitingTask': return 'What is the task?';
      case 'awaitingDate': return 'When is it due?';
      case 'awaitingTime': return 'What time?';
      case 'awaitingPriority': return 'Low, Medium, or High?';
      default: return '';
    }
  }

  double get _blobScale {
    if (_isHolding) return 1.0;
    if (_isAwaitingInput) return 0.92;
    return 1.0;
  }

  double get _blobAmplitude {
    if (_currentState == 'done' || _currentState == 'saving') return 0.05;
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
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 18,
                        child: Text(
                          _statusText(),
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 3,
                            fontWeight: FontWeight.w500,
                            color: _isHolding
                                ? AppColors.textSecondary
                                : AppColors.textTertiary,
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
                  child: GestureDetector(
                    onTap: _cancel,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.hairline, width: 1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: AppColors.textSecondary, size: 18),
                    ),
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
