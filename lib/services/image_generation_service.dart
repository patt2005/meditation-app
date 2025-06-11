import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';

class ImageGenerationService {
  static const String _baseUrl =
      'https://api.stability.ai/v2beta/stable-image/generate/core';
  static const String _apiKey =
      'sk-eNvzpe3PgewfgL3ljsWjZRkASCYYb5XmJqNQSnuQq0xpiTaJ';

  static final ImageGenerationService _instance =
      ImageGenerationService._internal();
  factory ImageGenerationService() => _instance;
  ImageGenerationService._internal();

  final GoogleTranslator _translator = GoogleTranslator();

  String generatePromptFromResponses(Map<int, String> responses) {
    List<String> elements = [];

    responses.forEach((step, response) {
      if (response.isNotEmpty) {
        String cleaned = response.trim().toLowerCase();

        switch (step) {
          case 1:
            elements.add('в сказочном месте $cleaned');
            break;
          case 2:
            elements.add('время суток $cleaned');
            break;
          case 3:
            elements.add('с персонажами $cleaned');
            break;
          case 4:
            elements.add('атмосфера наполнена $cleaned');
            break;
          case 5:
            elements.add('украшено деталями $cleaned');
            break;
          case 6:
            elements.add('в стиле $cleaned');
            break;
        }
      }
    });

    String basePrompt = "Сюрреалистический сказочный сон ";
    String userElements =
        elements.isNotEmpty ? elements.join(', ') : "с волшебной красотой";
    String styleModifiers =
        ", очень детализированный, магическая атмосфера, мягкое волшебное освещение, мистические элементы";

    return basePrompt + userElements + styleModifiers;
  }

  Future<Uint8List?> generateImage({
    required Map<int, String> userResponses,
    Function(String)? onStatusUpdate,
  }) async {
    try {
      String russianPrompt = generatePromptFromResponses(userResponses);
      debugPrint('Generated Russian prompt: $russianPrompt');

      if (onStatusUpdate != null) {
        onStatusUpdate('Подготавливаем ваш сон...');
      }

      Translation translation = await _translator.translate(
        russianPrompt,
        from: 'ru',
        to: 'en',
      );
      String englishPrompt = translation.text;
      debugPrint('Translated English prompt: $englishPrompt');

      var request = http.MultipartRequest('POST', Uri.parse(_baseUrl));

      request.headers.addAll({
        'authorization': 'Bearer $_apiKey',
        'accept': 'image/*',
        'stability-client-id': 'meditation-app',
        'stability-client-version': '1.0.0',
      });

      request.fields['prompt'] = englishPrompt;
      request.fields['aspect_ratio'] = '9:16';
      request.fields['style_preset'] = 'fantasy-art';
      request.fields['output_format'] = 'webp';
      request.fields['negative_prompt'] =
          'text, words, letters, watermark, signature, ugly, distorted';

      request.files.add(
        http.MultipartFile.fromString('none', '', filename: ''),
      );

      if (onStatusUpdate != null) {
        onStatusUpdate('Создаем визуализацию...');
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        if (onStatusUpdate != null) {
          onStatusUpdate('Завершаем создание...');
        }
        return response.bodyBytes;
      } else {
        debugPrint('Error generating image: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');

        try {
          var errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 'Failed to generate image');
        } catch (e) {
          throw Exception('Failed to generate image: ${response.statusCode}');
        }
      }
    } catch (e) {
      debugPrint('Exception in generateImage: $e');
      throw Exception('Failed to generate image: $e');
    }
  }

  bool isApiKeySet() {
    return _apiKey != 'YOUR_API_KEY_HERE' && _apiKey.isNotEmpty;
  }
}
