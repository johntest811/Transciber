import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'Login.dart';
import 'Register.dart';
import 'home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginOptions(),
    );
  }
}

class LoginOptions extends StatelessWidget {
  const LoginOptions({super.key});

  //Google Login
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Ensure a fresh sign-in by signing out first
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        print("Google Sign-In Cancelled");
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      print("Signed in as: ${userCredential.user?.displayName}");
      return userCredential;
    } catch (e) {
      print("Google Sign-In Error: $e");
      return null;
    }
  }


  // tokenString

  //Faccebook Firebase
  Future<UserCredential?> signInWithFacebook(BuildContext context) async {
    try {
      print("Attempting Facebook login...");
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success || result.accessToken == null) {
        print("Facebook Login Failed: ${result.status}");
        return null;
      }

      final AccessToken accessToken = result.accessToken!;
      final OAuthCredential credential = FacebookAuthProvider.credential(accessToken.tokenString);

      // Get Facebook user details
      final userData = await FacebookAuth.instance.getUserData();
      final String? email = userData['email'];
      final String? name = userData['name'];
      final String? profilePic = userData['picture']['data']['url'];

      print("Facebook Email: $email");

      if (email != null) {
        // Check if an account with this email already exists in Firebase
        final List<String> signInMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
        print("Existing sign-in methods: $signInMethods");

        if (signInMethods.isNotEmpty && !signInMethods.contains("facebook.com")) {
          print("This email is already associated with another sign-in method: ${signInMethods.join(", ")}");
          return null; // Prevent account merging
        }
      }

      // Proceed with Facebook authentication
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        print("Facebook Login Success: ${userCredential.user?.displayName}");
        print("Profile Picture: $profilePic");

        // Navigate to Home only if authentication is successful
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Home()),
        );
      }

      return userCredential;
    } catch (e) {
      print("Facebook Sign-In Error: $e");
      return null;
    }
  }








  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Transcify',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                  fontFamily: 'Cursive',
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Get Started',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                "It's easier to sign up now",
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 30),
              _socialButton('Continue with Facebook', Colors.blue, 'images/facebook.png',
                onPressed: () async {
                  final userCredential = await signInWithFacebook(context); // Pass context here
                  if (userCredential != null) {
                    print("Navigating to Home...");
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => Home()),
                    );
                  } else {
                    print("Facebook Sign-In failed.");
                  }
                },
              ),




              //Kung gusto Edit yung button para sa Facebook
              SizedBox(height: 10),
              Text("or", style: TextStyle(color: Colors.white70)),
              SizedBox(height: 10),
              _socialButton('Continue with Google', Colors.white, 'images/google.png', textColor: Colors.black,

                onPressed: () async {
                  final userCredential = await signInWithGoogle();
                  if (userCredential != null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => Home()),
                    );
                  } else {
                    print("Google Sign-In failed");
                  }
                },
              ),
              //Kung gusto Edit yung button para sa Facebook
              SizedBox(height: 10),
              Text("or", style: TextStyle(color: Colors.white70)),
              SizedBox(height: 10),
              _registerButton(),
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: Text(
                  'Already have an account? Login',
                  style: TextStyle(color: Colors.white70, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _socialButton(String text, Color color, String imagePath, {Color textColor = Colors.white, VoidCallback? onPressed}) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(imagePath, height: 24, width: 24),
        SizedBox(width: 10),
        Text(text, style: TextStyle(color: textColor)),
      ],
    ),
  );
}

Widget _registerButton() {
  return Builder(
    builder: (context) => ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RegisterScreen()),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 40),
      ),
      child: Text('Register', style: TextStyle(color: Colors.black)),
    ),
  );
}
