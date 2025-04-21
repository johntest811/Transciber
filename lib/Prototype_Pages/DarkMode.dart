// import 'package:flutter/material.dart';
// import 'FileToText_page.dart';
// import 'TextToVoice_page.dart';
// import 'VoiceToText_page.dart';
//
//
// void main() {
//   runApp(const Home());
// }
//
// class Home extends StatelessWidget {
//   const Home({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Trancify',
//       theme: ThemeData.dark().copyWith(
//         // Custom dark theme settings
//         scaffoldBackgroundColor: const Color(0xFF121212),
//         appBarTheme: const AppBarTheme(
//           backgroundColor: Color(0xFF1E1E1E),
//           elevation: 0,
//           iconTheme: IconThemeData(color: Colors.white),
//           titleTextStyle: TextStyle(
//             color: Colors.white,
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         cardTheme: CardTheme(
//           color: const Color(0xFF1E1E1E),
//           elevation: 2,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//         ),
//         bottomNavigationBarTheme: const BottomNavigationBarThemeData(
//           backgroundColor: Color(0xFF1E1E1E),
//           selectedItemColor: Colors.blueAccent,
//           unselectedItemColor: Colors.grey,
//         ),
//         drawerTheme: const DrawerThemeData(
//           backgroundColor: Color(0xFF1E1E1E),
//         ),
//       ),
//       home: const HomePage(),
//       debugShowCheckedModeBanner: false,
//       routes: {
//         '/file-to-text': (context) => FiletotextPage(),
//         '/text-to-voice': (context) => TexttovoicePage(),
//         '/voice-to-text': (context) => VoicetotextPage(),
//       },
//     );
//   }
// }
//
// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   int _currentIndex = 1;
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//
//   final List<Map<String, dynamic>> recordings = [
//     {'title': 'Voice 02', 'date': 'Feb 15'},
//     {'title': 'Voice 01', 'date': 'Feb 10'},
//     {'title': 'Voice 03', 'date': 'Feb 20'},
//   ];
//
//   final List<Map<String, dynamic>> transcriptions = [
//     {'title': 'Design Inspiration', 'words': '3300', 'date': 'Feb 10'},
//     {'title': 'Food Recipe', 'words': '8600', 'date': 'Feb 18'},
//     {'title': 'Voice 01', 'words': '8300', 'date': 'Feb 19'},
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey,
//       appBar: AppBar(
//         title: const Text('Welcome to Resolve'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.search),
//             onPressed: () {},
//           ),
//         ],
//       ),
//       drawer: _buildDrawer(),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Recordings Section
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     'Recordings',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   TextButton(
//                     onPressed: () {},
//                     child: const Text('See all'),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 10),
//               SizedBox(
//                 height: 120,
//                 child: ListView.builder(
//                   scrollDirection: Axis.horizontal,
//                   itemCount: recordings.length,
//                   itemBuilder: (context, index) {
//                     return Container(
//                       width: 150,
//                       margin: const EdgeInsets.only(right: 15),
//                       decoration: BoxDecoration(
//                         color: Theme.of(context).cardTheme.color,
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(12.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               recordings[index]['title'],
//                               style: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 16),
//                             ),
//                             const Spacer(),
//                             Text(
//                               recordings[index]['date'],
//                               style: TextStyle(
//                                   color: Colors.grey[400]),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               const SizedBox(height: 30),
//               // Transcriptions Section
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     'Transcriptions',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   TextButton(
//                     onPressed: () {},
//                     child: const Text('See all'),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 10),
//               Column(
//                 children: transcriptions.map((transcription) {
//                   return Card(
//                     child: ListTile(
//                       title: Text(
//                         transcription['title'],
//                         style: const TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       subtitle: Text(
//                         '${transcription['words']} Words • ${transcription['date']}',
//                         style: TextStyle(color: Colors.grey[400]),
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ],
//           ),
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _currentIndex,
//         onTap: (index) {
//           setState(() => _currentIndex = index);
//           switch (index) {
//             case 0: Navigator.pushNamed(context, '/text-to-voice'); break;
//             case 1: Navigator.pushNamed(context, '/voice-to-text'); break;
//             case 2: Navigator.pushNamed(context, '/file-to-text'); break;
//           }
//         },
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.text_snippet),
//             label: 'Text to Voice',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.mic),
//             label: 'Voice to Text',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.insert_drive_file),
//             label: 'File to Text',
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildDrawer() {
//     return Drawer(
//       child: Container(
//         color: Theme.of(context).drawerTheme.backgroundColor,
//         child: Column(
//           children: [
//             const DrawerHeader(
//               child: Center(
//                 child: Text(
//                   'Resolve',
//                   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ),
//             Expanded(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   _buildDrawerItem(
//                     icon: Icons.insert_drive_file,
//                     text: 'File to Text',
//                     onTap: () => _navigateTo('/file-to-text'),
//                   ),
//                   _buildDrawerItem(
//                     icon: Icons.mic,
//                     text: 'Voice to Text',
//                     onTap: () => _navigateTo('/voice-to-text'),
//                   ),
//                   _buildDrawerItem(
//                     icon: Icons.text_snippet,
//                     text: 'Text to Voice',
//                     onTap: () => _navigateTo('/text-to-voice'),
//                   ),
//                 ],
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.only(bottom: 20.0),
//               child: _buildDrawerItem(
//                 icon: Icons.home,
//                 text: 'Home',
//                 onTap: () => Navigator.pop(context),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _navigateTo(String route) {
//     Navigator.pop(context);
//     Navigator.pushNamed(context, route);
//   }
//
//   Widget _buildDrawerItem({
//     required IconData icon,
//     required String text,
//     required VoidCallback onTap,
//   }) {
//     return ListTile(
//       leading: Icon(icon, size: 30),
//       title: Text(
//         text,
//         style: const TextStyle(fontSize: 18),
//       ),
//       onTap: onTap,
//     );
//   }
// }
//
