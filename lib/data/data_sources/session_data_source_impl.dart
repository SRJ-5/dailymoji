import 'dart:developer';
import 'package:dailymoji/data/data_sources/sessions_data_source.dart';
import 'package:dailymoji/data/dtos/session_dto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionRemoteDataSourceImpl implements SessionRemoteDataSource {
  final SupabaseClient _client;
  SessionRemoteDataSourceImpl(this._client);

  static const _table = 'sessions';
  // 필요한 컬럼만 선택
  static const _columns = 'created_at, user_id, g_score';

  @override
  Future<List<SessionDto>> fetchLast14Days({
    required String userId,
    DateTime? now,
  }) async {
    try {
      final _now = now ?? DateTime.now();
      final endAtUtc = _now.toUtc(); // (끝 미포함)
      final startAtUtc = endAtUtc.subtract(const Duration(days: 14)); // 시작 포함

      final query = _client
          .from(_table)
          .select(_columns)
          .eq('user_id', userId)
          .gte('created_at', startAtUtc.toIso8601String())
          .lt('created_at', endAtUtc.toIso8601String())
          .order('created_at', ascending: true);

      final List<dynamic> rows = await query;
      return rows
          .cast<Map<String, dynamic>>()
          .map(SessionDto.fromJson)
          .toList();
    } on PostgrestException catch (e, s) {
      log('fetchLast14Days PostgrestException: ${e.message}', stackTrace: s);
      rethrow;
    } catch (e, s) {
      log('fetchLast14Days Unknown error: $e', stackTrace: s);
      rethrow;
    }
  }
}
