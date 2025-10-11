import 'dart:convert';

import 'package:dailymoji/core/config/api_config.dart';
import 'package:dailymoji/data/data_sources/assessment_response_remote_data_source.dart';
import 'package:dailymoji/data/dtos/assessment_responses_dto.dart';
import 'package:http/http.dart' as http;

class AssessmentResponseRemoteDataSourceImpl
    implements AssessmentResponseRemoteDataSource {
  @override
  Future<void> submitAssessment(
      AssessmentResponsesDto assessmentResponses) async {
    final url = "${ApiConfig.baseUrl}/assessment/submit";
    final response = await http.post(Uri.parse(url),
        body: jsonEncode({
          'user_id': assessmentResponses.userId,
          'cluster': assessmentResponses.clusterNM,
          'responses': assessmentResponses.responses,
        }));

    // --- API 디버깅!! ---
    final responseBody = utf8.decode(response.bodyBytes);
    print("--- 백엔드로부터 받은 실제 응답 ---");
    print(responseBody);
    // ---------------------------------------------

    // 3. API 응답 처리
    if (response.statusCode == 200) {
      final jsonResult = jsonDecode(responseBody);

      if (jsonResult == null ||
          jsonResult is! Map<String, dynamic>) {
        throw Exception(
            'Received null or invalid JSON from API. Response Body: $responseBody');
      }
    } else {
      throw Exception(
          'Failed to analyze emotion: ${response.statusCode} ${response.body}');
    }
  }
}
