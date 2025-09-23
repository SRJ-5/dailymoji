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
  String userNickname = "치키차카초코";

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

  String selectedCharacterOption = "문제 해결을 잘함";

  List<String> characterOptions = [
    "문제 해결을 잘함",
    "감정 풍부하고 따뜻함",
    "엉뚱하지만 따뜻함",
    "따뜻함과 이성 모두 가짐",
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
                    color: AppColors.green100,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.grey200,
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
                              userNickname,
                              style: AppFontStyles.bodyRegular16.copyWith(
                                color: AppColors.grey700,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            GestureDetector(
                              onTap: () {
                                _showEditUserNicknameDialog(context);
                              },
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
                onTapList: [
                  ...List.generate(
                    1,
                    (index) => () async {
                      final result = await showMenu<String>(
                        context: context,
                        position: RelativeRect.fromLTRB(183.w, 293.h, 0, 0),
                        color: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          side: BorderSide(color: AppColors.grey100),
                        ),
                        items: characterOptions.map((e) {
                          return PopupMenuItem<String>(
                            value: e,
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: e,
                                  groupValue: selectedCharacterOption,
                                  activeColor: AppColors.green400,
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  onChanged: (_) {
                                    // Navigator.pop(context, e); // 선택 시 메뉴 닫고 값 반환
                                  },
                                ),
                                Expanded(
                                  child: Text(
                                    e,
                                    style: AppFontStyles.bodyRegular14.copyWith(
                                      color: AppColors.grey900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                      if (result != null) {
                        setState(() {
                          selectedCharacterOption = result;
                        });
                      }
                    },
                  ),
                ],
                widget: Text(
                  selectedCharacterOption,
                  style: AppFontStyles.bodyRegular14.copyWith(
                    color: AppColors.grey500,
                  ),
                ),
                icon: Icon(
                  Icons.unfold_more,
                  color: AppColors.grey700,
                  size: 24.sp,
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.grey100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
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
          Text(
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

  Future<void> _showEditUserNicknameDialog(BuildContext context) async {
    final TextEditingController controller =
        TextEditingController(text: userNickname);

    String? result = await showDialog(
      context: context,
      barrierDismissible: false, // 바깥 터치로 닫히지 않게
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // 둥근 모서리
          ),
          contentPadding: EdgeInsets.all(24.r),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "프로필 수정",
                style: AppFontStyles.heading3.copyWith(
                  color: AppColors.grey900,
                ),
              ),
              SizedBox(height: 12.h),
              Divider(
                color: AppColors.grey100,
                height: 1.h,
              ),
              SizedBox(height: 12.h),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.green50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.grey200,
                        width: 1.sp,
                      ),
                    ),
                  ),
                ),
              ),
              Text(
                "3~10자만 사용 가능해요",
                style: AppFontStyles.bodyRegular12.copyWith(
                  color: AppColors.grey700,
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: EdgeInsets.only(
                          top: 8.h, bottom: 8.h, left: 16.w, right: 10.w),
                      child: Text(
                        "취소",
                        style: AppFontStyles.bodyMedium14.copyWith(
                          color: AppColors.grey700,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // 저장 로직
                      print("닉네임: ${controller.text}");
                      final nickname = controller.text;
                      Navigator.pop(context, nickname);
                    },
                    child: Container(
                      padding: EdgeInsets.only(
                          top: 8.h, bottom: 8.h, left: 16.w, right: 10.w),
                      child: Text(
                        "완료",
                        style: AppFontStyles.bodyMedium14.copyWith(
                          color: AppColors.green600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        userNickname = result;
      });
    }
  }
}
