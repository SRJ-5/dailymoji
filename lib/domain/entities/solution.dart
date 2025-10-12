import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class Solution {
  final String? videoId;
  final int? startAt;
  final int? endAt;
  final String text;

  Solution({this.videoId, this.startAt, this.endAt, this.text = ''});

  factory Solution.fromJson(Map<String, dynamic> json) {
    // 백엔드가 전체 YouTube URL을 주면 ID를 추출, ID만 주면 그대로 사용
    final videoId = YoutubePlayer.convertUrlToId(json['url']) ?? json['url'];
    return Solution(
      videoId: videoId,
      startAt: int.tryParse(json['startAt']?.toString() ?? '0') ?? 0,
      endAt: int.tryParse(json['endAt']?.toString() ?? '0'),
      text: json['text'] as String? ?? '',
    );
  }
}
