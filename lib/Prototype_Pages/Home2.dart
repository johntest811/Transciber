// import 'package:flutter/material.dart';
// import 'package:transcriber/pages/recordings_page.dart';
// import '../common/collapsing_navigation_drawer.dart';
// import 'package:transcriber/pages/transcription_page.dart';
// import 'package:transcriber/pages/recordings_detail_page.dart';
// import 'package:transcriber/pages/transcription_details_page.dart';
//
// void main() {
//   runApp(MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData.dark(),
//       home: HomeScreen(),
//     );
//   }
// }
//
// class HomeScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         title: Text("Welcome to Transify", style: TextStyle(color: Colors.blue)),
//         backgroundColor: Colors.black,
//         elevation: 0,
//       ),
//       drawer: CollapsingNavigationDrawer(),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             SectionHeader(title: "Recordings", onTap: () {
//               Navigator.push(context, MaterialPageRoute(builder: (context) => RecordingsPage()));
//             }),
//             SizedBox(height: 10),
//             RecordingsList(),
//             SizedBox(height: 20),
//             SectionHeader(title: "Transcriptions", onTap: () {
//               Navigator.push(context, MaterialPageRoute(builder: (context) => TranscriptionPage()));
//             }),
//             SizedBox(height: 10),
//             Expanded(child: TranscriptionsList()),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class SectionHeader extends StatelessWidget {
//   final String title;
//   final VoidCallback onTap;
//
//   const SectionHeader({required this.title, required this.onTap});
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(title, style: TextStyle(color: Colors.blue, fontSize: 18, fontWeight: FontWeight.bold)),
//         GestureDetector(
//           onTap: onTap,
//           child: Text("See all", style: TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.bold)),
//         ),
//       ],
//     );
//   }
// }
//
// class RecordingsList extends StatelessWidget {
//   final List<String> recordings = ["Voice 01", "Voice 02", "Voice 03", "Voice 04"];
//
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 100, // Ensures the list is horizontal but not too big
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         itemCount: recordings.length,
//         itemBuilder: (context, index) {
//           return Padding(
//             padding: const EdgeInsets.only(right: 12.0),
//             child: RecordingButton(title: recordings[index]),
//           );
//         },
//       ),
//     );
//   }
// }
//
// class RecordingButton extends StatelessWidget {
//   final String title;
//
//   const RecordingButton({required this.title});
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(context, MaterialPageRoute(builder: (context) => RecordingsDetailsPage()));
//       },
//       child: Container(
//         width: 100,
//         padding: EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.grey[900],
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: Colors.white, width: 1),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.mic, color: Colors.white, size: 30),
//             SizedBox(height: 5),
//             Text(title, style: TextStyle(color: Colors.blue, fontSize: 14), textAlign: TextAlign.center),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class TranscriptionsList extends StatelessWidget {
//   final List<Map<String, String>> transcriptions = [
//     {"title": "Design Inspiration", "duration": "00:03:00", "words": "407 Words", "date": "Feb 10"},
//     {"title": "Food Recipe", "duration": "00:08:00", "words": "1024 Words", "date": "Feb 16"},
//     {"title": "Podcast Episode", "duration": "00:15:00", "words": "2045 Words", "date": "Feb 20"},
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return ListView.builder(
//       itemCount: transcriptions.length,
//       itemBuilder: (context, index) {
//         return Padding(
//           padding: const EdgeInsets.only(bottom: 10.0),
//           child: TranscriptionCard(
//             title: transcriptions[index]["title"]!,
//             duration: transcriptions[index]["duration"]!,
//             words: transcriptions[index]["words"]!,
//             date: transcriptions[index]["date"]!,
//           ),
//         );
//       },
//     );
//   }
// }
//
// class TranscriptionCard extends StatelessWidget {
//   final String title;
//   final String duration;
//   final String words;
//   final String date;
//
//   const TranscriptionCard({required this.title, required this.duration, required this.words, required this.date});
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(context, MaterialPageRoute(builder: (context) => TranscriptionDetailsPage()));
//       },
//       child: Container(
//         padding: EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.grey[800],
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: Colors.white, width: 1),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.article, color: Colors.white, size: 30),
//                 SizedBox(width: 10),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(title, style: TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold)),
//                     SizedBox(height: 5),
//                     Text("$duration | $words", style: TextStyle(color: Colors.blue, fontSize: 14)),
//                   ],
//                 ),
//               ],
//             ),
//             Text(date, style: TextStyle(color: Colors.blue, fontSize: 14)),
//           ],
//         ),
//       ),
//     );
//   }
// }
