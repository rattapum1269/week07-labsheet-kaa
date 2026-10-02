import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // ดึง API Key ผ่าน --dart-define เท่านั้น (ไม่มีการ Hardcode คีย์ลงในโค้ด)
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  // รายชื่อโมเดลมาตรฐานสำหรับวิเคราะห์ข้อความ
  static const List<String> _candidateModels = [
    'gemini-1.5-flash',
    'gemini-1.5-pro',
    'gemini-2.0-flash',
  ];

  Future<String> generateText(String prompt) async {
    final cleanKey = _apiKey.trim();

    if (cleanKey.isEmpty) {
      throw Exception(
        'ไม่พบ API Key! กรุณาระบุ GEMINI_API_KEY ผ่าน --dart-define',
      );
    }

    final Map<String, String> headers = {'Content-Type': 'application/json'};

    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
    });

    String lastError = '';

    for (final model in _candidateModels) {
      Uri url;

      // จัดการ Header ตามประเภท Key (AQ. vs AIzaSy)
      if (cleanKey.startsWith('AQ.')) {
        headers['Authorization'] = 'Bearer $cleanKey';
        url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
        );
      } else {
        headers['x-goog-api-key'] = cleanKey;
        url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$cleanKey',
        );
      }

      try {
        final response = await http
            .post(url, headers: headers, body: requestBody)
            .timeout(
              const Duration(seconds: 20),
              onTimeout: () => throw Exception('หมดเวลาเชื่อมต่อ (20 วินาที)'),
            );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['candidates'] != null &&
              data['candidates'].isNotEmpty &&
              data['candidates'][0]['content'] != null &&
              data['candidates'][0]['content']['parts'] != null &&
              data['candidates'][0]['content']['parts'].isNotEmpty) {
            return data['candidates'][0]['content']['parts'][0]['text']
                as String;
          } else {
            throw Exception('ไม่พบข้อมูลคำตอบจากเซิร์ฟเวอร์');
          }
        } else if (response.statusCode == 503 ||
            response.statusCode == 429 ||
            response.statusCode == 404) {
          lastError =
              'Model $model (Status: ${response.statusCode})\n${response.body}';
          continue;
        } else {
          throw Exception(
            'เกิดข้อผิดพลาดจากเซิร์ฟเวอร์ (Status: ${response.statusCode})\n${response.body}',
          );
        }
      } catch (e) {
        lastError = 'Model $model error: $e';
        continue;
      }
    }

    throw Exception(
      'เกิดข้อผิดพลาดจากเซิร์ฟเวอร์ (ทุกโมเดลล้มเหลว)\n$lastError',
    );
  }
}
