// data/repositories/reaction_repository.dart

import 'dart:convert';
import 'package:dailymoji/core/config/api_config.dart';
import 'package:http/http.dart' as http;

abstract class ReactionRepository {
  Future<String> getReactionScript(String? emotion);
}

class ReactionRepositoryImpl implements ReactionRepository {
  final String _baseUrl = ApiConfig.baseUrl;

  @override
  Future<String> getReactionScript(String? emotion) async {
    final url = emotion == null
        ? Uri.parse('$_baseUrl/dialogue/home')
        : Uri.parse('$_baseUrl/dialogue/home?emotion=$emotion');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['dialogue'] as String;
      } else {
        throw Exception('Failed to load dialogues');
      }
    } catch (e) {
      print('Error fetching dialogues: $e');
      return "안녕!\n오늘 기분은 어때?";
    }
  }
}
