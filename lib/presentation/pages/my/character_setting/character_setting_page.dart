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
                  final result = await showMenu<String>(
                    context: context,
                    position: RelativeRect.fromLTRB(183.w, 263.h, 12.w, 0),
                    color: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      side: BorderSide(color: AppColors.grey100),
                    ),
                    items: CharacterPersonality.values.map((e) => e.label).map((e) {
                      return PopupMenuItem<String>(
                        padding: EdgeInsets.zero,
                        value: e,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context, e);
                                },
                                child: SvgPicture.asset(
                                  userState.userProfile!.characterPersonality! == e ? AppIcons.radioSelected : AppIcons.radioUnselected,
                                  width: 16.r,
                                  height: 16.r,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                e,
                                style: userState.userProfile!.characterPersonality! == e
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
                  );
                  if (result != null) {
                    print(result);
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
                      Icon(
                        Icons.unfold_more,
                        color: AppColors.grey700,
                        size: 24.sp,
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
