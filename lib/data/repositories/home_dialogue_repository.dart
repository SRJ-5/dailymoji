// data/repositories/home_dialogue_repository.dart
// 홈 말풍선 전용! 세션 생성 없음 (<-> 채팅방 이모지)
// 세션/스코어 생성 없이 /dialogue/home만 호출

import 'dart:convert';
import 'package:dailymoji/core/config/api_config.dart';
import 'package:http/http.dart' as http;

abstract class HomeDialogueRepository {
  Future<String> fetchHomeDialogue(
      String? emotion, String? personality, String? userNickNm);
  // 마음 관리 팁 후속 멘트를 가져오는 함수
  Future<String> fetchFollowUpDialogue({
    required String reason,
    required String? personality,
    required String? userNickNm,
  });
  // 마음 관리 팁 거절 멘트를 가져오는 함수
  Future<String> fetchDeclineSolutionDialogue({
    required String? personality,
    required String? userNickNm,
  });
}

class HomeDialogueRepositoryImpl implements HomeDialogueRepository {
  final String _baseUrl = ApiConfig.baseUrl;

  @override
  Future<String> fetchHomeDialogue(
      String? emotion, String? personality, String? userNickNm) async {
    final uri = Uri.parse('$_baseUrl/dialogue/home');
    final queryParameters = {
      if (emotion != null) 'emotion': emotion,
      if (personality != null) 'personality': personality,
      if (userNickNm != null) 'user_nick_nm': userNickNm,
    };
    final finalUri = uri.replace(queryParameters: queryParameters);

    try {
      final res = await http.get(finalUri);
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        return data['dialogue'] as String;
      }
    } catch (_) {}
    return "안녕! 오늘 기분은 어때?"; // fallback
  }

// 마음 관리 팁 마친 후 멘트
  @override
  Future<String> fetchFollowUpDialogue({
    required String reason,
    required String? personality,
    required String? userNickNm,
  }) async {
    final uri = Uri.parse('$_baseUrl/dialogue/solution-followup');
    final queryParameters = {
      'reason': reason,
      if (personality != null) 'personality': personality,
      if (userNickNm != null) 'user_nick_nm': userNickNm,
    };
    final finalUri = uri.replace(queryParameters: queryParameters);

    try {
      final res = await http.get(finalUri);
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        return data['dialogue'] as String;
      }
    } catch (_) {}
    // fallback 메시지
    return reason == 'user_closed' ? "대화를 더 해볼까요?" : "어때요? 좀 좋아진 것 같아요?😊";
  }

  // 🤩 RIN: 새로 추가된 함수의 구현부
  @override
  Future<String> fetchDeclineSolutionDialogue({
    required String? personality,
    required String? userNickNm,
  }) async {
    final uri = Uri.parse('$_baseUrl/dialogue/decline-solution');
    final queryParameters = {
      if (personality != null) 'personality': personality,
      if (userNickNm != null) 'user_nick_nm': userNickNm,
    };
    final finalUri = uri.replace(queryParameters: queryParameters);

    try {
      final res = await http.get(finalUri);
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        return data['dialogue'] as String;
      }
    } catch (_) {}
    // fallback 메시지
    return "알겠습니다. 그럼요. 저에게 편안하게 털어놓으세요.";
  }
}
