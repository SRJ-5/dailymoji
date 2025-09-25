// Supabase에서 리포트 데이터를 가져오는 DataSource
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportRemoteDataSource {
  final SupabaseClient _client;

  ReportRemoteDataSource(this._client);

  Future<List<Map<String, dynamic>>> getRecordsForMonth(
      String userId, DateTime month) async {
    final firstDay = DateTime(month.year, month.month, 1).toIso8601String();
    final lastDay = DateTime(month.year, month.month + 1, 0).toIso8601String();

    final response = await _client
        .from('emotional_records')
        .select('created_at, g_score, score_per_cluster')
        .eq('user_id', userId)
        .gte('created_at', firstDay)
        .lte('created_at', lastDay)
        .order('created_at', ascending: true);

    // response는 List<dynamic> 타입이므로 List<Map<String, dynamic>>으로 캐스팅
    return (response as List)
        .map((item) => item as Map<String, dynamic>)
        .toList();
  }
}
