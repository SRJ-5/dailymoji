// data/repositories/home_dialogue_repository.dart
// 홈 말풍선 전용! 세션 생성 없음 (<-> 채팅방 이모지)
// 세션/스코어 생성 없이 /dialogue/home만 호출

import 'dart:convert';
import 'package:dailymoji/core/config/api_config.dart';
import 'package:http/http.dart' as http;

abstract class HomeDialogueRepository {
  Future<String> fetchHomeDialogue(String? emotion);
}

class HomeDialogueRepositoryImpl implements HomeDialogueRepository {
  final String _baseUrl = ApiConfig.baseUrl;

  @override
  Future<String> fetchHomeDialogue(String? emotion) async {
    final url = (emotion == null)
        ? Uri.parse('$_baseUrl/dialogue/home')
        : Uri.parse('$_baseUrl/dialogue/home?emotion=$emotion');

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        return data['dialogue'] as String;
      }
    } catch (_) {}
    return "안녕! 오늘 기분은 어때?"; // fallback
  }
}
