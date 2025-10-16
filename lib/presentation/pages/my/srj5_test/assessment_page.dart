import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/domain/entities/emotion_cluster.dart';
import 'package:dailymoji/presentation/pages/my/srj5_test/assessment_view_model.dart';
import 'package:dailymoji/presentation/pages/my/srj5_test/widgets/clusters_box.dart';
import 'package:dailymoji/presentation/pages/my/srj5_test/widgets/start_test_widget.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/user_view_model.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class AssessmentPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<AssessmentPage> createState() =>
      _AssessmentPageState();
}

class _AssessmentPageState
    extends ConsumerState<AssessmentPage> {
  final emotionClusters = EmotionClusters();
  int selectedClusterNum = -1;
  int stepIndex = 0;
  int totalSteps = 1;
  late String? selectedcluster;
  late String? selectedclusterNM;

  Future<void> _getQuestion(
      {required String selectedcluster,
      required String selectedClusterNM}) async {
    try {
      final result = await ref
          .read(assessmentViewModelProvider.notifier)
          .getQuestion(
              cluster: selectedcluster,
              clusterNM: selectedClusterNM);
      if (mounted) {
        result
            ? setState(() {
                // isNextEnabled = false;
                stepIndex++;
              })
            : ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: AppText(
                        "감정 검사를 불러오는데 실패했습니다. 다시 시도해주세요.")));
      }
    } catch (e) {
      // 예외 처리
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: AppText("오류가 발생했습니다: ${e.toString()}")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clusters = emotionClusters.all;
    final user = ref.read(userViewModelProvider);
    final userName = user.userProfile!.userNickNm;
    if (selectedClusterNum != -1) {
      selectedcluster = clusters[selectedClusterNum].cluster;
      selectedclusterNM = clusters[selectedClusterNum].clusterNM;
    }
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.yellow50,
      appBar: AppBar(
        backgroundColor: AppColors.yellow50,
        leading: SizedBox.shrink(),
        actions: [
          GestureDetector(
              onTap: () {
                context.pop();
              },
              child: Icon(
                Icons.clear,
                size: 24.r,
              )),
          SizedBox(width: 12.r)
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              SizedBox(height: 40.h),
              AppText(
                stepIndex == totalSteps
                    ? '나의 $selectedclusterNM 체크를 통해\n$userName님을 조금 더 알아볼게요'
                    : '$userName님이\n알려주고 싶은\n감정을 선택해 볼까요?',
                textAlign: TextAlign.center,
                style: AppFontStyles.heading2
                    .copyWith(color: AppColors.grey900),
              ),
              SizedBox(height: 5.h),
              AppText(
                stepIndex == totalSteps
                    ? '솔직하게 답변할수록 도우미 답변이 더 정교해져요 🍀'
                    : '도우미와 대화할 때 도움이 됩니다. 🌱',
                textAlign: TextAlign.center,
                style: AppFontStyles.bodyRegular14
                    .copyWith(color: AppColors.grey700),
              ),
              Expanded(
                  child: stepIndex == totalSteps
                      ? StartTestWidget()
                      : SingleChildScrollView(
                          child: Column(
                            children: List.generate(
                              clusters.length,
                              (index) {
                                return Column(
                                  children: [
                                    index == 0
                                        ? SizedBox(height: 30.h)
                                        : SizedBox(height: 8.h),
                                    GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (selectedClusterNum ==
                                                index) {
                                              selectedClusterNum =
                                                  -1;
                                            } else {
                                              selectedClusterNum =
                                                  index;
                                            }
                                          });
                                        },
                                        child: ClustersBox(
                                            clusterIndex: index,
                                            selectedNum:
                                                selectedClusterNum,
                                            cluster: clusters[
                                                index])),
                                  ],
                                );
                              },
                            ),
                          ),
                        )),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: SizedBox(
          width: 100.w,
          height: 100.h,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 52.h),
                    backgroundColor: selectedClusterNum != -1
                        ? AppColors.green500
                        : AppColors.grey200,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onPressed: selectedClusterNum != -1
                      ? () async {
                          if (stepIndex < totalSteps) {
                            _getQuestion(
                                selectedcluster:
                                    selectedcluster!,
                                selectedClusterNM:
                                    selectedclusterNM!);
                          } else if (stepIndex == totalSteps) {
                            context.push('/srj5_test');
                          }
                        }
                      : null,
                  child: AppText(
                      stepIndex == totalSteps ? '시작하기' : '계속하기',
                      style: AppFontStyles.bodyMedium16.copyWith(
                        color: selectedClusterNum != -1
                            ? AppColors.grey50
                            : AppColors.grey500,
                      )),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
