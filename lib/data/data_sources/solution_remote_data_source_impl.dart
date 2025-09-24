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
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
          "Failed to propose solution: ${response.statusCode} ${response.body}");
    }
  }

  @override
  Future<Map<String, dynamic>> fetchSolutionById(String solutionId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/solutions/$solutionId');
    final response = await client.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
          "Failed to fetch solution: ${response.statusCode} ${response.body}");
    }
  }
}
