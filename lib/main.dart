import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'LoginOptions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Add this line
  runApp(const MyApp());
}


// void main() async{
//   WidgetsFlutterBinding.ensureInitialized();
//   // await Firebase.initializeApp();
//   runApp(MyApp());
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginOptions(), // First screen to open
    );
  }
}
