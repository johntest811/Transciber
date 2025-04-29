import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:highlight_text/highlight_text.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'Home.dart';
import 'theme_provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const VoicetotextPage(),
    ),
  );
}

class VoicetotextPage extends StatelessWidget {
  const VoicetotextPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Recorder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: Colors.red,
          secondary: Colors.redAccent,
        ),
      ),
      themeMode: Provider.of<ThemeProvider>(context).themeMode,
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
  bool _isPaused = false;
  String _text = 'Press the button and start speaking';
  double _confidence = 1.0;
  String? _currentLocaleId;
  bool _isNewRecording = false;
  List<stt.LocaleName> _locales = [];
  String _selectedLanguage = 'System Default';

  // For text animation
  final List<SpeechRecognitionResult> _textBuffer = [];
  bool _isProcessingText = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  void _initSpeech() async {
    try {
      bool initialized = await _speech.initialize(
        onStatus: (status) {
          print('Speech status: $status');
          if (status == 'notListening' && _isListening && !_isPaused) {
            _startListening();
          }
        },
        onError: (error) {
          print('Speech error: $error');
          if (_isListening && !_isPaused) {
            _startListening();
          }
        },
      );

      if (initialized) {
        _locales = await _speech.locales();
        final systemLocale = await _speech.systemLocale();
        setState(() {
          _currentLocaleId = systemLocale?.localeId;
          _selectedLanguage = systemLocale?.name ?? 'System Default';
        });
      }
    } catch (e) {
      print('Error initializing speech: $e');
    }
  }

  void _startListening() {
    if (!_speech.isAvailable) {
      print('Speech not available');
      return;
    }

    _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        if (!_isProcessingText) {
          _isProcessingText = true;
          _processResult(result);
          Future.delayed(Duration(milliseconds: 100), () {
            _isProcessingText = false;
            if (_textBuffer.isNotEmpty) {
              _processResult(_textBuffer.removeLast());
            }
          });
        } else {
          _textBuffer.add(result);
        }
      },
      listenFor: Duration(minutes: 5),
      pauseFor: Duration(seconds: 5),
      partialResults: true,
      localeId: _currentLocaleId,
      onSoundLevelChange: (level) {
        // Optional: Can be used for visual feedback
      },
      cancelOnError: false,
      listenMode: stt.ListenMode.confirmation,
    );
  }

  void _processResult(SpeechRecognitionResult result) {
    setState(() {
      if (_isNewRecording && result.recognizedWords.isNotEmpty) {
        _text = result.recognizedWords;
        _isNewRecording = false;
      } else if (result.recognizedWords.isNotEmpty) {
        _text = '$_text ${result.recognizedWords}';
      }

      if (result.hasConfidenceRating && result.confidence > 0) {
        _confidence = result.confidence;
      }
    });
  }

  void _toggleRecording() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
          _isPaused = false;
          _isNewRecording = true;
        });
        _startListening();
      }
    } else {
      setState(() {
        _isListening = false;
        _isPaused = false;
      });
      _speech.stop();
    }
  }

  void _togglePause() {
    if (_isListening) {
      if (_isPaused) {
        _startListening();
      } else {
        _speech.stop();
      }
      setState(() {
        _isPaused = !_isPaused;
      });
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Text copied to clipboard')),
    );
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _saveRecording() async {
    if (_text.isEmpty) return;

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Count words
      final wordCount = _text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;

      await _firestore.collection('users').doc(user.uid).collection('recordings').add({
        'title': 'Recording ${DateFormat('MMM d').format(DateTime.now())}',
        'text': _text,
        'words': wordCount,
        'date': DateFormat('MMM d').format(DateTime.now()),
        'timestamp': FieldValue.serverTimestamp(),
        'language': _selectedLanguage,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recording saved to your history')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving recording: $e')),
      );
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Language'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              ListTile(
                title: Text('System Default'),
                onTap: () {
                  setState(() {
                    _currentLocaleId = null;
                    _selectedLanguage = 'System Default';
                  });
                  Navigator.pop(context);
                },
              ),
              ..._locales.map((locale) => ListTile(
                title: Text(locale.name),
                onTap: () {
                  setState(() {
                    _currentLocaleId = locale.localeId;
                    _selectedLanguage = locale.name;
                  });
                  Navigator.pop(context);
                },
              )).toList(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Home()),
            );
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confidence: ${(_confidence * 100.0).toStringAsFixed(1)}%'),
            Text(
              'Language: $_selectedLanguage',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.language),
            onPressed: _showLanguageDialog,
            tooltip: 'Change language',
          ),
          IconButton(
            icon: Icon(Icons.copy),
            onPressed: _text.isNotEmpty ? _copyToClipboard : null,
            tooltip: 'Copy text',
          ),
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _text.isNotEmpty ? _saveRecording : null,
            tooltip: 'Save to file',
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _copyToClipboard,
                    child: Text('Copy'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _text.isNotEmpty ? _saveRecording : null,
                    child: Text('Save'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isListening)
                FloatingActionButton(
                  onPressed: _togglePause,
                  heroTag: 'pause',
                  mini: true,
                  child: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                ),
              SizedBox(width: 20),
              AvatarGlow(
                animate: _isListening && !_isPaused,
                glowColor: Theme.of(context).primaryColor,
                endRadius: 75.0,
                duration: const Duration(milliseconds: 2000),
                repeatPauseDuration: const Duration(milliseconds: 100),
                repeat: true,
                child: FloatingActionButton(
                  onPressed: _toggleRecording,
                  heroTag: 'record',
                  child: Icon(_isListening ? Icons.mic : Icons.mic_none),
                ),
              ),
            ],
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
            textStyle: TextStyle(
              fontSize: 32.0,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}