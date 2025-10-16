import 'dart:convert';
import 'package:http/http.dart' as http;
import 'solution_remote_data_source.dart';
import 'package:dailymoji/core/config/api_config.dart';

class SolutionRemoteDataSourceImpl implements SolutionRemoteDataSource {
  final http.Client client;

  SolutionRemoteDataSourceImpl(this.client);

  @override
  Future<Map<String, dynamic>> proposeSolution({
    required String userId,
    required String sessionId,
    required String topCluster,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/solutions/propose');
    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "user_id": userId,
        "session_id": sessionId,
        "top_cluster": topCluster,
      }),
    );

    if (response.statusCode == 200) {
// 응답 본문을 UTF-8로 강제 디코딩!!
      final decodedBody = utf8.decode(response.bodyBytes);
      return jsonDecode(decodedBody) as Map<String, dynamic>;
    } else {
      throw Exception(
          "Failed to propose solution: ${response.statusCode} ${response.body}");
    }
  }

  @override
  Future<Map<String, dynamic>> fetchSolutionById(String solutionId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/solutions/$solutionId');
    final response = await client.get(
      url,
      headers: {
        'Content-Type': 'application/json; charset=utf-8'
      }, // 헤더에 charset=utf-8 명시
    );

    if (response.statusCode == 200) {
      // 이 함수도 UTF-8로 강제 디코딩
      final decodedBody = utf8.decode(response.bodyBytes);
      return jsonDecode(decodedBody) as Map<String, dynamic>;
    } else {
      throw Exception(
          "Failed to fetch solution: ${response.statusCode} ${response.body}");
    }
  }

  @override
  Future<String?> fetchSolutionTextById(String solutionId) async {
    // Supabase에서 직접 text를 가져오는 것이 더 효율적일 수 있으나,
    // 일관성을 위해 기존처럼 API 서버를 통해 가져오는 방식으로 구현합니다.
    // (만약 백엔드에 이 기능이 없다면, 백엔드에도 /solutions/{solution_id}/text 와 같은 엔드포인트 추가가 필요합니다)
    try {
      final data = await fetchSolutionById(solutionId); // 기존 함수 재활용
      return data['text'] as String?;
    } catch (e) {
      print('Error fetching solution text by id: $e');
      return null;
    }
  }
}
