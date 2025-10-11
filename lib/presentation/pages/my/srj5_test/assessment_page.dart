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

  Future<void> _getQuestion(String selectedcluster) async {
    final result = await ref
        .read(assessmentViewModelProvider.notifier)
        .getQuestion(selectedcluster);
    result ? context.go('/home') : context.go('/home1');
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

    // final clusterState = ref.read(assessmentViewModelProvider);
    // selectedClusterNum = clusterState.clusterNum;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.yellow50,
      appBar: AppBar(
        backgroundColor: AppColors.yellow50,
        leading: GestureDetector(
          onTap: () {
            setState(() {
              stepIndex = 0;
            });
          },
          child: stepIndex == 0 ? null : Icon(Icons.arrow_back),
        ),
        actions: [
          GestureDetector(
              onTap: () {
                context.pop();
              },
              child: Icon(
                Icons.clear,
                size: 24.r,
              )),
          SizedBox(width: 12.h)
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
                    ? '$selectedclusterNM 감정 검사를 통해\n$userName님을 조금 더 알아볼게요'
                    : '지금 $userName님께 필요한\n감정 검사를 선택해 볼까요?',
                textAlign: TextAlign.center,
                style: AppFontStyles.heading2
                    .copyWith(color: AppColors.grey900),
              ),
              SizedBox(height: 5.h),
              AppText(
                stepIndex == totalSteps
                    ? '솔직하게 답변할수록 AI 분석이 더 정교해져요 🍀'
                    : '각 검사는 약 2분 정도 소요돼요 🌱',
                textAlign: TextAlign.center,
                style: AppFontStyles.bodyRegular14
                    .copyWith(color: AppColors.grey700),
              ),
              Expanded(
                  child: stepIndex == totalSteps
                      ? StartTestWidget()
                      : Column(
                          children: List.generate(
                            clusters.length,
                            (index) {
                              // final answer = _answerList[index];
                              // final isSelected = _selectedIndex == index;
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
                                          cluster:
                                              clusters[index])),
                                ],
                              );
                            },
                          ),
                        )
                  // child: stepIndex == totalSteps
                  //     ? FinishWidget(
                  //         text: '모든 준비 완료!\n함께 시작해 볼까요?',
                  //       )
                  //     : Srj5TestBox(
                  //         key: ValueKey(stepIndex),
                  //         text: personalities[stepIndex],
                  //         questionIndex: stepIndex,
                  //       )
                  ),
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
                            setState(() {
                              // isNextEnabled = false;
                              stepIndex++;
                            });
                          } else if (stepIndex == totalSteps) {
                            _getQuestion(selectedcluster!);
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
