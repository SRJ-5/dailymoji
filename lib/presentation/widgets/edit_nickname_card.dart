import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/user_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NicknameEditCard extends ConsumerStatefulWidget {
  const NicknameEditCard({
    required this.nickname,
    required this.isUser,
  });

  final String nickname;
  final bool isUser;

  @override
  ConsumerState<NicknameEditCard> createState() =>
      _NicknameEditCardState();
}

class _NicknameEditCardState
    extends ConsumerState<NicknameEditCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.only(top: 16.h, left: 16.w, right: 16.w),
      decoration: BoxDecoration(
        color:
            widget.isUser ? AppColors.green100 : AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: widget.isUser
              ? AppColors.grey200
              : AppColors.grey100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isUser ? "닉네임" : "캐릭터 이름",
            style: AppFontStyles.bodyBold14.copyWith(
              color: AppColors.grey900,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Row(
              children: [
                Text(
                  widget.nickname,
                  style: AppFontStyles.bodyRegular16.copyWith(
                    color: AppColors.grey700,
                  ),
                ),
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: () {
                    _showEditNicknameDialog(
                        context, widget.nickname);
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
    );
  }

  Future<void> _showEditNicknameDialog(
      BuildContext context, String nickname) async {
    final TextEditingController controller =
        TextEditingController(text: nickname);
    int nicknameLength = controller.text.length;

    String? result = await showDialog(
      context: context,
      barrierDismissible: false, // 바깥 터치로 닫히지 않게
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setStateDialog) {
          final len = controller.text.length;
          final invalid = len < 2 || len > 10;
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
                    onChanged: (value) {
                      setStateDialog(() {});
                    },
                    maxLines: 1,
                    maxLength: 10,
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
                  "2~10자만 사용 가능해요",
                  style: AppFontStyles.bodyRegular12.copyWith(
                    color: invalid
                        ? AppColors.orange500
                        : AppColors.grey700,
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
                            top: 8.h,
                            bottom: 8.h,
                            left: 16.w,
                            right: 10.w),
                        child: Text(
                          "취소",
                          style: AppFontStyles.bodyMedium14
                              .copyWith(
                            color: AppColors.grey700,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (invalid) return;
                        final nickname = controller.text;
                        Navigator.pop(context, nickname);
                      },
                      child: Container(
                        padding: EdgeInsets.only(
                            top: 8.h,
                            bottom: 8.h,
                            left: 16.w,
                            right: 10.w),
                        child: Text(
                          "완료",
                          style: AppFontStyles.bodyMedium14
                              .copyWith(
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
        });
      },
    );

    if (result != null && result.isNotEmpty) {
      widget.isUser
          ? ref
              .read(userViewModelProvider.notifier)
              .updateUserNickNM(newUserNickNM: result)
          : ref
              .read(userViewModelProvider.notifier)
              .updateCharacterNM(newCharacterNM: result);
    }
  }
}
