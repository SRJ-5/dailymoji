import 'package:dailymoji/core/constants/app_text_strings.dart';
import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/presentation/pages/my/srj5_test/assessment_view_model.dart';
import 'package:dailymoji/presentation/pages/onboarding/widgets/select_box.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Srj5TestBox extends ConsumerStatefulWidget {
  final String text;
  final int questionIndex;
  const Srj5TestBox(
      {super.key,
      required this.text,
      required this.questionIndex});

  @override
  ConsumerState<Srj5TestBox> createState() =>
      _Srj5TestBoxState();
}

class _Srj5TestBoxState extends ConsumerState<Srj5TestBox> {
  late int _selectedIndex = -1;

  final List<String> _answerList = AppTextStrings.testAnswerList;

  @override
  void initState() {
    super.initState();
    _selectedIndex = ref
        .read(assessmentViewModelProvider)
        .questionScores![widget.questionIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 46.h),
        Container(
            width: double.infinity,
            height: 147.h,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    '최근 2주를 기준으로 답변해 주세요',
                    style: AppFontStyles.bodyRegular14
                        .copyWith(color: AppColors.grey700),
                  ),
                  SizedBox(height: 4),
                  AppText(
                    widget.text,
                    style: AppFontStyles.heading3
                        .copyWith(color: AppColors.grey900),
                  ),
                ],
              ),
            )),
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
                            .read(assessmentViewModelProvider
                                .notifier)
                            .setTestAnswer(
                              questionIndex:
                                  widget.questionIndex,
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
