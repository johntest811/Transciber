import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:highlight_text/highlight_text.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/services.dart';

void main() {
  runApp(RecordingsPage());
}

class RecordingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Recorder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SpeechScreen(),
    );
  }
}

class SpeechScreen extends StatefulWidget {
  @override
  _SpeechScreenState createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  final Map<String, HighlightedWord> _highlights = {
    'flutter': HighlightedWord(
      onTap: () => print('flutter'),
      textStyle: const TextStyle(
        color: Colors.blue,
        fontWeight: FontWeight.bold,
      ),
    ),
    'voice': HighlightedWord(
      onTap: () => print('voice'),
      textStyle: const TextStyle(
        color: Colors.green,
        fontWeight: FontWeight.bold,
      ),
    ),
    'subscribe': HighlightedWord(
      onTap: () => print('subscribe'),
      textStyle: const TextStyle(
        color: Colors.red,
        fontWeight: FontWeight.bold,
      ),
    ),
    'like': HighlightedWord(
      onTap: () => print('like'),
      textStyle: const TextStyle(
        color: Colors.blueAccent,
        fontWeight: FontWeight.bold,
      ),
    ),
    'comment': HighlightedWord(
      onTap: () => print('comment'),
      textStyle: const TextStyle(
        color: Colors.green,
        fontWeight: FontWeight.bold,
      ),
    ),
  };

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Press the button and start speaking';
  double _confidence = 1.0;
  String? _currentLocaleId;
  bool _isNewRecording = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  void _initSpeech() async {
    await _speech.initialize(
      onStatus: (val) {
        print('onStatus: $val');
        if (_isListening && val == 'notListening') {
          _startListening();
        }
      },
      onError: (val) {
        print('onError: $val');
        if (_isListening) {
          _startListening();
        }
      },
    );

    final systemLocale = await _speech.systemLocale();
    setState(() {
      _currentLocaleId = systemLocale?.localeId;
    });
  }

  void _startListening() {
    _speech.listen(
      onResult: (val) => setState(() {
        if (_isNewRecording && val.recognizedWords.isNotEmpty) {
          // For new recording, replace the text
          _text = val.recognizedWords;
          _isNewRecording = false;
        } else if (val.recognizedWords.isNotEmpty) {
          // For continuing recording, append to existing text
          _text += ' ' + val.recognizedWords;
        }

        if (val.hasConfidenceRating && val.confidence > 0) {
          _confidence = val.confidence;
        }
      }),
      listenFor: Duration(minutes: 5),
      pauseFor: Duration(seconds: 5),
      partialResults: true,
      localeId: _currentLocaleId,
      onSoundLevelChange: (level) {
        print('Sound level: $level');
      },
    );
  }

  void _toggleRecording() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() {
          _isListening = true;
          _isNewRecording = true; // Mark as new recording
        });
        _startListening();
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Text copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confidence: ${(_confidence * 100.0).toStringAsFixed(1)}%'),
        actions: [
          IconButton(
            icon: Icon(Icons.copy),
            onPressed: _text.isNotEmpty ? _copyToClipboard : null,
            tooltip: 'Copy text',
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: ElevatedButton(
                onPressed: _copyToClipboard,
                child: Text('Copy Text'),
              ),
            ),
          AvatarGlow(
            animate: _isListening,
            glowColor: Theme.of(context).primaryColor,
            endRadius: 75.0,
            duration: const Duration(milliseconds: 2000),
            repeatPauseDuration: const Duration(milliseconds: 100),
            repeat: true,
            child: FloatingActionButton(
              onPressed: _toggleRecording,
              child: Icon(_isListening ? Icons.mic : Icons.mic_none),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        reverse: true,
        child: Container(
          padding: const EdgeInsets.fromLTRB(30.0, 30.0, 30.0, 150.0),
          child: TextHighlight(
            text: _text,
            words: _highlights,
            textStyle: const TextStyle(
              fontSize: 32.0,
              color: Colors.black,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}