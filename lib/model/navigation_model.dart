import 'package:flutter/material.dart';
import '../pages/dashboard_page.dart';
import '../pages/recordings_page.dart';
import '../pages/transcription_page.dart';
import '../pages/settings_page.dart';
import '../pages/profile_page.dart';
import '../pages/logout_page.dart';

class NavigationModel {
  final String title;
  final IconData icon;
  final Widget page;

  NavigationModel({required this.title, required this.icon, required this.page});
}

List<NavigationModel> navigationItems = [
  NavigationModel(title: "Dashboard", icon: Icons.insert_chart, page: DashboardPage()),
  NavigationModel(title: "Recordings", icon: Icons.keyboard_voice_rounded, page: RecordingsPage()),
  NavigationModel(title: "Transcription", icon: Icons.list_alt, page: TranscriptionPage()),
  NavigationModel(title: "Settings", icon: Icons.settings, page: SettingsPage()),
  NavigationModel(title: "Profile", icon: Icons.person, page: ProfilePage()),
  NavigationModel(title: "Logout", icon: Icons.logout, page: LogoutPage()),
];
