import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dailymoji/core/config/api_config.dart';
import 'package:dailymoji/domain/entities/solution.dart';
import 'package:dailymoji/domain/repositories/solution_repository.dart';

// SolutionRepository 규칙을 실제로 구현(implements)하는 클래스
class SolutionRepositoryImpl implements SolutionRepository {
  final http.Client _client;
  SolutionRepositoryImpl(this._client);

  @override
  Future<Solution> fetchSolutionById(String solutionId) async {
    final uri = Uri.parse('${getBaseUrl()}/solutions/$solutionId');
    try {
      final response = await _client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        return Solution.fromJson(data);
      } else {
        throw Exception('Failed to load solution data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching solution: $e');
      throw Exception('Failed to connect to the server.');
    }
  }
}
