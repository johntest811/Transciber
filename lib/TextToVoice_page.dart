import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'Home.dart';
import 'theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

class TexttovoicePage extends StatelessWidget {
  const TexttovoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Text to Speech',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: Provider.of<ThemeProvider>(context).themeMode,
      home: const TTSHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TTSHomePage extends StatefulWidget {
  const TTSHomePage({super.key});

  @override
  State<TTSHomePage> createState() => _TTSHomePageState();
}

class _TTSHomePageState extends State<TTSHomePage> {
  final FlutterTts flutterTts = FlutterTts();
  final TextEditingController textController = TextEditingController();
  bool isSpeaking = false;
  bool isSaving = false;
  bool isSavingToHistory = false;
  double volume = 1.0;
  double pitch = 1.0;
  double rate = 0.5;
  String? selectedLanguage;
  List<Map<String, String>> languages = [];
  String? savePath;
  String? savedFileName;

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _initTTS();
    _loadLanguages();
  }

  Future<void> _initTTS() async {
    await flutterTts.setVolume(volume);
    await flutterTts.setPitch(pitch);
    await flutterTts.setSpeechRate(rate);

    flutterTts.setStartHandler(() {
      setState(() {
        isSpeaking = true;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        isSpeaking = false;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        isSpeaking = false;
      });
      _showSnackBar('Error: $msg');
    });
  }

  Future<void> _loadLanguages() async {
    try {
      final supportedLanguages = [
        {'code': 'en-US', 'name': 'English (US)'},
        {'code': 'en-GB', 'name': 'English (UK)'},
        {'code': 'es-ES', 'name': 'Spanish (Spain)'},
        {'code': 'fr-FR', 'name': 'French (France)'},
        {'code': 'de-DE', 'name': 'German (Germany)'},
        {'code': 'it-IT', 'name': 'Italian (Italy)'},
        {'code': 'pt-BR', 'name': 'Portuguese (Brazil)'},
      ];

      setState(() {
        languages = supportedLanguages.map((lang) {
          return <String, String>{
            'code': lang['code']!,
            'displayName': lang['name']!,
          };
        }).toList();
        selectedLanguage = 'en-US';
      });
    } catch (e) {
      _showSnackBar('Error loading languages: $e');
    }
  }

  Future<void> _speak() async {
    if (textController.text.isEmpty) {
      _showSnackBar('Please enter some text');
      return;
    }

    try {
      if (selectedLanguage != null) {
        await flutterTts.setLanguage(selectedLanguage!);
      }
      await flutterTts.speak(textController.text);
    } catch (e) {
      _showSnackBar('Error speaking: $e');
    }
  }

  Future<void> _stop() async {
    try {
      await flutterTts.stop();
      setState(() {
        isSpeaking = false;
      });
    } catch (e) {
      _showSnackBar('Error stopping speech: $e');
    }
  }

  Future<void> _saveToFile() async {
    if (textController.text.isEmpty) {
      _showSnackBar('Please enter some text');
      return;
    }

    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        _showSnackBarWithSettings('Storage permission is required to save audio files');
        return;
      }
    }

    setState(() {
      isSaving = true;
    });

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final baseFileName = 'TTS_$timestamp.mp3';
      String filePath;

      if (Platform.isAndroid) {
        final musicDir = Directory('/storage/emulated/0/Music');
        if (!await musicDir.exists()) {
          await musicDir.create(recursive: true);
        }
        filePath = path.join(musicDir.path, baseFileName);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        filePath = path.join(directory.path, baseFileName);
      }

      debugPrint('Attempting to save to: $filePath');

      final result = await flutterTts.synthesizeToFile(
        textController.text,
        filePath,
      );

      if (result == 1) {
        debugPrint('File saved successfully at: $filePath');
        final file = File(filePath);
        final exists = await file.exists();
        debugPrint('File verification: $exists');
        if (exists) {
          debugPrint('File size: ${(await file.length()).toString()} bytes');
        }

        setState(() {
          savePath = filePath;
          savedFileName = baseFileName;
        });
        _showSnackBar('Audio saved to Music directory');
      } else {
        _showSnackBar('Failed to save audio file');
      }
    } catch (e) {
      debugPrint('Error saving audio: $e');
      _showSnackBar('Error saving audio: $e');
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  void _showSnackBarWithSettings(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Settings',
          onPressed: () {
            openAppSettings();
          },
        ),
      ),
    );
  }

  Future<void> _saveToHistory() async {
    if (textController.text.isEmpty) {
      _showSnackBar('Please enter some text');
      return;
    }

    if (savedFileName == null) {
      _showSnackBar('Please save the audio file first');
      return;
    }

    setState(() {
      isSavingToHistory = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        debugPrint('Saving to history with filename: $savedFileName');
        await _firestore.collection('users').doc(user.uid).collection('tts').add({
          'title': 'TTS ${DateFormat('MMM d').format(DateTime.now())}',
          'text': textController.text,
          'words': textController.text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length,
          'date': DateFormat('MMM d').format(DateTime.now()),
          'timestamp': FieldValue.serverTimestamp(),
          'audioFilePath': savePath, // Store the full path instead of just the filename
          'language': selectedLanguage,
        });
        _showSnackBar('Saved to history');
      } else {
        _showSnackBar('Please log in to save to history');
      }
    } catch (e) {
      debugPrint('Error saving to history: $e');
      _showSnackBar('Error saving to history: $e');
    } finally {
      setState(() {
        isSavingToHistory = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    flutterTts.stop();
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text to Speech'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => Home()),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: textController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter text to speak',
                hintText: 'Type something...',
              ),
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: selectedLanguage,
              decoration: InputDecoration(
                labelText: 'Select Language',
                border: const OutlineInputBorder(),
              ),
              dropdownColor: Theme.of(context).cardColor,
              items: languages.map((language) {
                return DropdownMenuItem<String>(
                  value: language['code'],
                  child: Text(language['displayName']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedLanguage = value;
                });
              },
              isExpanded: true,
            ),

            const SizedBox(height: 20),

            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Volume: ${volume.toStringAsFixed(1)}'),
                Slider(
                  value: volume,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  onChanged: (value) async {
                    setState(() {
                      volume = value;
                    });
                    await flutterTts.setVolume(value);
                  },
                ),
                Text('Pitch: ${pitch.toStringAsFixed(1)}'),
                Slider(
                  value: pitch,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  onChanged: (value) async {
                    setState(() {
                      pitch = value;
                    });
                    await flutterTts.setPitch(value);
                  },
                ),
                Text('Speech Rate: ${rate.toStringAsFixed(1)}'),
                Slider(
                  value: rate,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  onChanged: (value) async {
                    setState(() {
                      rate = value;
                    });
                    await flutterTts.setSpeechRate(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isSpeaking ? _stop : _speak,
                    child: Text(
                      isSpeaking ? 'Stop Speaking' : 'Speak',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isSaving ? null : _saveToFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      'Save as MP3',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isSavingToHistory ? null : _saveToHistory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: isSavingToHistory
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      'Save to History',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}