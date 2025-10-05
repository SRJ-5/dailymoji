// lib/data/dtos/emotional_record_dto.dart

import 'package:dailymoji/domain/entities/emotional_record.dart';

class EmotionalRecordDto {
  final Map<String, dynamic> finalScores;
  final double gScore;
  final int profile;
  final String? sessionId;
  final Map<String, dynamic> intervention;

  EmotionalRecordDto({
    required this.finalScores,
    required this.gScore,
    required this.profile,
    this.sessionId,
    required this.intervention,
  });

  factory EmotionalRecordDto.fromJson(Map<String, dynamic> json) {
    return EmotionalRecordDto(
      finalScores: Map<String, dynamic>.from(json['final_scores'] ?? {}),
      gScore: (json['g_score'] as num?)?.toDouble() ?? 0.0,
      profile: json['profile'] as int? ?? 0,
      sessionId: json['session_id'] as String?,
      intervention: Map<String, dynamic>.from(json['intervention'] ?? {}),
    );
  }

  EmotionalRecord toEntity() {
    return EmotionalRecord(
      finalScores: finalScores
          .map((key, value) => MapEntry(key, (value as num).toDouble())),
      gScore: gScore,
      profile: profile,
      sessionId: sessionId,
      intervention: intervention,
    );
  }
}
