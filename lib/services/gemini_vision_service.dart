import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/listing_draft.dart';

class GeminiVisionService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  Future<ListingDraft> analyzeProductImage(
    File imageFile, {
    String? customPrompt,
  }) async {
    final cleanKey = _apiKey.trim();
    if (cleanKey.isEmpty) {
      throw Exception(
        'ไม่พบ API Key! กรุณาระบุ GEMINI_API_KEY ผ่าน --dart-define',
      );
    }

    // อ่านภาพเป็น Bytes และแปลงเป็น Base64
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    String mimeType = 'image/jpeg';
    if (imageFile.path.toLowerCase().endsWith('.png')) {
      mimeType = 'image/png';
    }

    final Map<String, String> headers = {'Content-Type': 'application/json'};

    Uri url;
    if (cleanKey.startsWith('AQ.')) {
      headers['Authorization'] = 'Bearer $cleanKey';
      url = Uri.parse(_baseUrl);
    } else {
      headers['x-goog-api-key'] = cleanKey;
      url = Uri.parse('$_baseUrl?key=$cleanKey');
    }

    const defaultPrompt = '''
วิเคราะห์ภาพสินค้าชิ้นนี้สำหรับลงประกาศขายในแอปร้านค้าสถาบันการศึกษา
ให้สร้างข้อมูล 3 ส่วนเป็นภาษาไทย:
1. title: ชื่อสินค้าที่ดึงดูด น่าสนใจ และตรงกับภาพ
2. category: หมวดหมู่สินค้า (เช่น เครื่องแต่งกาย, อุปกรณ์การเรียน, ไอที/อิเล็กทรอนิกส์, หนังสือ/เอกสาร, ของใช้ทั่วไป)
3. description: คำอธิบายรายละเอียดสินค้า ระบุสภาพ จุดเด่น และความน่าซื้อ
''';

    final promptText = customPrompt ?? defaultPrompt;

    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': promptText},
            {
              'inline_data': {'mime_type': mimeType, 'data': base64Image},
            },
          ],
        },
      ],
      'generationConfig': {
        'response_mime_type': 'application/json',
        'response_schema': {
          'type': 'OBJECT',
          'properties': {
            'title': {'type': 'STRING'},
            'category': {'type': 'STRING'},
            'description': {'type': 'STRING'},
          },
          'required': ['title', 'category', 'description'],
        },
      },
    });

    try {
      final response = await http
          .post(url, headers: headers, body: requestBody)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('หมดเวลาเชื่อมต่อ (30 วินาที)'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ตรวจสอบ Safety Block ในชั้น Prompt
        if (data['promptFeedback'] != null &&
            data['promptFeedback']['blockReason'] != null) {
          final blockReason = data['promptFeedback']['blockReason'];
          if (blockReason == 'SAFETY') {
            throw Exception('เนื้อหาคำขอเข้าข่ายไม่ปลอดภัยตามนโยบายของ Gemini');
          }
          throw Exception('คำขอถูกบล็อกเนื่องจาก: $blockReason');
        }

        // ตรวจสอบ Safety Block ในชั้น Candidate ผลลัพธ์
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          final finishReason = candidate['finishReason'];

          if (finishReason == 'SAFETY') {
            throw Exception(
              'เนื้อหาที่วิเคราะห์เข้าข่ายไม่ปลอดภัยตามนโยบายของ Gemini กรุณาใช้ภาพอื่น',
            );
          }

          if (candidate['content'] != null &&
              candidate['content']['parts'] != null &&
              candidate['content']['parts'].isNotEmpty) {
            final rawJsonText =
                candidate['content']['parts'][0]['text'] as String;
            final Map<String, dynamic> parsedJson = jsonDecode(rawJsonText);
            return ListingDraft.fromJson(parsedJson);
          }
        }

        throw Exception(
          'AI ไม่สามารถวิเคราะห์ภาพนี้ได้ อาจเข้าข่ายเนื้อหาที่ไม่เหมาะสม ลองใช้ภาพอื่น',
        );
      } else {
        throw Exception(
          'เกิดข้อผิดพลาดจากเซิร์ฟเวอร์ (Status: ${response.statusCode})\n${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
