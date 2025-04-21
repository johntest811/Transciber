import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:permission_handler/permission_handler.dart';
import '/assemblyai_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Transcriber',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const TranscriptionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TranscriptionScreen extends StatefulWidget {
  const TranscriptionScreen({super.key});

  @override
  _TranscriptionScreenState createState() => _TranscriptionScreenState();
}

class _TranscriptionScreenState extends State<TranscriptionScreen> {
  final AssemblyAIService _assemblyAI = AssemblyAIService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isTranscribing = false;
  String _transcription = '';
  File? _audioFile;
  double _playbackSpeed = 1.0;
  final TextEditingController _textEditingController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
    _requestPermissions();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _textEditingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initAudioPlayer() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());

    _audioPlayer.playerStateStream.listen((state) {
      setState(() {
        // Update UI based on player state
      });
    });

    _audioPlayer.positionStream.listen((position) {
      setState(() {
        // Update position if needed
      });
    });
  }

  Future<void> _requestPermissions() async {
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
  }

  Future<void> _pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _audioFile = File(result.files.single.path!);
          _transcription = '';
        });
        await _audioPlayer.stop(); // Stop any currently playing audio
      }
    } catch (e) {
      _showError('Error picking file: $e');
    }
  }

  Future<void> _transcribeAudio() async {
    if (_audioFile == null) {
      _showError('Please select an audio file first');
      return;
    }

    setState(() {
      _isTranscribing = true;
      _transcription = '';
    });

    try {
      final uploadUrl = await _assemblyAI.uploadAudioFile(_audioFile!);
      final transcription = await _assemblyAI.transcribeAudio(uploadUrl);

      setState(() {
        _transcription = transcription;
        _textEditingController.text = transcription;
        _isTranscribing = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    } catch (e) {
      setState(() {
        _isTranscribing = false;
      });
      _showError('Transcription failed: $e');
    }
  }

  Future<void> _togglePlayback() async {
    if (_audioFile == null) return;

    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
      } else {
        if (_audioPlayer.processingState == ProcessingState.completed) {
          await _audioPlayer.seek(Duration.zero);
        }
        if (_audioPlayer.processingState == ProcessingState.idle) {
          await _audioPlayer.setAudioSource(
            AudioSource.uri(Uri.file(_audioFile!.path)),
          );
          await _audioPlayer.setSpeed(_playbackSpeed);
        }
        await _audioPlayer.play();
      }
      setState(() {}); // Update UI
    } catch (e) {
      _showError('Error playing audio: $e');
    }
  }

  void _changePlaybackSpeed() {
    setState(() {
      _playbackSpeed = _playbackSpeed == 1.0 ? 1.5 : _playbackSpeed == 1.5 ? 0.5 : 1.0;
    });
    _audioPlayer.setSpeed(_playbackSpeed);
  }

  void _saveEditedText() {
    setState(() {
      _transcription = _textEditingController.text;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Text saved successfully')),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  IconData _getPlayPauseIcon() {
    if (_audioPlayer.processingState == ProcessingState.loading ||
        _audioPlayer.processingState == ProcessingState.buffering) {
      return Icons.hourglass_top;
    } else if (_audioPlayer.playing) {
      return Icons.pause;
    } else {
      return Icons.play_arrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Transcriber'),
        actions: [
          if (_transcription.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveEditedText,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _pickAudioFile,
                    child: const Text('Select Audio File'),
                  ),
                ),
                const SizedBox(width: 10),
                if (_audioFile != null)
                  StreamBuilder<PlayerState>(
                    stream: _audioPlayer.playerStateStream,
                    builder: (context, snapshot) {
                      final playerState = snapshot.data;
                      final processingState = playerState?.processingState;
                      final playing = playerState?.playing;

                      return IconButton(
                        icon: Icon(
                          playing == true ? Icons.pause : Icons.play_arrow,
                        ),
                        onPressed: _togglePlayback,
                        tooltip: playing == true ? 'Pause' : 'Play',
                      );
                    },
                  ),
                if (_audioFile != null)
                  IconButton(
                    icon: Text('${_playbackSpeed}x'),
                    onPressed: _changePlaybackSpeed,
                    tooltip: 'Change playback speed',
                  ),
              ],
            ),
            if (_audioFile != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Selected: ${_audioFile!.path.split('/').last}',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isTranscribing ? null : _transcribeAudio,
              child: _isTranscribing
                  ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 10),
                  Text('Transcribing...'),
                ],
              )
                  : const Text('Transcribe Audio'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Transcription:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: _transcription.isEmpty
                      ? Center(
                    child: Text(
                      _isTranscribing
                          ? 'Transcribing...'
                          : 'No transcription available',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                      : Scrollbar(
                    controller: _scrollController,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: TextField(
                        controller: _textEditingController,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Edit your transcription here...',
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}