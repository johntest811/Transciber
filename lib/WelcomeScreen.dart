import 'package:flutter/material.dart';
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black!,
              Colors.black!,
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
                  // Image with reduced bottom margin
                  Container(
                    height: 350, // Slightly reduced height
                    margin: const EdgeInsets.only(bottom: 10), // Reduced from 40
                    child: Image.asset(
                      'images/Robot.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.low,
                      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                        if (frame == null) {
                          return Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(Colors.blueAccent),
                            ),
                          );
                        }
                        return child;
                      },
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
                        height: 1.2, // Tighter line height
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 20), // Reduced from 40

                  // Button with tighter padding
                  Container(
                    margin: const EdgeInsets.only(top: 20), // Added top margin instead of SizedBox
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
                          vertical: 14, // Reduced from 18
                          horizontal: 30, // Reduced from 36
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
                            fontSize: 16, // Slightly smaller
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