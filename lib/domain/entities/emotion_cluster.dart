import 'package:dailymoji/core/constants/app_text_strings.dart';
import 'package:dailymoji/core/styles/images.dart';

class EmotionCluster {
  final String? clusterNM;
  final String? icon;
  final String? description;
  EmotionCluster({this.icon, this.clusterNM, this.description});
}

class EmotionClusters {
  final angryCluster = EmotionCluster(
    clusterNM: AppTextStrings.clusterNegHigh,
    icon: AppImages.angryEmoji,
    description: AppTextStrings.negHighDescription,
  );
  final cryCluster = EmotionCluster(
    clusterNM: AppTextStrings.clusterNegLow,
    icon: AppImages.cryingEmoji,
    description: AppTextStrings.negLowDescription,
  );
  final adhdCluster = EmotionCluster(
    clusterNM: AppTextStrings.clusterAdhd,
    icon: AppImages.shockedEmoji,
    description: AppTextStrings.adhdDescription,
  );
  final sleepCluster = EmotionCluster(
    clusterNM: AppTextStrings.clusterSleep,
    icon: AppImages.sleepingEmoji,
    description: AppTextStrings.sleepDescription,
  );
  final positiveCluster = EmotionCluster(
    clusterNM: AppTextStrings.clusterPositive,
    icon: AppImages.smileEmoji,
    description: AppTextStrings.positiveDescription,
  );

  late final List<EmotionCluster> all = [
    angryCluster,
    cryCluster,
    adhdCluster,
    sleepCluster,
    positiveCluster,
  ];
}
