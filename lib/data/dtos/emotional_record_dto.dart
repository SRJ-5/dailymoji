// lib/data/dtos/emotional_record_dto.dart
// 0924 변경:
// 1. 백엔드 응답 변경에 맞춰 DTO 구조 수정 (analysis_text, proposal_text 추가)
// 2. intervention 필드를 더 유연하게 처리

import 'package:dailymoji/domain/entities/emotional_record.dart';

class EmotionalRecordDto {
  final Map<String, double>? finalScores;
  final double? gScore;
  final int? profile;
  final Map<String, dynamic>? intervention;
  final String? sessionId;

  EmotionalRecordDto({
    this.finalScores,
    this.gScore,
    this.profile,
    this.intervention,
    this.sessionId,
  });

  factory EmotionalRecordDto.fromJson(Map<String, dynamic> json) {
    return EmotionalRecordDto(
      finalScores: (json["final_scores"] as Map?)?.map(
        (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
      ),
      gScore: (json["g_score"] as num?)?.toDouble(),
      profile: json["profile"],
      intervention: json["intervention"] != null
          ? Map<String, dynamic>.from(json["intervention"])
          : null,
      sessionId: json["session_id"],
    );
  }

  EmotionalRecord toEntity() {
    return EmotionalRecord(
      finalScores: finalScores ?? {},
      gScore: gScore ?? 0.0,
      profile: profile ?? 0,
      sessionId: sessionId,
      interventionPresetId: intervention?['preset_id'] as String?,
      analysisText: intervention?['analysis_text'] as String?,
      proposalText: intervention?['proposal_text'] as String?,
      intervention: intervention ?? {},
    );
  }
}
