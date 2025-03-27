import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class WhisperService {
  static const String apiKey = "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";
  static const String apiUrl = "https://api.openai.com/v1/audio/transcriptions";
  static const String translationApiUrl = "https://api.openai.com/v1/chat/completions";

  Future<String> transcribeFile(File audioFile) async {
    var request = http.MultipartRequest('POST', Uri.parse(apiUrl))
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..headers['Content-Type'] = 'multipart/form-data'
      ..files.add(await http.MultipartFile.fromPath('file', audioFile.path))
      ..fields['model'] = 'whisper-1';

    try {
      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        String text = jsonDecode(responseData)['text'];
        return text;
      } else {
        print("Error: ${response.statusCode}");
        print("Response: $responseData");
        throw Exception("Failed to transcribe audio: $responseData");
      }
    } catch (e) {
      print("Exception: $e");
      throw Exception("Failed to transcribe audio: $e");
    }
  }


  Future<String> translateText(String text) async {
    var response = await http.post(
      Uri.parse(translationApiUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "gpt-4",
        "messages": [
          {"role": "system", "content": "Translate the following text to English:"},
          {"role": "user", "content": text}
        ]
      }),
    );

    if (response.statusCode == 200) {
      var responseData = jsonDecode(response.body);
      return responseData['choices'][0]['message']['content'];
    } else {
      throw Exception("Failed to translate text");
    }
  }
}
