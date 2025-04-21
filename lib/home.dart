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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _HistoryItemView(
          title: recording['title'],
          content: recording['text'],
          type: 'recording',
          audioPath: recording['audioPath'],
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
        ),
      ),
    );
  }

  void _viewTTS(DocumentSnapshot tts) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _HistoryItemView(
          title: tts['title'],
          content: tts['text'],
          type: 'tts',
          audioPath: tts['audioPath'],
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
                      // TODO: Implement see all recordings
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
                      // TODO: Implement see all transcriptions
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
                      // TODO: Implement see all TTS
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

class _HistoryItemView extends StatefulWidget {
  final String title;
  final String content;
  final String type;
  final String? audioPath;

  const _HistoryItemView({
    required this.title,
    required this.content,
    required this.type,
    this.audioPath,
  });

  @override
  State<_HistoryItemView> createState() => _HistoryItemViewState();
}

class _HistoryItemViewState extends State<_HistoryItemView> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
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
  }

  Future<void> _togglePlayback() async {
    if (widget.audioPath == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_audioPlayer.processingState == ProcessingState.completed) {
          await _audioPlayer.seek(Duration.zero);
        }
        if (_audioPlayer.processingState == ProcessingState.idle) {
          await _audioPlayer.setAudioSource(
            AudioSource.uri(Uri.file(widget.audioPath!)),
          );
        }
        await _audioPlayer.play();
      }
      setState(() {
        _isPlaying = !_isPlaying;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing audio: $e')),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.audioPath != null) ...[
              Row(
                children: [
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: _togglePlayback,
                  ),
                  const Text('Play Audio'),
                ],
              ),
              const SizedBox(height: 20),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SelectableText(
                  widget.content,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}