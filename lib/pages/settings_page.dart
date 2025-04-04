import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:async';

void main() {
  runApp(const SettingsPage());
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Advanced TTS App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const TTSHomePage(),
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

  // In the _loadLanguages method, modify the sorting to put Tagalog first
  Future<void> _loadLanguages() async {
    try {
      // Get available languages from the TTS engine
      final availableLanguages = (await flutterTts.getLanguages as List<dynamic>?)?.cast<String>() ?? [];

      // Add common language codes as fallback
      final commonLanguages = [
        'tl-PH', // Tagalog (Philippines) - now first in the list
        'en-US', 'en-GB', 'es-ES', 'fr-FR', 'de-DE', 'it-IT', 'pt-BR',
        'ru-RU', 'zh-CN', 'ja-JP', 'ko-KR', 'ar-SA', 'hi-IN'
      ];

      // Combine and remove duplicates
      final allLanguageCodes = {...availableLanguages, ...commonLanguages};

      setState(() {
        languages = allLanguageCodes.map((code) {
          return <String, String>{
            'code': code,
            'displayName': _getDisplayName(code),
          };
        }).toList()
          ..sort((a, b) {
            // Put Tagalog first
            if (a['code'] == 'tl-PH') return -1;
            if (b['code'] == 'tl-PH') return 1;
            // Then sort the rest alphabetically
            return a['displayName']!.compareTo(b['displayName']!);
          });

        // Set default language to Tagalog if available
        selectedLanguage = languages.firstWhere(
              (lang) => lang['code'] == 'tl-PH',
          orElse: () => languages.first,
        )['code'];
      });
    } catch (e) {
      _showSnackBar('Error loading languages: $e');
    }
  }

// Add this method to handle playing saved audio files
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


  String _getDisplayName(String code) {
    try {
      final parts = code.split('-');
      final languageCode = parts[0].toLowerCase();
      final countryCode = parts.length > 1 ? parts[1].toUpperCase() : null;

      final languageNames = {
        'en': 'English',
        'es': 'Spanish',
        'fr': 'French',
        'de': 'German',
        'it': 'Italian',
        'pt': 'Portuguese',
        'ru': 'Russian',
        'zh': 'Chinese',
        'ja': 'Japanese',
        'ko': 'Korean',
        'ar': 'Arabic',
        'hi': 'Hindi',
        'tl': 'Tagalog', // Added Tagalog
      };

      final languageName = languageNames[languageCode] ?? languageCode.toUpperCase();

      if (countryCode != null) {
        final countryNames = {
          'US': 'United States',
          'GB': 'United Kingdom',
          'ES': 'Spain',
          'FR': 'France',
          'DE': 'Germany',
          'IT': 'Italy',
          'BR': 'Brazil',
          'RU': 'Russia',
          'CN': 'China',
          'JP': 'Japan',
          'KR': 'South Korea',
          'SA': 'Saudi Arabia',
          'IN': 'India',
          'PH': 'Philippines', // Added Philippines
        };

        final countryName = countryNames[countryCode] ?? countryCode;
        return '$languageName ($countryName)';
      }

      return languageName;
    } catch (e) {
      return code;
    }
  }

  String? _findBestLanguageMatch() {
    try {
      final systemLocale = Platform.localeName; // Get system locale
      final systemLanguage = systemLocale.split('_')[0];

      // Try exact match first
      for (var lang in languages) {
        if (lang['code']?.toLowerCase() == systemLocale.toLowerCase()) {
          return lang['code'];
        }
      }

      // Try language-only match
      for (var lang in languages) {
        if (lang['code']?.toLowerCase().startsWith('${systemLanguage}_') ?? false) {
          return lang['code'];
        }
      }

      // Fallback to English if available
      for (var lang in languages) {
        if (lang['code']?.toLowerCase().startsWith('en_') ?? false) {
          return lang['code'];
        }
      }
      // In the fallback section, you might want to check for Tagalog too
      for (var lang in languages) {
        if (lang['code']?.toLowerCase().startsWith('tl_') ?? false) {
          return lang['code'];
        }
      }

    } catch (e) {
      _showSnackBar('Error detecting system language: $e');
    }

    // Return the first language if nothing matches
    return languages.isNotEmpty ? languages.first['code'] : null;
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

      if (result == 1) {
        setState(() {
          savePath = filePath;
        });
        _showSnackBar('Audio saved to $filePath');
      } else {
        _showSnackBar('Failed to save audio file');
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

            // Update the dropdown items to show Tagalog first
            DropdownButtonFormField<String>(
              value: selectedLanguage,
              decoration: const InputDecoration(
                labelText: 'Select Language',
                border: OutlineInputBorder(),
              ),
              items: [
                // Show Tagalog first if available
                if (languages.any((lang) => lang['code'] == 'tl-PH'))
                  DropdownMenuItem<String>(
                    value: 'tl-PH',
                    child: Text(_getDisplayName('tl-PH')),
                  ),
                // Then show System Default
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('System Default'),
                ),
                // Then show other languages excluding Tagalog (since we already showed it first)
                ...languages.where((lang) => lang['code'] != 'tl-PH').map((language) {
                  return DropdownMenuItem<String>(
                    value: language['code'],
                    child: Text(language['displayName']!),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  selectedLanguage = value;
                });
              },
              isExpanded: true,
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