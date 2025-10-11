import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
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

  final List<String> _answerList = [
    '전혀없음',
    '며칠',
    '절반 이상',
    '거의 매일'
  ];

  @override
  void initState() {
    super.initState();
    // _selectedIndex = ref
    //     .read(userViewModelProvider)
    //     .step2Answers[widget.questionIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 24.h),
        Container(
            width: double.infinity,
            height: 100.h,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppText(
                widget.text,
                style: AppFontStyles.heading2
                    .copyWith(color: AppColors.grey900),
              ),
            )),
        SizedBox(height: 24.h),
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
                        // ref
                        //     .read(userViewModelProvider.notifier)
                        //     .setAnswer(
                        //       index: widget.questionIndex,
                        //       score: _selectedIndex,
                        //     );
                      },
                      child: SelectBox(
                          isSelected: isSelected, text: answer)),
                  SizedBox(height: 8.h),
                ],
              );
            },
          ),
        ),
        AppText(
          '• 지난2주동안, 아래의 경험을 얼마나 자주 느끼셨나요?',
          style: AppFontStyles.bodyRegular12
              .copyWith(color: AppColors.grey700),
        )
      ],
    );
  }
}
