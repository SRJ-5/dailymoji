import 'package:dailymoji/core/styles/images.dart';
import 'package:dailymoji/core/constants/app_text_strings.dart';
import 'package:dailymoji/core/styles/videos.dart';

/// 이모지 에셋 타입
///
/// 감정 상태에 따른 이모지 이미지와 표시명을 관리
enum EmojiAsset {
  angry(
    AppTextStrings.negHigh,
    AppImages.angryEmoji,
    AppTextStrings.clusterNegHigh,
    AppVideos.angryEmoji,
  ),
  crying(
    AppTextStrings.negLow,
    AppImages.cryingEmoji,
    AppTextStrings.clusterNegLow,
    AppVideos.cryingEmoji,
  ),
  shocked(
    AppTextStrings.adhd,
    AppImages.shockedEmoji,
    AppTextStrings.clusterAdhd,
    AppVideos.shockedEmoji,
  ),
  sleeping(
    AppTextStrings.sleep,
    AppImages.sleepingEmoji,
    AppTextStrings.clusterSleep,
    AppVideos.sleepingEmoji,
  ),
  smile(
    AppTextStrings.positive,
    AppImages.smileEmoji,
    AppTextStrings.clusterPositive,
    AppVideos.smileEmoji,
  ),
  defaultEmoji(
    "default",
    AppImages.defaultEmoji,
    '기본',
    "default",
  );

  /// 이모지 키 값 (default는 Dart 키워드라서 label 필드 필요)
  final String label;

  /// 이미지 에셋 경로
  final String asset;

  /// 사용자에게 표시되는 이름
  final String display;

  final String video; // ✅ 추가: 동영상 경로

  const EmojiAsset(this.label, this.asset, this.display, this.video);

  /// 문자열로부터 EmojiAsset을 찾는 헬퍼 메서드
  static EmojiAsset fromString(String label) {
    return EmojiAsset.values.firstWhere(
      (e) => e.label == label,
      orElse: () => EmojiAsset.defaultEmoji,
    );
  }

  /// default를 제외한 모든 이모지 리스트
  static List<EmojiAsset> get withoutDefault {
    return EmojiAsset.values
        .where((e) => e != EmojiAsset.defaultEmoji)
        .toList();
  }

  /// 모든 이모지의 label 리스트 (Map의 keys 대체용)
  static List<String> get allLabels {
    return EmojiAsset.values.map((e) => e.label).toList();
  }

  /// default를 제외한 label 리스트
  static List<String> get labelsWithoutDefault {
    return withoutDefault.map((e) => e.label).toList();
  }
}
