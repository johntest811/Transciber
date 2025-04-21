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

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const TexttovoicePage(),
    ),
  );
}

class TexttovoicePage extends StatelessWidget {
  const TexttovoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Advanced TTS App',
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
  double volume = 1.0;
  double pitch = 1.0;
  double rate = 0.5;
  String? selectedLanguage;
  List<Map<String, String>> languages = [];
  String? savePath;

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
      // Get available languages from the TTS engine
      final availableLanguages = (await flutterTts.getLanguages as List<dynamic>?)?.cast<String>() ?? [];

      // Create a comprehensive list of all possible languages with their display names
      final allLanguages = {
        'af': 'Afrikaans',
        'sq': 'Albanian',
        'am': 'Amharic',
        'ar': 'Arabic',
        'hy': 'Armenian',
        'az': 'Azerbaijani',
        'eu': 'Basque',
        'be': 'Belarusian',
        'bn': 'Bengali',
        'bs': 'Bosnian',
        'bg': 'Bulgarian',
        'my': 'Burmese',
        'ca': 'Catalan',
        'ceb': 'Cebuano',
        'zh': 'Chinese',
        'co': 'Corsican',
        'hr': 'Croatian',
        'cs': 'Czech',
        'da': 'Danish',
        'nl': 'Dutch',
        'en': 'English',
        'eo': 'Esperanto',
        'et': 'Estonian',
        'fi': 'Finnish',
        'fr': 'French',
        'fy': 'Frisian',
        'gl': 'Galician',
        'ka': 'Georgian',
        'de': 'German',
        'el': 'Greek',
        'gu': 'Gujarati',
        'ht': 'Haitian Creole',
        'ha': 'Hausa',
        'haw': 'Hawaiian',
        'he': 'Hebrew',
        'hi': 'Hindi',
        'hmn': 'Hmong',
        'hu': 'Hungarian',
        'is': 'Icelandic',
        'ig': 'Igbo',
        'id': 'Indonesian',
        'ga': 'Irish',
        'it': 'Italian',
        'ja': 'Japanese',
        'jv': 'Javanese',
        'kn': 'Kannada',
        'kk': 'Kazakh',
        'km': 'Khmer',
        'rw': 'Kinyarwanda',
        'ko': 'Korean',
        'ku': 'Kurdish',
        'ky': 'Kyrgyz',
        'lo': 'Lao',
        'la': 'Latin',
        'lv': 'Latvian',
        'lt': 'Lithuanian',
        'lb': 'Luxembourgish',
        'mk': 'Macedonian',
        'mg': 'Malagasy',
        'ms': 'Malay',
        'ml': 'Malayalam',
        'mt': 'Maltese',
        'mi': 'Maori',
        'mr': 'Marathi',
        'mn': 'Mongolian',
        'ne': 'Nepali',
        'no': 'Norwegian',
        'ny': 'Nyanja',
        'or': 'Odia',
        'ps': 'Pashto',
        'fa': 'Persian',
        'pl': 'Polish',
        'pt': 'Portuguese',
        'pa': 'Punjabi',
        'ro': 'Romanian',
        'ru': 'Russian',
        'sm': 'Samoan',
        'gd': 'Scots Gaelic',
        'sr': 'Serbian',
        'st': 'Sesotho',
        'sn': 'Shona',
        'sd': 'Sindhi',
        'si': 'Sinhala',
        'sk': 'Slovak',
        'sl': 'Slovenian',
        'so': 'Somali',
        'es': 'Spanish',
        'su': 'Sundanese',
        'sw': 'Swahili',
        'sv': 'Swedish',
        'tl': 'Tagalog',
        'tg': 'Tajik',
        'ta': 'Tamil',
        'tt': 'Tatar',
        'te': 'Telugu',
        'th': 'Thai',
        'tr': 'Turkish',
        'tk': 'Turkmen',
        'uk': 'Ukrainian',
        'ur': 'Urdu',
        'ug': 'Uyghur',
        'uz': 'Uzbek',
        'vi': 'Vietnamese',
        'cy': 'Welsh',
        'xh': 'Xhosa',
        'yi': 'Yiddish',
        'yo': 'Yoruba',
        'zu': 'Zulu',
      };

      // Filter to only include languages that are available on the device
      final supportedLanguages = <String, String>{};
      for (final code in availableLanguages) {
        final baseCode = code.split('-').first.toLowerCase();
        if (allLanguages.containsKey(baseCode)) {
          supportedLanguages[baseCode] = allLanguages[baseCode]!;
        }
      }

      // Add any remaining languages from our comprehensive list that might not be detected
      for (final entry in allLanguages.entries) {
        if (!supportedLanguages.containsKey(entry.key)) {
          supportedLanguages[entry.key] = entry.value;
        }
      }

      setState(() {
        languages = supportedLanguages.entries.map((entry) {
          return <String, String>{
            'code': entry.key,
            'displayName': entry.value,
          };
        }).toList()
          ..sort((a, b) {
            // Put Tagalog first
            if (a['code'] == 'tl') return -1;
            if (b['code'] == 'tl') return 1;
            // Then sort the rest alphabetically
            return a['displayName']!.compareTo(b['displayName']!);
          });

        // Set default language to Tagalog if available, otherwise first language
        selectedLanguage = languages.firstWhere(
              (lang) => lang['code'] == 'tl',
          orElse: () => languages.first,
        )['code'];
      });
    } catch (e) {
      _showSnackBar('Error loading languages: $e');
    }
  }

  Future<void> _playSavedAudio() async {
    if (savePath == null) return;

    try {
      _showSnackBar('Playing saved audio...');
      // You would typically use a package like audioplayers here
      // Example: await AudioPlayer().play(DeviceFileSource(savePath!));
    } catch (e) {
      _showSnackBar('Error playing audio: $e');
    }
  }

  Future<bool> _setLanguage(String? languageCode) async {
    if (languageCode == null) {
      languageCode = 'en'; // Default to English
    }

    try {
      // First try the exact language code
      var result = await flutterTts.setLanguage(languageCode);

      // If that fails, try appending a country code
      if (result != 1) {
        if (languageCode == 'tl') {
          // Special case for Tagalog - try Philippines variant
          result = await flutterTts.setLanguage('tl-PH');
        } else {
          // For other languages, try with US/UK variants
          result = await flutterTts.setLanguage('${languageCode}-US');
          if (result != 1) {
            result = await flutterTts.setLanguage('${languageCode}-GB');
          }
        }
      }

      if (result != 1) {
        _showSnackBar('Language $languageCode not supported, using default');
        return false;
      }
      return true;
    } catch (e) {
      _showSnackBar('Error setting language: $e');
      return false;
    }
  }

  String? _findBestLanguageMatch() {
    try {
      final systemLocale = Platform.localeName.split('_').first.toLowerCase();

      // First try exact match
      for (var lang in languages) {
        if (lang['code']?.toLowerCase() == systemLocale) {
          return lang['code'];
        }
      }

      // Fallback to English
      return 'en';
    } catch (e) {
      _showSnackBar('Error detecting system language: $e');
      return 'en';
    }
  }

  Future<void> _speak() async {
    if (textController.text.isEmpty) {
      _showSnackBar('Please enter some text');
      return;
    }

    try {
      if (!await _setLanguage(selectedLanguage)) {
        // If language setting failed, try with default
        await _setLanguage(null);
      }

      await flutterTts.setVolume(volume);
      await flutterTts.setPitch(pitch);
      await flutterTts.setSpeechRate(rate);

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

    // Check and request storage permission
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        _showSnackBar('Storage permission is required to save audio files');
        return;
      }
    }

    setState(() {
      isSaving = true;
    });

    try {
      // Get downloads directory for better compatibility
      final directory = await getDownloadsDirectory();
      final fileName = 'tts_${DateTime.now().millisecondsSinceEpoch}.mp3';
      final filePath = '${directory?.path}/$fileName';

      // Set language if selected
      if (selectedLanguage != null) {
        await flutterTts.setLanguage(selectedLanguage!);
      } else {
        final defaultLanguage = _findBestLanguageMatch();
        if (defaultLanguage != null) {
          await flutterTts.setLanguage(defaultLanguage);
        }
      }

      // Set speech parameters
      await flutterTts.setVolume(volume);
      await flutterTts.setPitch(pitch);
      await flutterTts.setSpeechRate(rate);

      // Synthesize to file
      final result = await flutterTts.synthesizeToFile(
        textController.text,
        filePath,
      );

      // Update your _saveToFile method to also save to Firestore
      if (result == 1) {
        final user = _auth.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).collection('tts').add({
            'title': 'TTS ${DateFormat('MMM d').format(DateTime.now())}',
            'text': textController.text,
            'words': textController.text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length,
            'date': DateFormat('MMM d').format(DateTime.now()),
            'timestamp': FieldValue.serverTimestamp(),
            'audioPath': filePath,
            'language': selectedLanguage,
          });
        }

        setState(() {
          savePath = filePath;
        });
        _showSnackBar('Audio saved to $filePath');
      }

    } catch (e) {
      _showSnackBar('Error saving audio: $e');
    } finally {
      setState(() {
        isSaving = false;
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
        title: const Text('Advanced TTS App'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => Home()),
          ),
        ),
        actions: [
          if (savePath != null)
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () {
                _showSnackBar('Playing: $savePath');
              },
            ),
        ],
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
                labelStyle: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              dropdownColor: Theme.of(context).cardColor,
              items: languages.map((language) {
                return DropdownMenuItem<String>(
                  value: language['code'],
                  child: Text(
                    language['displayName']!,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) async {
                if (value == null) return;

                setState(() {
                  selectedLanguage = value;
                });
                // Immediately test the voice when language changes
                if (textController.text.isNotEmpty) {
                  await flutterTts.stop();
                  if (await _setLanguage(value)) {
                    await flutterTts.speak('Hello'); // Test phrase
                  }
                }
              },
              isExpanded: true,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 20),

            // Speech Settings
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

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isSpeaking ? _stop : _speak,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(
                      isSpeaking ? 'Stop Speaking' : 'Speak',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isSaving ? null : _saveToFile,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.green,
                    ),
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      'Save as MP3',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

            // Saved file info
            if (savePath != null) ...[
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Last saved audio:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        File(savePath!).uri.pathSegments.last,
                        style: const TextStyle(color: Colors.blue),
                      ),
                      Text(
                        savePath!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}