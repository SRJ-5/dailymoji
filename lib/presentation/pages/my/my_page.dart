import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/presentation/widgets/bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyPage extends StatefulWidget {
  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
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
    return Scaffold(
      backgroundColor: AppColors.yellow50,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        title: Text(
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
              SizedBox(height: 8.h),
              GestureDetector(
                onTap: () {
                  // TODO 유저 닉네임 변경 페이지
                },
                child: Container(
                  padding: EdgeInsets.only(top: 16.h, left: 16.w, right: 16.w),
                  decoration: BoxDecoration(
                    color: Color(0xffE8EBE0),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Color(0xffd2d2d2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "닉네임",
                        style: AppFontStyles.bodyBold14.copyWith(
                          color: AppColors.grey900,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        child: Row(
                          children: [
                            Text(
                              "치키차카초코",
                              style: AppFontStyles.bodyRegular16.copyWith(
                                color: AppColors.grey700,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            GestureDetector(
                              onTap: () {},
                              child: Icon(
                                Icons.edit,
                                color: AppColors.grey900,
                                size: 24.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              _buildSection(
                title: "맞춤 설정",
                items: ["캐릭터 성격"],
                onTapList: [...List.generate(1, (index) => () {})],
                widget: Text(
                  "문제 해결을 잘함",
                  style: AppFontStyles.bodyRegular14.copyWith(
                    color: AppColors.grey500,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              _buildSection(
                title: "정보",
                items: ["공지사항", "언어 설정", "이용 약관"],
                onTapList: [...List.generate(3, (index) => () {})],
              ),
              SizedBox(height: 16.h),
              _buildSection(
                title: "기타",
                items: ["로그아웃", "회원 탈퇴"],
                onTapList: [...List.generate(2, (index) => () {})],
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
      padding: EdgeInsets.only(top: 16.h, left: 16.w, right: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Color(0xffE8E8E8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Color(0xff333333),
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          ...List.generate(
            items.length * 2 - 1,
            (index) => index.isEven
                ? GestureDetector(
                    onTap: onTapList[index ~/ 2],
                    child: _buildSurveyItem(
                      title: items[index ~/ 2],
                      icon: icon,
                      widget: widget,
                    ),
                  )
                : Divider(
                    height: 1.h,
                    color: Color(0xFFE8E8E8),
                  ),
          ),
        ],
      ),
    );
  }

  Container _buildSurveyItem({
    required String title,
    Icon? icon,
    Widget? widget,
  }) {
    return Container(
      height: 48.h,
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: Color(0xff333333),
              fontSize: 16.sp,
              letterSpacing: 0,
            ),
          ),
          Spacer(),
          widget ?? Container(),
          icon ??
              Icon(
                Icons.chevron_right,
                color: Color(0xFF606060),
                size: 24.sp,
              ),
        ],
      ),
    );
  }
}
