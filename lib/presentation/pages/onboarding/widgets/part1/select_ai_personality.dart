import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/core/styles/images.dart';
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
  ConsumerState<SelectAiPersonality> createState() =>
      _SelectAiPersonalityState();
}

class _SelectAiPersonalityState
    extends ConsumerState<SelectAiPersonality> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = ref.read(userViewModelProvider).step11;
  }

  final _personalitiesOnboarding = CharacterPersonality.values
      .map((e) => e.onboardingLabel)
      .toList();
  final _personalitiesMy =
      CharacterPersonality.values.map((e) => e.label).toList();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 566.h,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 24.r,
          ),
          Container(
            width: double.infinity,
            height: 94.h,
            padding: EdgeInsets.symmetric(
                horizontal: 4.w, vertical: 8.h),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '캐릭터의 성격을\n골라볼까요?',
                style: AppFontStyles.heading2
                    .copyWith(color: AppColors.grey900),
              ),
            ),
          ),
          SizedBox(
            height: 32.r,
          ),
          Column(
            children: List.generate(
              _personalitiesOnboarding.length,
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
                              .read(
                                  userViewModelProvider.notifier)
                              .setAiPersonality(
                                  selectNum: _selectedIndex,
                                  aiPersonality:
                                      _personalitiesMy[index]);
                        },
                        child: SelectBox(
                            isSelected: isSelected,
                            text: _personalitiesOnboarding[
                                index])),
                    _personalitiesOnboarding.length - 1 == index
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
                AppImages.cadoProfile,
                width: 120.w,
                height: 180.h,
              )),
        ],
      ),
    );
  }
}
