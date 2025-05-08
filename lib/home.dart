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
import 'dart:developer'; // For debugPrint
import 'settings.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart'; // Added for Clipboard

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
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });
  }

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
          audioPath: data?['audioFilePath'],
          audioDownloadUrl: data?['audioDownloadUrl'],
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
          audioPath: data?['audioFilePath'],
          audioDownloadUrl: data?['audioDownloadUrl'],
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
        backgroundColor:
        Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        selectedItemColor:
        Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor:
        Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
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
              color: Theme.of(context).cardTheme.shadowColor ??
                  Colors.black.withOpacity(0.1),
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
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTranscriptionCard(
      String title, String words, String date, DocumentSnapshot doc) {
    return GestureDetector(
      onTap: () => _viewTranscription(doc),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).cardTheme.shadowColor ??
                  Colors.black.withOpacity(0.1),
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
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTtsCard(
      String title, String words, String date, DocumentSnapshot doc) {
    return GestureDetector(
      onTap: () => _viewTTS(doc),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).cardTheme.shadowColor ??
                  Colors.black.withOpacity(0.1),
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
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: user != null
                  ? FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots()
                  : Stream<DocumentSnapshot>.empty(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return UserAccountsDrawerHeader(
                    accountName: const Text(
                      'Loading...',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    accountEmail: Text(
                      user?.email ?? 'No email',
                      style: const TextStyle(fontSize: 14),
                    ),
                    currentAccountPicture: const CircleAvatar(
                      backgroundColor: Colors.cyanAccent,
                      child: Text(
                        'L',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[900]
                          : Colors.blue[900],
                    ),
                  );
                }
                if (snapshot.hasError) {
                  debugPrint('Error fetching user data: ${snapshot.error}');
                  return UserAccountsDrawerHeader(
                    accountName: const Text(
                      'Error',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    accountEmail: Text(
                      user?.email ?? 'No email',
                      style: const TextStyle(fontSize: 14),
                    ),
                    currentAccountPicture: const CircleAvatar(
                      backgroundColor: Colors.cyanAccent,
                      child: Text(
                        'E',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[900]
                          : Colors.blue[900],
                    ),
                  );
                }

                final username = snapshot.hasData && snapshot.data!.exists
                    ? snapshot.data!['username'] ?? user?.displayName ?? 'Guest'
                    : user?.displayName ?? 'Guest';
                final photoUrl = snapshot.hasData && snapshot.data!.exists
                    ? snapshot.data!['photoUrl'] ?? user?.photoURL
                    : user?.photoURL;

                return UserAccountsDrawerHeader(
                  accountName: Text(
                    username,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  accountEmail: Text(
                    user?.email ?? 'No email',
                    style: const TextStyle(fontSize: 14),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.cyanAccent,
                    child: photoUrl != null
                        ? ClipOval(
                      child: Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        width: 64,
                        height: 64,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Error loading profile image: $error');
                          return Text(
                            user?.email?.substring(0, 1).toUpperCase() ??
                                'G',
                            style: const TextStyle(fontSize: 24),
                          );
                        },
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
                );
              },
            ),
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
            _buildDrawerSwitchItem(
              icon: Icons.brightness_6,
              text: 'Dark Mode',
              value: themeProvider.themeMode == ThemeMode.dark,
              onChanged: (value) {
                themeProvider.toggleTheme(value);
              },
            ),
            const Spacer(),
            _buildDrawerItem(
              icon: Icons.logout,
              text: 'Logout',
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginOptions()),
                );
              },
            ),
            const SizedBox(height: 32),
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
    return ListTile(
      leading: Icon(
        icon,
        size: 24,
        color: Theme.of(context).iconTheme.color,
      ),
      title: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildDrawerSwitchItem({
    required IconData icon,
    required String text,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        size: 24,
        color: Theme.of(context).iconTheme.color,
      ),
      title: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue,
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
                          content:
                          const Text('Are you sure you want to delete this item?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete',
                                  style: TextStyle(color: Colors.red)),
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
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection(collectionName)
          .doc(docId)
          .get();

      await doc.reference.delete();

      if (doc['audioDownloadUrl'] != null) {
        final storageRef =
        FirebaseStorage.instance.refFromURL(doc['audioDownloadUrl']);
        await storageRef.delete();
        debugPrint(
            'Deleted audio file from Firebase Storage: ${doc['audioDownloadUrl']}');
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
  final String? audioDownloadUrl;
  final String docId;

  const _HistoryItemView({
    required this.title,
    required this.content,
    required this.type,
    this.audioPath,
    this.audioDownloadUrl,
    required this.docId,
  });

  @override
  State<_HistoryItemView> createState() => _HistoryItemViewState();
}

class _HistoryItemViewState extends State<_HistoryItemView> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _canPlayAudio = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
  }

  Future<void> _setupAudioPlayer() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.speech());

    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });

    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    _audioPlayer.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration ?? Duration.zero;
        });
      }
    });

    bool audioLoaded = false;

    // Load audio from audioDownloadUrl
    if (widget.audioDownloadUrl != null) {
      try {
        await _audioPlayer.setUrl(widget.audioDownloadUrl!);
        debugPrint('Loaded audio from URL: ${widget.audioDownloadUrl}');
        audioLoaded = true;
      } catch (e) {
        debugPrint('Error loading audio from URL: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load audio from cloud: $e')),
        );
      }
    } else {
      debugPrint('No audioDownloadUrl provided');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio file is missing or was not uploaded to the cloud')),
      );
    }

    setState(() {
      _canPlayAudio = audioLoaded;
    });

    if (!audioLoaded && widget.audioDownloadUrl != null) {
      // Only show this if we tried to load a URL and failed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No playable audio source available')),
      );
    }
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

      if (widget.audioDownloadUrl != null) {
        final storageRef =
        FirebaseStorage.instance.refFromURL(widget.audioDownloadUrl!);
        await storageRef.delete();
        debugPrint(
            'Deleted audio file from Firebase Storage: ${widget.audioDownloadUrl}');
      }

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

  Future<void> _playPauseAudio() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  Future<void> _seekAudio(double value) async {
    final position = Duration(seconds: value.toInt());
    await _audioPlayer.seek(position);
  }

  Future<void> _copyText() async {
    await Clipboard.setData(ClipboardData(text: widget.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Text copied to clipboard')),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
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
            // Show Audio Playback section if audioDownloadUrl is available
            if (widget.audioDownloadUrl != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Audio Playback',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              size: 32,
                            ),
                            onPressed: _canPlayAudio ? _playPauseAudio : null,
                          ),
                        ],
                      ),
                      Slider(
                        value: _position.inSeconds.toDouble(),
                        min: 0.0,
                        max: _duration.inSeconds.toDouble() > 0
                            ? _duration.inSeconds.toDouble()
                            : 1.0,
                        onChanged: _canPlayAudio
                            ? (value) {
                          _seekAudio(value);
                        }
                            : null,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(_position)),
                          Text(_formatDuration(_duration)),
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
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy Text'),
                        onPressed: _copyText,
                      ),
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