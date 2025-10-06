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
  List<String> surveyTitles = [
    "우울 진단 검사하기",
    "스트레스 진단 검사하기",
    "불안 진단 검사하기",
    "번아웃 진단 검사하기",
    "자존감 진단 검사하기",
    "ADHD 진단 검사하기",
  ];

  List<String> userSettingTitles = [
    "캐릭터 설정",
    "튜토리얼",
    "알림 설정",
  ];

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userViewModelProvider);
    // 상태 초기화 시 userNickNm이 널이 되어서 화면이 깨지는 현상 때문에 ''를 넣음
    final String userNickname =
        userState.userProfile?.userNickNm ?? '';
    return Scaffold(
      backgroundColor: AppColors.yellow50,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        title: AppText(
          "마이페이지",
          style: AppFontStyles.heading3.copyWith(
            color: AppColors.grey900,
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
      ),
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
                title: "맞춤 설정",
                items: ["캐릭터 설정"],
                onTapList: [
                  ...List.generate(
                    1,
                    (index) => () {
                      context.push('/characterSetting');
                    },
                  )
                ],
              ),
              SizedBox(height: 16.h),
              _buildSection(
                title: "정보",
                items: ["공지사항", "언어 설정", "이용 약관", "개인정보 처리방침"],
                onTapList: [
                  ...List.generate(
                    4,
                    (index) => () {
                      final title = [
                        "공지사항",
                        "언어 설정",
                        "이용 약관",
                        "개인정보 처리방침"
                      ][index];
                      context.push(
                          // index == 3
                          //   ? '/privacyPolicy'
                          //   :
                          '/info/$title');
                    },
                  )
                ],
              ),
              SizedBox(height: 16.h),
              _buildSection(
                title: "기타",
                items: ["로그아웃", "회원 탈퇴"],
                onTapList: [
                  ...List.generate(
                    2,
                    (index) => () {
                      final title = ["로그아웃", "회원 탈퇴"][index];
                      switch (title) {
                        case "로그아웃":
                          showDialog(
                            context: context,
                            builder: (context) {
                              return ConfirmDialog(
                                isDeleteAccount: false,
                              );
                            },
                          );
                        case "회원 탈퇴":
                        default:
                          context.push('/deleteAccount');
                      }
                    },
                  )
                ],
              ),
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
      padding:
          EdgeInsets.only(top: 16.h, left: 16.w, right: 16.w),
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
