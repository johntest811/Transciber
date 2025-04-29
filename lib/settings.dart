import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _usernameController;
  String? _profileImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        _usernameController.text = userDoc['username'] ?? user.displayName ?? '';
        _profileImageUrl = userDoc['photoUrl'] ?? user.photoURL;
      } else {
        _usernameController.text = user.displayName ?? '';
        _profileImageUrl = user.photoURL;
      }
    } catch (e) {
      _usernameController.text = user.displayName ?? '';
      _profileImageUrl = user.photoURL;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _isLoading = true);

        final user = _auth.currentUser;
        if (user == null) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must be logged in to update your profile image')),
          );
          return;
        }

        // Refresh the user's token and log user details
        await user.getIdToken(true);
        debugPrint('User UID: ${user.uid}');
        debugPrint('User email: ${user.email}');
        debugPrint('User token: ${await user.getIdToken()}');

        final file = File(pickedFile.path);
        final fileName = 'profile_${user.uid}${path.extension(file.path)}';
        final ref = _storage.ref().child('profile_images/$fileName');
        debugPrint('Uploading to Firebase Storage path: profile_images/$fileName');

        await ref.putFile(file);
        final downloadUrl = await ref.getDownloadURL();

        await user.updatePhotoURL(downloadUrl);
        await _firestore.collection('users').doc(user.uid).set({
          'photoUrl': downloadUrl,
          'username': _usernameController.text.trim(),
          'email': user.email,
          'uid': user.uid,
        }, SetOptions(merge: true));

        // Reload the user to ensure photoURL is updated
        await user.reload();
        final updatedUser = _auth.currentUser;
        debugPrint('Updated user photoURL: ${updatedUser?.photoURL}');

        setState(() {
          _profileImageUrl = downloadUrl;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      String errorMessage = 'Error updating image: $e';
      if (e.toString().contains('unauthorized')) {
        errorMessage = 'You do not have permission to upload images. Please ensure you are logged in with the correct account or contact support.';
      }
      debugPrint('Image upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  Future<void> _updateUsername() async {
    try {
      setState(() => _isLoading = true);
      final user = _auth.currentUser;
      if (user == null) return;

      final newUsername = _usernameController.text.trim();
      if (newUsername.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username cannot be empty')),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Update the display name in Firebase Authentication
      await user.updateDisplayName(newUsername);

      // Update the username in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'username': newUsername,
        'email': user.email,
        'uid': user.uid,
      }, SetOptions(merge: true));

      // Refresh the user to ensure the updated display name is reflected
      await user.reload();
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username updated')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating username: $e')),
      );
    }
  }

  Future<void> _deleteAllHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      setState(() => _isLoading = true);

      // Delete all documents in the user's recordings, transcriptions, and tts collections
      final collections = ['recordings', 'transcriptions', 'tts'];
      for (final collection in collections) {
        final querySnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection(collection)
            .get();
        for (final doc in querySnapshot.docs) {
          // Safely access the document data
          final data = doc.data();
          // Check if audioFilePath exists and is not null
          if (data.containsKey('audioFilePath') && data['audioFilePath'] != null) {
            final file = File(data['audioFilePath']);
            if (await file.exists()) {
              await file.delete();
            }
          }
          await doc.reference.delete();
        }
      }

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All history deleted successfully')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting history: $e')),
      );
    }
  }

  Future<void> _clearAllHistory() async {
    // First confirmation dialog
    final firstConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Clear All History'),
        content: const Text(
            'Are you sure you want to delete all your recordings, transcriptions, and TTS conversions? This action cannot be undone.'),
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

    if (firstConfirmed != true) return;

    // Second confirmation dialog
    final secondConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text(
            'This is your final confirmation. Are you absolutely sure you want to clear all history? This action is irreversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (secondConfirmed == true) {
      await _deleteAllHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: Text('Please log in to access settings')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!)
                        : null,
                    child: _profileImageUrl == null
                        ? const Icon(Icons.person, size: 60)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _updateUsername,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Account',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: Text(user.email ?? 'No email'),
            ),
            ListTile(
              leading: const Icon(Icons.verified_user),
              title: const Text('Account Status'),
              subtitle: Text(user.emailVerified ? 'Verified' : 'Not verified'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Danger Zone',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Clear All History',
                  style: TextStyle(color: Colors.red)),
              subtitle: const Text(
                  'Delete all your recordings, transcriptions and TTS conversions'),
              onTap: _clearAllHistory,
            ),
          ],
        ),
      ),
    );
  }
}