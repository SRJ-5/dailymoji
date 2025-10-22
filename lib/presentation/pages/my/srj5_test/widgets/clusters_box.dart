import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/domain/entities/emotion_cluster.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ClustersBox extends StatelessWidget {
  final int selectedNum;
  final int clusterIndex;
  final EmotionCluster cluster;
  const ClustersBox(
      {super.key,
      required this.cluster,
      required this.clusterIndex,
      required this.selectedNum});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 71.h),
      padding:
          EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
          color: selectedNum == clusterIndex
              ? AppColors.green700
              : AppColors.green50,
          borderRadius: BorderRadius.circular(12.r),
          border:
              Border.all(width: 1, color: AppColors.grey200)),
      child: Row(
        children: [
          SizedBox(
              width: 36.r,
              height: 36.r,
              child: Image.asset(cluster.icon!)),
          SizedBox(width: 12.w),
          Container(
            padding: EdgeInsets.only(left: 12.w),
            decoration: BoxDecoration(
                border: Border(
                    left: BorderSide(
                        width: 1,
                        color: selectedNum == clusterIndex
                            ? AppColors.grey600
                            : AppColors.grey100))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  '${cluster.clusterNM!} 감정 알기',
                  style: AppFontStyles.bodyMedium16.copyWith(
                      color: selectedNum == clusterIndex
                          ? AppColors.grey50
                          : AppColors.grey900),
                ),
                AppText(
                  cluster.description!,
                  style: AppFontStyles.bodyRegular14.copyWith(
                      color: selectedNum == clusterIndex
                          ? AppColors.grey200
                          : AppColors.grey700),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
