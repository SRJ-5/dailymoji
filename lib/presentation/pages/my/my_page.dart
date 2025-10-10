import 'package:dailymoji/core/constants/app_text_strings.dart';
import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/presentation/pages/my/widgets/confirm_dialog.dart';
import 'package:dailymoji/presentation/pages/my/widgets/edit_nickname_card.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/user_view_model.dart';
import 'package:dailymoji/presentation/widgets/bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class MyPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyPage> createState() => _MyPageState();
}

class _MyPageState extends ConsumerState<MyPage> {
  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userViewModelProvider);
    // 상태 초기화 시 userNickNm이 널이 되어서 화면이 깨지는 현상 때문에 ''를 넣음
    final String userNickname = userState.userProfile?.userNickNm ?? '';

// onTap 동작을 위한 라우팅 맵 정의
    final Map<String, VoidCallback> infoTapActions = {
      AppTextStrings.notice: () =>
          context.push('/info/${AppTextStrings.notice}'),
      AppTextStrings.languageSettings: () =>
          context.push('/info/${AppTextStrings.languageSettings}'),
      AppTextStrings.termsOfService: () =>
          context.push('/info/${AppTextStrings.termsOfService}'),
      AppTextStrings.privacyPolicy: () =>
          context.push('/info/${AppTextStrings.privacyPolicy}'),
    };

    final Map<String, VoidCallback> etcTapActions = {
      AppTextStrings.logout: () => showDialog(
            context: context,
            builder: (context) => ConfirmDialog(isDeleteAccount: false),
          ),
      AppTextStrings.deleteAccount: () => context.push('/deleteAccount'),
    };

    return Scaffold(
      backgroundColor: AppColors.yellow50,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        title: AppText(
          AppTextStrings.myPageTitle,
          style: AppFontStyles.heading3,
        ),
      ),
      // actions: [
      //   GestureDetector(
      //     onTap: () {
      //       // TODO 설정 페이지 이동(MVP 이후)
      //     },
      //     child: Container(
      //       width: 50.w,
      //       height: 50.h,
      //       child: Icon(
      //         Icons.settings,
      //         color: Color(0xff333333),
      //         size: 19.2.sp,
      //       ),
      //     ),
      //   ),
      // ],

      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 16.h),
              NicknameEditCard(
                nickname: userNickname,
                isUser: true,
              ),
              SizedBox(height: 16.h),
              _buildSection(
                title: AppTextStrings.customSettings,
                items: [AppTextStrings.characterSettings],
                onTapList: [() => context.push('/characterSetting')],
              ),
              SizedBox(height: 16.h),
              _buildSection(
                title: AppTextStrings.information,
                items: infoTapActions.keys.toList(),
                onTapList: infoTapActions.values.toList(),
              ),
              SizedBox(height: 16.h),
              _buildSection(
                title: AppTextStrings.etc,
                items: etcTapActions.keys.toList(),
                onTapList: etcTapActions.values.toList(),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomBar(),
    );
  }

  Container _buildSection({
    required String title,
    required List<String> items,
    required List<VoidCallback> onTapList,
    Icon? icon,
    Widget? widget,
  }) {
    return Container(
      padding: EdgeInsets.only(top: 16.h, left: 16.w, right: 16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.grey100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            title,
            style: AppFontStyles.bodyBold14.copyWith(
              color: AppColors.grey900,
            ),
          ),
          ...List.generate(
            items.length * 2 - 1,
            (index) => index.isEven
                ? GestureDetector(
                    onTap: onTapList[index ~/ 2],
                    child: _buildSettingItem(
                      title: items[index ~/ 2],
                      icon: icon,
                      widget: widget,
                    ),
                  )
                : Divider(
                    height: 1.h,
                    color: AppColors.grey100,
                  ),
          ),
        ],
      ),
    );
  }

  Container _buildSettingItem({
    required String title,
    Icon? icon,
    Widget? widget,
  }) {
    return Container(
      color: AppColors.white,
      height: 48.h,
      child: Row(
        children: [
          AppText(
            title,
            style: AppFontStyles.bodyRegular16.copyWith(
              color: AppColors.grey700,
            ),
          ),
          Spacer(),
          widget ?? Container(),
          icon ??
              Icon(
                Icons.chevron_right,
                color: AppColors.grey700,
                size: 24.sp,
              ),
        ],
      ),
    );
  }
}
