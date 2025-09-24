import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/domain/enums/enum_data.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/user_view_model.dart';
import 'package:dailymoji/presentation/pages/onboarding/widgets/select_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SelectAiPersonality extends ConsumerStatefulWidget {
  const SelectAiPersonality({
    super.key,
  });

  @override
  ConsumerState<SelectAiPersonality> createState() => _SelectAiPersonalityState();
}

class _SelectAiPersonalityState extends ConsumerState<SelectAiPersonality> {
  int _selectedIndex = -1;

  final _personalities = CharacterPersonality.values.map((e) => e.label).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 24.r,
        ),
        Container(
          width: double.infinity,
          height: 94.h,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '캐릭터의 성격을\n골라볼까요?',
              style: AppFontStyles.heading2.copyWith(color: AppColors.grey900),
            ),
          ),
        ),
        SizedBox(
          height: 24.r,
        ),
        Column(
          children: List.generate(
            _personalities.length,
            (index) {
              final isSelected = _selectedIndex == index;
              return Column(
                children: [
                  GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIndex = (_selectedIndex == index) ? -1 : index;
                        });
                        ref.read(userViewModelProvider.notifier).setAiPersonality(check: _selectedIndex != -1, aiPersonality: _personalities[index]);
                      },
                      child: SelectBox(isSelected: isSelected, text: _personalities[index])),
                  _personalities.length - 1 == index
                      ? SizedBox.shrink()
                      : SizedBox(
                          height: 8.h,
                        )
                ],
              );
            },
          ),
        ),
        Spacer(),
        Align(
            alignment: Alignment.bottomRight,
            child: Image.asset(
              'assets/images/cado_profile.png',
              width: 120.w,
              height: 180.h,
            )),
      ],
    );
  }
}
