import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/user_view_model.dart';
import 'package:dailymoji/presentation/pages/onboarding/widgets/disclaimer_dialog.dart';
import 'package:dailymoji/presentation/pages/onboarding/widgets/finish_widget.dart';
import 'package:dailymoji/presentation/pages/onboarding/widgets/part1/ai_name_setting.dart';
import 'package:dailymoji/presentation/pages/onboarding/widgets/part1/select_ai_personality.dart';
import 'package:dailymoji/presentation/pages/onboarding/widgets/top_indicator.dart';
import 'package:dailymoji/presentation/pages/onboarding/widgets/part1/user_nick_name.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class OnboardingPart1Page extends ConsumerStatefulWidget {
  @override
  ConsumerState<OnboardingPart1Page> createState() => _OnboardingPart1PageState();
}

class _OnboardingPart1PageState extends ConsumerState<OnboardingPart1Page> {
  int stepIndex = 0;
  // 캐릭터 선택창이 생기면 totalSteps +1 해야함
  int totalSteps = 3;

  @override
  void initState() {
    super.initState();
    // 페이지 로드 후 팝업 표시
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false, // 배경 터치로 닫기 방지
        builder: (context) => DisclaimerDialog(),
      );
    });
  }

  void selectCharacter({required int selectNum, required String aiPersonality}) {
    ref.read(userViewModelProvider.notifier).setAiPersonality(selectNum: selectNum, aiPersonality: aiPersonality);
    setState(() {
      stepIndex++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isNextEnabled = switch (stepIndex) {
      0 => ref.watch(userViewModelProvider).step11 == -1 ? false : true,
      1 => ref.watch(userViewModelProvider).step12,
      2 => ref.watch(userViewModelProvider).step13,
      _ => true,
    };
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.yellow50,
        appBar: AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: AppColors.yellow50,
          leading: stepIndex > 0 && stepIndex != totalSteps
              ? IconButton(
                  onPressed: () {
                    setState(() => stepIndex--);
                  },
                  icon: Icon(
                    Icons.arrow_back,
                    size: 24.r,
                  ))
              : null,
          title: stepIndex == totalSteps
              ? null
              : AppText(
                  stepIndex == 2 ? '나의 닉네임 설정' : '도우미 설정',
                  style: AppFontStyles.bodyBold18.copyWith(color: AppColors.grey900),
                ),
          centerTitle: true,
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Column(
            children: [
              stepIndex == totalSteps
                  ? SizedBox.shrink()
                  : TopIndicator(width: 51, totalSteps: totalSteps - 1, stepIndex: stepIndex), // indicator 맨 위
              Expanded(
                  child: SingleChildScrollView(
                child: [
                  SelectAiPersonality(onSelect: selectCharacter),
                  AiNameSetting(),
                  UserNickName(),
                  FinishWidget(
                    text: '좋아요!\n이제 다음 단계로 가볼까요?',
                  ),
                ][stepIndex],
              )),
            ],
          ),
        ),
        bottomNavigationBar: stepIndex == 0
            ? null
            : AnimatedPadding(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(
                  top: 8.h,
                  left: 12.w,
                  right: 12.w,
                  bottom: MediaQuery.of(context).viewInsets.bottom > 66.h ? MediaQuery.of(context).viewInsets.bottom + 10.h : 66.h,
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 52.h),
                    backgroundColor: isNextEnabled ? AppColors.green500 : AppColors.grey200,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onPressed: isNextEnabled
                      ? () {
                          if (stepIndex < totalSteps) {
                            setState(() {
                              // isNextEnabled = false;
                              stepIndex++;
                            });
                          } else if (stepIndex == totalSteps) {
                            context.go('/onboarding2');
                          }
                        }
                      : null,
                  child: AppText('계속하기',
                      style: AppFontStyles.bodyMedium16.copyWith(
                        color: isNextEnabled ? AppColors.grey50 : AppColors.grey500,
                      )),
                ),
              ),
      ),
    );
  }
}
