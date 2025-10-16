import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class Solution {
  final String? videoId;
  final int? startAt;
  final int? endAt;
  final String text;

  Solution({this.videoId, this.startAt, this.endAt, this.text = ''});

  factory Solution.fromJson(Map<String, dynamic> json) {
    String? videoId;
    final dynamic rawUrl = json['url']; // url 값을 dynamic으로 먼저 받기

    // url 값이 문자열일 때만 videoId 추출 시도
    if (rawUrl is String && rawUrl.isNotEmpty) {
      videoId = YoutubePlayer.convertUrlToId(rawUrl) ?? rawUrl;
    }
    // (url이 null이거나 문자열이 아니면 videoId는 그대로 null로 유지)

    return Solution(
      videoId: videoId,
      startAt: int.tryParse(json['startAt']?.toString() ?? '0') ?? 0,
      endAt: int.tryParse(json['endAt']?.toString() ?? '0'),
      // text 값이 null일 경우를 대비한 안전장치도 그대로 유지
      text: json['text'] as String? ?? '',
    );
  }
}
