// lib/presentation/providers/report_providers.dart

import 'dart:convert';
import 'package:dailymoji/core/config/api_config.dart';
import 'package:dailymoji/domain/entities/weekly_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

// user_id를 받아 2주 리포트 요약 데이터를 비동기적으로 가져오는 Provider
final weeklySummaryProvider =
    FutureProvider.family<WeeklySummary, String>((ref, userId) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/report/weekly-summary');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'user_id': userId}),
  );
  if (response.statusCode == 200) {
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return WeeklySummary.fromJson(data);
  } else {
    throw Exception('Failed to load weekly summary');
  }
});
