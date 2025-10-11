import 'package:dailymoji/core/constants/app_text_strings.dart';
import 'package:dailymoji/core/styles/images.dart';

class EmotionCluster {
  final String? cluster;
  final String? clusterNM;
  final String? icon;
  final String? description;
  EmotionCluster(
      {this.cluster,
      this.icon,
      this.clusterNM,
      this.description});
}

class EmotionClusters {
  final angryCluster = EmotionCluster(
    cluster: AppTextStrings.negHigh,
    clusterNM: AppTextStrings.clusterNegHigh,
    icon: AppImages.angryEmoji,
    description: AppTextStrings.negHighDescription,
  );
  final cryCluster = EmotionCluster(
    cluster: AppTextStrings.negLow,
    clusterNM: AppTextStrings.clusterNegLow,
    icon: AppImages.cryingEmoji,
    description: AppTextStrings.negLowDescription,
  );
  final adhdCluster = EmotionCluster(
    cluster: AppTextStrings.adhd,
    clusterNM: AppTextStrings.clusterAdhd,
    icon: AppImages.shockedEmoji,
    description: AppTextStrings.adhdDescription,
  );
  final sleepCluster = EmotionCluster(
    cluster: AppTextStrings.sleepDescription,
    clusterNM: AppTextStrings.clusterSleep,
    icon: AppImages.sleepingEmoji,
    description: AppTextStrings.sleepDescription,
  );
  final positiveCluster = EmotionCluster(
    cluster: AppTextStrings.positive,
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
