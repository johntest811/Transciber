import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class AssemblyAIService {
  static const String _baseUrl = 'https://api.assemblyai.com/v2';
  static const String _apiKey = '67a1b50161bb48c5a6a460adffdf6976'; // Get free API key from https://www.assemblyai.com/

  Future<String> uploadAudioFile(File audioFile) async {
    final uri = Uri.parse('$_baseUrl/upload');
    final request = http.MultipartRequest('POST', uri)
      ..headers['authorization'] = _apiKey
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        audioFile.path,
      ));

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final jsonResponse = jsonDecode(responseData);

    if (response.statusCode != 200) {
      throw Exception('Upload failed: ${jsonResponse['error']}');
    }

    return jsonResponse['upload_url'];
  }

  Future<String> transcribeAudio(String audioUrl) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/transcript'),
      headers: {
        'authorization': _apiKey,
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'audio_url': audioUrl,
      }),
    );

    final responseData = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception('Transcription failed: ${responseData['error']}');
    }

    final transcriptId = responseData['id'];
    return await _pollForTranscription(transcriptId);
  }

  Future<String> _pollForTranscription(String transcriptId) async {
    final uri = Uri.parse('$_baseUrl/transcript/$transcriptId');

    while (true) {
      final response = await http.get(uri, headers: {'authorization': _apiKey});
      final responseData = jsonDecode(response.body);

      if (responseData['status'] == 'completed') {
        return responseData['text'];
      } else if (responseData['status'] == 'error') {
        throw Exception('Transcription error: ${responseData['error']}');
      }

      await Future.delayed(const Duration(seconds: 1));
    }
  }
}