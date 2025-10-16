import 'package:dailymoji/core/constants/app_text_strings.dart';
import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/core/styles/images.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/user_view_model.dart';
import 'package:dailymoji/presentation/pages/onboarding/widgets/part2/speech_bubble.dart';
import 'package:dailymoji/presentation/pages/onboarding/widgets/select_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TestWidget extends ConsumerStatefulWidget {
  final String text;
  final int questionIndex;
  const TestWidget(
      {super.key,
      required this.text,
      required this.questionIndex});

  @override
  ConsumerState<TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends ConsumerState<TestWidget> {
  late int _selectedIndex;

  final List<String> _answerList = AppTextStrings.testAnswerList;

  @override
  void initState() {
    super.initState();
    _selectedIndex = ref
        .read(userViewModelProvider)
        .step2Answers[widget.questionIndex];
  }

  @override
  Widget build(BuildContext context) {
    final characterIndex =
        ref.read(userViewModelProvider).characterNum;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 30.h),
        Container(
          width: double.infinity,
          height: 129.h,
          child: Row(
            children: [
              SizedBox(width: 2.w),
              Image.asset(
                AppImages.characterListProfile[characterIndex],
                width: 120.w,
                height: 129.h,
              ),
              Container(
                width: 206.17.w,
                height: 110.h,
                child: Stack(
                  children: [
                    SpeechBubble(),
                    Positioned(
                      left: 7.w,
                      top: 0,
                      right: 0,
                      bottom: 0,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 10.h),
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child: AppText(
                              widget.text,
                              style: AppFontStyles.bodyBold16
                                  .copyWith(
                                      color: AppColors.grey900),
                            )),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 56.h),
        Column(
          children: List.generate(
            _answerList.length,
            (index) {
              final answer = _answerList[index];
              final isSelected = _selectedIndex == index;
              return Column(
                children: [
                  GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIndex =
                              (_selectedIndex == index)
                                  ? -1
                                  : index;
                        });
                        ref
                            .read(userViewModelProvider.notifier)
                            .setAnswer(
                              index: widget.questionIndex,
                              score: _selectedIndex,
                            );
                      },
                      child: SelectBox(
                          isSelected: isSelected, text: answer)),
                  SizedBox(height: 8.h),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
