import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'FileToText_page.dart';
import 'TextToVoice_page.dart';
import 'VoiceToText_page.dart';
import 'theme_provider.dart';
import 'LoginOptions.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:developer';  // For debugPrint
import 'settings.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const Home(),
    ),
  );
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trancify',
      theme: ThemeData.light().copyWith(
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardColor: Colors.white,
        cardTheme: CardTheme(
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardColor: Colors.grey[800],
        cardTheme: CardTheme(
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      themeMode: Provider.of<ThemeProvider>(context).themeMode,
      home: const HomePage(),
      routes: {
        '/file-to-text': (context) => ChangeNotifierProvider.value(
          value: Provider.of<ThemeProvider>(context, listen: false),
          child: const FiletotextPage(),
        ),
        '/text-to-voice': (context) => ChangeNotifierProvider.value(
          value: Provider.of<ThemeProvider>(context, listen: false),
          child: const TexttovoicePage(),
        ),
        '/voice-to-text': (context) => ChangeNotifierProvider.value(
          value: Provider.of<ThemeProvider>(context, listen: false),
          child: VoicetotextPage(),
        ),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 1;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _viewRecording(DocumentSnapshot recording) {
    final data = recording.data() as Map<String, dynamic>?;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _HistoryItemView(
          title: data?['title'] ?? 'Recording',
          content: data?['text'] ?? '',
          type: 'recording',
          audioPath: data?['audioFileName'],
          docId: recording.id,
        ),
      ),
    );
  }

  void _viewTranscription(DocumentSnapshot transcription) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _HistoryItemView(
          title: transcription['title'],
          content: transcription['text'],
          type: 'transcription',
          docId: transcription.id,
        ),
      ),
    );
  }

  void _viewTTS(DocumentSnapshot tts) {
    final data = tts.data() as Map<String, dynamic>?;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _HistoryItemView(
          title: data?['title'] ?? 'TTS',
          content: data?['text'] ?? '',
          type: 'tts',
          audioPath: data?['audioFileName'],
          docId: tts.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Please log in to view your history'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginOptions()),
                  );
                },
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: Theme.of(context).brightness == Brightness.dark ? 0 : 2,
        shadowColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.transparent
            : Colors.grey.withOpacity(0.3),
        leading: IconButton(
          icon: Icon(Icons.menu, color: Theme.of(context).iconTheme.color),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          'Welcome to Trancify',
          style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
            onPressed: () {},
          ),
        ],
      ),

      drawer: _buildDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recordings Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recordings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => _HistoryListView(
                            collectionName: 'recordings',
                            title: 'All Recordings',
                            onItemTap: _viewRecording,
                          ),
                        ),
                      );
                    },
                    child: const Text('See all'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 120,
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('users')
                      .doc(user.uid)
                      .collection('recordings')
                      .orderBy('timestamp', descending: true)
                      .limit(3)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No recordings yet'));
                    }

                    final recordings = snapshot.data!.docs;
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: recordings.length,
                      itemBuilder: (context, index) {
                        final recording = recordings[index];
                        return _buildRecordingCard(
                          recording['title'] ?? 'Recording',
                          recording['date'] ?? 'No date',
                          recording,
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),

              // Transcriptions Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Transcriptions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => _HistoryListView(
                            collectionName: 'transcriptions',
                            title: 'All Transcriptions',
                            onItemTap: _viewTranscription,
                          ),
                        ),
                      );
                    },
                    child: const Text('See all'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .doc(user.uid)
                    .collection('transcriptions')
                    .orderBy('timestamp', descending: true)
                    .limit(3)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No transcriptions yet'));
                  }

                  final transcriptions = snapshot.data!.docs;
                  return Column(
                    children: transcriptions.map((doc) {
                      return _buildTranscriptionCard(
                        doc['title'] ?? 'Transcription',
                        doc['words']?.toString() ?? '0',
                        doc['date'] ?? 'No date',
                        doc,
                      );
                    }).toList(),
                  );
                },
              ),

              // Text-to-Speech Section
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Text-to-Speech',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => _HistoryListView(
                            collectionName: 'tts',
                            title: 'All TTS Conversions',
                            onItemTap: _viewTTS,
                          ),
                        ),
                      );
                    },
                    child: const Text('See all'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .doc(user.uid)
                    .collection('tts')
                    .orderBy('timestamp', descending: true)
                    .limit(3)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No TTS conversions yet'));
                  }

                  final ttsItems = snapshot.data!.docs;
                  return Column(
                    children: ttsItems.map((doc) {
                      return _buildTtsCard(
                        doc['title'] ?? 'TTS Conversion',
                        doc['words']?.toString() ?? '0',
                        doc['date'] ?? 'No date',
                        doc,
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        selectedItemColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/text-to-voice');
              break;
            case 1:
              Navigator.pushNamed(context, '/voice-to-text');
              break;
            case 2:
              Navigator.pushNamed(context, '/file-to-text');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.text_snippet),
            label: 'Text to Voice',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mic),
            label: 'Voice to Text',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_drive_file),
            label: 'File to Text',
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingCard(String title, String date, DocumentSnapshot doc) {
    return GestureDetector(
      onTap: () => _viewRecording(doc),
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).cardTheme.shadowColor ?? Colors.black.withOpacity(0.1),
              blurRadius: Theme.of(context).cardTheme.elevation ?? 2,
              spreadRadius: 0.5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const Spacer(),
              Text(
                date,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTranscriptionCard(String title, String words, String date, DocumentSnapshot doc) {
    return GestureDetector(
      onTap: () => _viewTranscription(doc),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).cardTheme.shadowColor ?? Colors.black.withOpacity(0.1),
              blurRadius: Theme.of(context).cardTheme.elevation ?? 2,
              spreadRadius: 0.5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          subtitle: Text(
            '$words Words • $date',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTtsCard(String title, String words, String date, DocumentSnapshot doc) {
    return GestureDetector(
      onTap: () => _viewTTS(doc),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).cardTheme.shadowColor ?? Colors.black.withOpacity(0.1),
              blurRadius: Theme.of(context).cardTheme.elevation ?? 2,
              spreadRadius: 0.5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          leading: const Icon(Icons.volume_up),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          subtitle: Text(
            '$words Words • $date',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                user?.displayName ?? 'Guest',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(
                user?.email ?? 'No email',
                style: const TextStyle(fontSize: 14),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.cyanAccent,
                child: user?.photoURL != null
                    ? ClipOval(
                  child: Image.network(
                    user!.photoURL!,
                    fit: BoxFit.cover,
                    width: 64,
                    height: 64,
                  ),
                )
                    : Text(
                  user?.email?.substring(0, 1).toUpperCase() ?? 'G',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[900]
                    : Colors.blue[900],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDrawerItem(
                    icon: Icons.insert_drive_file,
                    text: 'File to Text',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/file-to-text');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.mic,
                    text: 'Voice to Text',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/voice-to-text');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.text_snippet,
                    text: 'Text to Voice',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/text-to-voice');
                    },
                  ),
                  // Add this to your _buildDrawer method, before the logout option
                  _buildDrawerItem(
                    icon: Icons.settings,
                    text: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsPage()),
                      );
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    value: themeProvider.themeMode == ThemeMode.dark,
                    onChanged: (value) {
                      themeProvider.toggleTheme(value);
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: _buildDrawerItem(
                icon: Icons.logout,
                text: 'Logout',
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginOptions()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: Theme.of(context).brightness == Brightness.dark ? 2 : 1,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          size: 30,
          color: Theme.of(context).iconTheme.color,
        ),
        title: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _HistoryListView extends StatelessWidget {
  final String collectionName;
  final String title;
  final Function(DocumentSnapshot) onItemTap;

  const _HistoryListView({
    required this.collectionName,
    required this.title,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text('Please log in to view history')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection(collectionName)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No items found'));
          }

          final items = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(item['title'] ?? 'Untitled'),
                  subtitle: Text(
                    '${item['words']?.toString() ?? '0'} Words • ${item['date'] ?? 'No date'}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm Delete'),
                          content: const Text('Are you sure you want to delete this item?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await _deleteItem(collectionName, item.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Item deleted')),
                        );
                      }
                    },
                  ),
                  onTap: () => onItemTap(item),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _deleteItem(String collectionName, String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // First get the document to check for audio file path
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection(collectionName)
          .doc(docId)
          .get();

      // Delete the document
      await doc.reference.delete();

      // If there's an audio file, delete it
      if (doc['audioFileName'] != null) {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/${doc['audioFileName']}');
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('Error deleting item: $e');
      rethrow;
    }
  }
}

class _HistoryItemView extends StatefulWidget {
  final String title;
  final String content;
  final String type;
  final String? audioPath;
  final String docId;

  const _HistoryItemView({
    required this.title,
    required this.content,
    required this.type,
    this.audioPath,
    required this.docId,
  });

  @override
  State<_HistoryItemView> createState() => _HistoryItemViewState();
}

class _HistoryItemViewState extends State<_HistoryItemView> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _fileExists = false;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
    _checkFileExistence();
  }

  Future<void> _initAudioPlayer() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.media,
          flags: AndroidAudioFlags.none,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ));

      _audioPlayer.playbackEventStream.listen((event) {},
          onError: (Object e, StackTrace st) {
            if (e is PlayerException) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${e.message}')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
            setState(() => _isPlaying = false);
          });

      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() => _isPlaying = false);
        }
      });
    } catch (e) {
      debugPrint('Error initializing audio session: $e');
    }
  }

  // In the _checkFileExistence method
  Future<void> _checkFileExistence() async {
    if (widget.audioPath == null) {
      setState(() => _fileExists = false);
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      // Look for the exact filename stored in Firestore
      File file = File('${directory.path}/${widget.audioPath}');
      bool exists = await file.exists();

      // If not found, try alternative patterns
      if (!exists) {
        // Try with just the timestamp part if the full path was stored
        final fileName = path.basename(widget.audioPath!);
        file = File('${directory.path}/$fileName');
        exists = await file.exists();
      }

      setState(() => _fileExists = exists);
    } catch (e) {
      debugPrint('Error checking file: $e');
      setState(() => _fileExists = false);
    }
  }

  Future<void> _togglePlayback() async {
    if (widget.audioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No audio file associated with this item')),
      );
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      File file = File('${directory.path}/${widget.audioPath}');

      // First try to play local file if it exists
      if (await file.exists()) {
        await _playLocalFile(file);
        return;
      }

      // If local file doesn't exist, try to download from Firebase
      final data = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection(widget.type == 'recording' ? 'recordings' :
      widget.type == 'tts' ? 'tts' : 'transcriptions')
          .doc(widget.docId)
          .get();

      if (data.exists) {
        // Use the correct field name here - 'audioFileName' instead of 'audioUrl'
        final audioFileName = data['audioFileName'];
        if (audioFileName != null) {
          file = File('${directory.path}/$audioFileName');
          if (await file.exists()) {
            await _playLocalFile(file);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Audio file not found locally')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No audio file associated with this item')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item not found in database')),
        );
      }
    } catch (e) {
      debugPrint('Playback error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Playback error: ${e.toString()}')),
      );
      setState(() => _isPlaying = false);
    }
  }

  Future<void> _playLocalFile(File file) async {
    await _audioPlayer.setAudioSource(
      AudioSource.uri(Uri.file(file.path)),
    );
    await _audioPlayer.setSpeed(_playbackSpeed);
    await _audioPlayer.play();
    setState(() => _isPlaying = true);
  }

  Future<void> _playFromUrl(String url) async {
    await _audioPlayer.setAudioSource(
      AudioSource.uri(Uri.parse(url)),
    );
    await _audioPlayer.setSpeed(_playbackSpeed);
    await _audioPlayer.play();
    setState(() => _isPlaying = true);
  }

  Future<void> _deleteItem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Delete the document from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection(widget.type == 'recording'
          ? 'recordings'
          : widget.type == 'tts'
          ? 'tts'
          : 'transcriptions')
          .doc(widget.docId)
          .delete();

      // If there's an audio file, delete it from storage
      if (widget.audioPath != null) {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/${widget.audioPath}');
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Show success message and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item deleted successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete item: $e')),
      );
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteItem,
            tooltip: 'Delete',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.audioPath != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Audio Player',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              size: 36,
                            ),
                            onPressed: _togglePlayback,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.audioPath!,
                                  style: TextStyle(
                                    color: _fileExists ? Colors.green : Colors.red,
                                  ),
                                ),
                                Text(
                                  _fileExists ? 'File exists' : 'File not found',
                                  style: TextStyle(
                                    color: _fileExists ? Colors.green : Colors.red,
                                  ),
                                ),
                                if (_fileExists) ...[
                                  FutureBuilder<File>(
                                    future: () async {
                                      final directory = await getApplicationDocumentsDirectory();
                                      return File('${directory.path}/${widget.audioPath}');
                                    }(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        return FutureBuilder<int>(
                                          future: snapshot.data!.length(),
                                          builder: (context, sizeSnapshot) {
                                            if (sizeSnapshot.hasData) {
                                              return Text(
                                                'Size: ${(sizeSnapshot.data! / 1024).toStringAsFixed(2)} KB',
                                                style: TextStyle(
                                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                                ),
                                              );
                                            }
                                            return const Text('Calculating size...');
                                          },
                                        );
                                      }
                                      return const Text('Checking file...');
                                    },
                                  ),
                                ],
                                Text('${_playbackSpeed}x'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Text Content',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      widget.content,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

