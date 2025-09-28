import 'package:dailymoji/data/dtos/session_dto.dart';

/// 최근 14일 세션(raw) 조회 전용 데이터 소스
abstract class SessionRemoteDataSource {
  /// [now]를 기준으로 지난 14일 구간 [now-14d, now) 의 세션들을 반환합니다.
  /// 정렬: 오래된 → 최신(ascending)
  Future<List<SessionDto>> fetchLast14Days({
    required String userId,
    DateTime? now, // 주입 가능(테스트 용이)
  });
}
