import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/onboarding_view_model.dart';
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
  int _selectedIndex = -1;

  final _answer = [
    '전혀 없었어요',
    '가끔 있었어요',
    '자주 있었어요',
    '거의 매일 있었어요'
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = -1;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 180.h,
          child: Row(
            children: [
              Image.asset('assets/images/cado_profile.png'),
              SizedBox(
                width: 8.w,
              ),
              Container(
                width: 187.w,
                height: 96.h,
                padding: EdgeInsets.symmetric(
                    horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.r)),
                child: Center(
                    child: Text(
                  widget.text,
                  style: AppFontStyles.bodyBold16
                      .copyWith(color: AppColors.grey900),
                )),
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),
        Column(
          children: List.generate(
            _answer.length,
            (index) {
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
                            .read(onboardingViewModelProvider
                                .notifier)
                            .setAnswer(
                                check: _selectedIndex != -1,
                                index: widget.questionIndex);
                      },
                      child: SelectBox(
                          isSelected: isSelected,
                          text: _answer[index])),
                  SizedBox(height: 8.h),
                ],
              );
            },
          ),
        ),
        Text(
          '• 자주: 일주일 중 절반 이상은 그런 기분을 느꼈던 경우',
          style: AppFontStyles.bodyRegular12
              .copyWith(color: AppColors.grey700),
        )
      ],
    );
  }
}
