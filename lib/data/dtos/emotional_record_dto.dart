import 'package:dailymoji/domain/entities/emotional_record.dart';

// 백엔드 API 응답에 맞춰 DTO 통합 및 수정
class EmotionalRecordDto {
  final Map<String, double>? finalScores;
  final double? gScore;
  final int? profile;
  final Map<String, dynamic>? intervention;
  final Map<String, dynamic>? debugLog;
  final String? sessionId;

  EmotionalRecordDto({
    this.finalScores,
    this.gScore,
    this.profile,
    this.intervention,
    this.debugLog,
    this.sessionId,
  });

  EmotionalRecordDto.fromJson(Map<String, dynamic> json)
      : finalScores = (json["final_scores"] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
            ) ??
            {}, // null일 경우 빈 맵을 반환하도록 안정성 강화
        gScore = (json["g_score"] as num?)?.toDouble(),
        profile = json["profile"],
        intervention = json["intervention"] != null
            ? Map<String, dynamic>.from(json["intervention"])
            : null,
        debugLog = json["debug_log"] != null
            ? Map<String, dynamic>.from(json["debug_log"])
            : null,
        sessionId = json["session_id"];

  EmotionalRecord toEntity() {
    return EmotionalRecord(
      finalScores: finalScores ?? {},
      gScore: gScore ?? 0.0,
      profile: profile ?? 0,
      interventionPresetId: intervention?['preset_id'] as String?,
      intervention: intervention ?? {},
      sessionId: sessionId,
    );
  }
}
