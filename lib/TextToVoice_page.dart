import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
// import 'package:flutter/services.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'Home.dart';
import 'theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Added for Firebase Storage
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
  String? audioDownloadUrl; // Added to store Firebase Storage URL

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance; // Added for Firebase Storage

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
      audioDownloadUrl = null; // Reset audioDownloadUrl to ensure it’s fresh
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

          // Upload to Firebase Storage
          final user = _auth.currentUser;
          if (user != null) {
            final storageRef = _storage.ref().child('users/${user.uid}/tts/$baseFileName');
            final uploadTask = storageRef.putFile(file);
            final snapshot = await uploadTask;
            final downloadUrl = await snapshot.ref.getDownloadURL();
            debugPrint('Uploaded to Firebase Storage: $downloadUrl');

            setState(() {
              audioDownloadUrl = downloadUrl; // Store the download URL
            });
          } else {
            debugPrint('User not logged in, skipping upload to Firebase Storage');
            _showSnackBar('Audio saved locally, but not uploaded to cloud. Please log in to save to history.');
          }
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
          'audioDownloadUrl': audioDownloadUrl, // Store the Firebase Storage URL
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Text to Speech'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => Home()),
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: textController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: theme.dividerColor,
                          ),
                        ),
                        labelText: 'Enter text to speak',
                        hintText: 'Type something...',
                        filled: true,
                        fillColor: isDarkMode
                            ? Colors.grey[900]
                            : Colors.grey[50],
                      ),
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedLanguage,
                      decoration: InputDecoration(
                        labelText: 'Select Language',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: isDarkMode
                            ? Colors.grey[900]
                            : Colors.grey[50],
                      ),
                      dropdownColor: theme.cardColor,
                      items: languages.map((language) {
                        return DropdownMenuItem<String>(
                          value: language['code'],
                          child: Text(
                            language['displayName']!,
                            style: theme.textTheme.bodyLarge,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedLanguage = value;
                        });
                      },
                      isExpanded: true,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Voice Settings Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Voice Settings',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSliderWithIcon(
                      context,
                      icon: Icons.volume_up,
                      label: 'Volume',
                      value: volume,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (value) async {
                        setState(() {
                          volume = value;
                        });
                        await flutterTts.setVolume(value);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSliderWithIcon(
                      context,
                      icon: Icons.trending_up,
                      label: 'Pitch',
                      value: pitch,
                      min: 0.5,
                      max: 2.0,
                      onChanged: (value) async {
                        setState(() {
                          pitch = value;
                        });
                        await flutterTts.setPitch(value);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSliderWithIcon(
                      context,
                      icon: Icons.speed,
                      label: 'Speech Rate',
                      value: rate,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (value) async {
                        setState(() {
                          rate = value;
                        });
                        await flutterTts.setSpeechRate(value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(
                      isSpeaking ? Icons.stop : Icons.play_arrow,
                      size: 24,
                      color: Colors.white,
                    ),
                    label: Text(
                      isSpeaking ? 'Stop' : 'Speak',
                      style: const TextStyle(fontSize: 16,
                      color: Colors.white),
                    ),
                    onPressed: isSpeaking ? _stop : _speak,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: isSpeaking
                          ? Colors.redAccent
                          : theme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: isSaving
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.save_alt, size: 24),
                    label: Text(
                      isSaving ? 'Saving...' : 'Save as MP3',
                      style: const TextStyle(fontSize: 16),
                    ),
                    onPressed: isSaving ? null : _saveToFile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.blueAccent,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: isSavingToHistory
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.history, size: 24),
                    label: Text(
                      isSavingToHistory ? 'Saving...' : 'Save History',
                      style: const TextStyle(fontSize: 16),
                    ),
                    onPressed: isSavingToHistory ? null : _saveToHistory,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.green,
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

  Widget _buildSliderWithIcon(
      BuildContext context, {
        required IconData icon,
        required String label,
        required double value,
        required double min,
        required double max,
        required ValueChanged<double> onChanged,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            Text(
              value.toStringAsFixed(1),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: 10,
          onChanged: onChanged,
          activeColor: Theme.of(context).primaryColor,
          inactiveColor: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ],
    );
  }
}