import 'package:flutter/material.dart';
import 'whisper_service.dart';

class LiveTranscriber extends StatefulWidget {
  final Function(String, bool) onTextUpdate;

  LiveTranscriber({required this.onTextUpdate});

  @override
  _LiveTranscriberState createState() => _LiveTranscriberState();
}

class _LiveTranscriberState extends State<LiveTranscriber> {
  String liveText = "Listening...";
  final WhisperService whisperService = WhisperService();
  bool isCompleted = false;

  void startLiveTranscription() async {
    for (int i = 0; i < 5; i++) { // Simulating 5 rounds of live transcription
      await Future.delayed(Duration(seconds: 3));
      if (!mounted) return;

      setState(() {
        liveText = "Live speech detected at ${DateTime.now()}";
      });

      widget.onTextUpdate(liveText, false);
    }

    setState(() {
      liveText = "Final Transcription: \"Live transcription complete.\"";
      isCompleted = true;
    });

    widget.onTextUpdate(liveText, true);
  }

  @override
  void initState() {
    super.initState();
    startLiveTranscription();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Live Transcription")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(liveText, style: TextStyle(fontSize: 18)),
            if (isCompleted)
              Text("✔ Live Transcription Completed!", style: TextStyle(color: Colors.green)),
          ],
        ),
      ),
    );
  }
}
