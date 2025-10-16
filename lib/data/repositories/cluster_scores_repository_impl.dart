import 'package:dailymoji/data/data_sources/cluster_scores_data_source.dart';
import 'package:dailymoji/data/dtos/cluster_score_dto.dart';
import 'package:dailymoji/domain/entities/cluster_score.dart';
import 'package:dailymoji/domain/repositories/cluster_scores_repository.dart';

class ClusterScoresRepositoryImpl implements ClusterScoresRepository {
  final ClusterScoresDataSource dataSource;

  ClusterScoresRepositoryImpl(this.dataSource);

// 14일 집계용 범위 조회
  @override
  Future<List<ClusterScore>> fetchRangeByUser({
    required String userId,
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    final dtos = await dataSource.fetchByUserAndRange(
      userId: userId,
      startInclusive: startInclusive,
      endExclusive: endExclusive,
    );
    // 테스트 후 삭제 바람
    dtos.forEach(
      (e) {
        if (e.cluster == "adhd") {
          print("${e.id}, ${e.cluster}, ${e.score}");
        }
      },
    );
    return _toEntities(dtos);
  }

// RIN: 복잡했던 _pickDailyMax 함수가 제거되고, RPC를 호출하는 데이터 소스 함수를 직접 사용합니다.
  // 이제 Repository는 데이터를 변환하는 역할에만 집중합니다.
  @override
  Future<List<ClusterScore>> fetchByUserAndMonth({
    required String userId,
    required int year,
    required int month,
  }) async {
    final dtos = await dataSource.fetchDailyMaxByUserAndMonth(
      userId: userId,
      year: year,
      month: month,
    );

    // 서버에서 이미 계산된 데이터를 엔티티로 변환하기만 하면 됩니다~!
    return _toEntities(dtos);
  }

  // DTO → 슬림 Entity 매핑
  List<ClusterScore> _toEntities(List<ClusterScoreDto> dtos) {
    return dtos.map((d) {
      return ClusterScore(
        userId: d.userId ?? '',
        createdAt:
            d.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        cluster: d.cluster ?? '',
        score: d.score ?? 0.0,
      );
    }).toList();
  }

  // // 한달 데이터 불러오기
  // @override
  // Future<List<ClusterScore>> fetchByUserAndMonth({
  //   required String userId,
  //   required int year,
  //   required int month,
  // }) async {
  //   final dtos = await dataSource.fetchByUserAndMonth(
  //     userId: userId,
  //     year: year,
  //     month: month,
  //   );

  //   return _pickDailyMax(dtos);
  // }

  // /// 요구사항:
  // /// 1) 한달 DTO 리스트 입력
  // /// 2) 하루별 최대 점수(동점이면 더 최신 createdAt) 한 건만 선택
  // /// 3) 최종 반환은 List<ClusterScore> (엔티티)
  // List<ClusterScore> _pickDailyMax(List<ClusterScoreDto> monthRows) {
  //   if (monthRows.isEmpty) return <ClusterScore>[];

  //   // 날짜(로컬 00:00)를 키로, 그 날짜의 최고 DTO 한 건을 값으로
  //   final byDayMax = <DateTime, ClusterScoreDto>{};

  //   for (final row in monthRows) {
  //     final createdAt = row.createdAt;
  //     final score = row.score;

  //     // 필수 값 널이면 스킵 (기본값 채우는 것보다 왜곡이 적음)
  //     if (createdAt == null || score == null) continue;

  //     // "하루" 경계를 로컬(디바이스 TZ) 기준으로 묶음 (한국이면 KST)
  //     final local = createdAt.toLocal();
  //     final dayKey = DateTime(local.year, local.month, local.day); // 로컬 자정

  //     final cur = byDayMax[dayKey];

  //     // 점수 우선, 동점이면 더 최신 createdAt
  //     if (cur == null ||
  //         score > (cur.score ?? double.negativeInfinity) ||
  //         (score == cur.score &&
  //             cur.createdAt != null &&
  //             createdAt.isAfter(cur.createdAt!))) {
  //       byDayMax[dayKey] = row;
  //     }
  //   }

  //   // 엔티티로 변환 + 정렬
  //   // 정렬 기준을 '하루' 순서로 정확히 맞추고 싶다면 key(=dayKey)로 정렬
  //   final sortedKeys = byDayMax.keys.toList()..sort();

  //   final result = <ClusterScore>[];
  //   for (final key in sortedKeys) {
  //     final d = byDayMax[key]!; // key로 꺼낸 DTO (createdAt/score는 위에서 보장됨)

  //     result.add(
  //       ClusterScore(
  //         userId: d.userId ?? '',
  //         createdAt: d.createdAt!.toUtc(), // 저장/연산은 UTC 권장
  //         cluster: d.cluster ?? 'unknown', // enum이면 parseCluster(d.cluster)
  //         score: d.score!, // null 가드 했으니 !
  //       ),
  //     );
  //   }
  //   return result;
  // }
}
