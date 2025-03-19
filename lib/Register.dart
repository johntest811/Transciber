import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Login.dart';
import 'Home.dart';
import 'SuccessScreen.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String? _errorMessage;


  Future<void> _register() async {
    setState(() {
      _errorMessage = null;
      _isLoading = false; // Set loading state to true at the start
    });

    String firstName = _firstNameController.text.trim();
    String lastName = _lastNameController.text.trim();
    String username = _usernameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = "Please fill in all fields.";
        _isLoading = false;
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = "Passwords do not match.";
        _isLoading = false;
      });
      return;
    }

    try {
      print("Attempting to register user...");

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print("User registered successfully: ${userCredential.user?.uid}");

      if (userCredential.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SuccessScreen()),
        );
        await _firestore.collection("users").doc(userCredential.user!.uid).set({
          'firstName': firstName,
          'lastName': lastName,
          'username': username,
          'email': email,
          'createdAt': Timestamp.now(),


        });

      }
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.message}");
      if (mounted) {
        setState(() {
          _errorMessage = e.message ?? "Registration failed. Please try again.";
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Unexpected error: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Something went wrong. Please try again.";
          _isLoading = false; // Ensure this is set
        });
      }
    }

  }


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




  //Faccebook
  Future<UserCredential?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success || result.accessToken == null) {
        throw FirebaseAuthException(
          code: "MISSING_FACEBOOK_TOKEN",
          message: "Facebook authentication failed. Missing token.",
        );
      }

      final AccessToken accessToken = result.accessToken!;
      final OAuthCredential credential = FacebookAuthProvider.credential(accessToken.tokenString);


      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print("Facebook Sign-In Error: $e");
      return null;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          color: Colors.transparent,
                        ),
                        child: const Center(
                          child: Icon(Icons.arrow_back, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Text(
                'Transcify',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.cyanAccent, fontFamily: 'Cursive'),
              ),
              const SizedBox(height: 20),
              const Text(
                'Get Started For Free',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Text("Create your account", style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(child: _inputField(_firstNameController, 'First Name')),
                  const SizedBox(width: 10),
                  Expanded(child: _inputField(_lastNameController, 'Last Name')),
                ],
              ),
              _inputField(_usernameController, 'Username', icon: Icons.person),
              _inputField(_emailController, 'Email', icon: Icons.email),
              _inputField(_passwordController, 'Password', icon: Icons.lock, obscureText: true),
              _inputField(_confirmPasswordController, 'Confirm Password', icon: Icons.lock, obscureText: true),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 14)),
                ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('Register', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 10),
              const Text("Or sign in with", style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 10),

             //Google and Facebook
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _socialButton(' Google   ', Colors.white, 'images/google.png',
                      textColor: Colors.black, onPressed: () async {
                        final userCredential = await signInWithGoogle();
                        if (userCredential != null) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => Home()),
                          );
                        } else {
                          print("Google Sign-In failed");
                        }
                      }),
                  const SizedBox(width: 10),
                  _socialButton('Facebook', Colors.blue, 'images/facebook.png',
                      onPressed: () async {
                        final userCredential = await signInWithFacebook();
                        if (userCredential != null) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => Home()),
                          );
                        } else {
                          print("Facebook Sign-In failed");
                        }
                      }),
                ],
              ),



              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen())),
                child: const Text(
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

  Widget _inputField(TextEditingController controller, String hint, {IconData? icon, bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white70),
          prefixIcon: icon != null ? Icon(icon, color: Colors.white70) : null,
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _socialButton(String text, Color color, String imagePath,
      {Color textColor = Colors.white, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(imagePath, height: 24, width: 24),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(color: textColor)),
        ],
      ),
    );
  }

}
