// lib/data/data_sources/assessment_history_data_source_impl.dart
import 'package:dailymoji/data/data_sources/assessment_history_data_source.dart';
import 'package:dailymoji/data/dtos/assessment_history_dto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssessmentHistoryDataSourceImpl implements AssessmentHistoryDataSource {
  final SupabaseClient client;
  AssessmentHistoryDataSourceImpl(this.client);

  @override
  Future<AssessmentHistoryDto?> fetchLastSurvey(String userId) async {
    final res = await client
        .from('assessment_history')
        .select(
            'id, created_at, user_id, assessment_type, scores, raw_responses')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle(); // 있으면 사용, 없으면 아래 대안 참고

    if (res == null) return null;
    return AssessmentHistoryDto.fromJson(res as Map<String, dynamic>);
  }
}
