import 'package:dailymoji/core/styles/icons.dart';
import 'package:dailymoji/domain/enums/enum_data.dart';
import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/presentation/pages/my/widgets/edit_nickname_card.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/user_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CharacterSettingPage extends ConsumerStatefulWidget {
  const CharacterSettingPage({super.key});

  @override
  ConsumerState<CharacterSettingPage> createState() => _CharacterSettingPageState();
}

class _CharacterSettingPageState extends ConsumerState<CharacterSettingPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userViewModelProvider);
    final userViewModel = ref.read(userViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.yellow50,
      appBar: AppBar(
        backgroundColor: AppColors.yellow50,
        centerTitle: true,
        title: Text(
          "캐릭터 설정",
          style: AppFontStyles.bodyBold18.copyWith(color: AppColors.grey900),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 16.h),
              NicknameEditCard(nickname: userState.userProfile!.characterNm!, isUser: false),
              SizedBox(height: 16.h),
              GestureDetector(
                onTap: () async {
                  final result = await showDialog<String>(
                    context: context,
                    barrierColor: Colors.transparent,
                    builder: (context) {
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(color: Colors.transparent),
                            ),
                          ),
                          Positioned(
                            // left: 183.w,
                            top: 216.h,
                            right: 12.w,
                            child: Material(
                              color: Colors.transparent,
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 4.h),
                                width: 182.w,
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(color: AppColors.grey100),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF1D293D).withValues(alpha: 0.1),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: CharacterPersonality.values.map((e) {
                                    final isSelected = userState.userProfile!.characterPersonality! == e.label;
                                    return GestureDetector(
                                      onTap: () => Navigator.pop(context, e.label),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                        alignment: Alignment.centerLeft,
                                        child: Row(
                                          children: [
                                            SvgPicture.asset(
                                              isSelected ? AppIcons.radioSelected : AppIcons.radioUnselected,
                                              width: 16.r,
                                              height: 16.r,
                                            ),
                                            SizedBox(width: 8.w),
                                            Text(
                                              e.label,
                                              style: isSelected
                                                  ? AppFontStyles.bodySemiBold14.copyWith(
                                                      color: AppColors.grey900,
                                                    )
                                                  : AppFontStyles.bodyRegular14.copyWith(
                                                      color: AppColors.grey900,
                                                    ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );

                  if (result != null) {
                    ref.read(userViewModelProvider.notifier).updateCharacterPersonality(newCharacterPersonality: result);
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.grey100),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "캐릭터 성격",
                        style: AppFontStyles.bodyRegular16.copyWith(
                          color: AppColors.grey700,
                        ),
                      ),
                      Spacer(),
                      Text(
                        userState.userProfile!.characterPersonality!,
                        style: AppFontStyles.bodyRegular14.copyWith(
                          color: AppColors.grey500,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
                        width: 24.w,
                        height: 24.h,
                        child: SvgPicture.asset(
                          AppIcons.unfoldMore,
                          colorFilter: ColorFilter.mode(AppColors.grey700, BlendMode.srcIn),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
