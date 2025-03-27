import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';

class TranscriberPage extends StatefulWidget {
  @override
  _TranscriberPageState createState() => _TranscriberPageState();
}

class _TranscriberPageState extends State<TranscriberPage> {
  stt.SpeechToText speech = stt.SpeechToText();
  bool isListening = false;
  String liveTranscription = "Press the button and start speaking...";
  String fileTranscription = "";

  @override
  void initState() {
    super.initState();
    speech.initialize();
  }

  void startListening() async {
    if (!isListening) {
      isListening = true;
      speech.listen(
        onResult: (result) {
          setState(() {
            liveTranscription = result.recognizedWords;
          });
        },
      );
    }
  }

  void stopListening() {
    speech.stop();
    setState(() {
      isListening = false;
    });
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);

    if (result != null) {
      File file = File(result.files.single.path!);
      transcribeFile(file);
    }
  }

  Future<void> transcribeFile(File file) async {
    String apiKey = "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";  // Replace with your OpenAI API Key
    var request = http.MultipartRequest('POST', Uri.parse("https://api.openai.com/v1/audio/transcriptions"))
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..headers['Content-Type'] = 'multipart/form-data'
      ..files.add(await http.MultipartFile.fromPath('file', file.path))
      ..fields['model'] = 'whisper-1';

    var response = await request.send();
    var responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      setState(() {
        fileTranscription = jsonDecode(responseData)['text'];
      });
    } else {
      print("Error: ${response.statusCode} - $responseData");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Speech & File Transcriber")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(liveTranscription, style: TextStyle(fontSize: 18)),
            ElevatedButton(
              onPressed: isListening ? stopListening : startListening,
              child: Text(isListening ? "Stop Listening" : "Start Listening"),
            ),
            Divider(),
            Text(fileTranscription, style: TextStyle(fontSize: 18)),
            ElevatedButton(
              onPressed: pickFile,
              child: Text("Pick an Audio File"),
            ),
          ],
        ),
      ),
    );
  }
}
