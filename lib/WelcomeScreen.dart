import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart'; // Add this import
import 'package:provider/provider.dart';
import 'LoginOptions.dart';
import 'theme_provider.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Enhanced blue gradient
    final blueGradient = LinearGradient(
      colors: [
        Colors.lightBlueAccent.shade400,
        Colors.blueAccent.shade700,
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.black,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Lottie animation container
                  Container(
                    height: 350,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Lottie.asset(
                      'assets/Robot.json', // Path to your Lottie JSON file
                      fit: BoxFit.contain,
                      repeat: true,
                      animate: true,
                      frameRate: FrameRate.max,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.smart_toy,
                          size: 100,
                          color: Colors.blueAccent.shade200,
                        );
                      },
                    ),
                  ),

                  // Title with reduced spacing
                  ShaderMask(
                    shaderCallback: (bounds) => blueGradient.createShader(bounds),
                    blendMode: BlendMode.srcIn,
                    child: const Text(
                      'Seamless Transcription with AI',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Button with tighter padding
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: blueGradient,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginOptions()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 30,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        shadowColor: Colors.transparent,
                      ),
                      child: ShaderMask(
                        shaderCallback: (bounds) => blueGradient.createShader(bounds),
                        blendMode: BlendMode.srcIn,
                        child: const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}