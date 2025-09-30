import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/presentation/pages/my/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DeleteAccountPage extends StatefulWidget {
  @override
  State<DeleteAccountPage> createState() =>
      _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final TextEditingController _textEditingController =
      TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.yellow50,
        appBar: AppBar(
          backgroundColor: AppColors.yellow50,
          title: Text(
            '회원 탈퇴',
            style: AppFontStyles.bodyBold18
                .copyWith(color: AppColors.grey900),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(
                  horizontal: 12.w, vertical: 16.h)
              .copyWith(top: 16.h),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '떠나신다니 아쉬워요 🥲',
                        style: AppFontStyles.bodyBold16
                            .copyWith(color: AppColors.grey900),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        '저희 서비스가 아직 부족했나 봐요. 만족을 드리지 못해 죄송합니다. 더 좋은 경험을 드릴 수 있도록 노력하겠습니다.',
                        style: AppFontStyles.bodyRegular14
                            .copyWith(color: AppColors.grey900),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        '탈퇴 전, 꼭 확인해 주세요',
                        style: AppFontStyles.bodyBold16.copyWith(
                            color: AppColors.orange700),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        ' ∙ 지금까지 저장된 대화 내역과 데이터는 모두 삭제돼요.\n ∙ 다시 가입하셔도 예전 기록은 복구되지 않아요.\n ∙ 회원 탈퇴 후 3개월간 재가입이 불가능해요.',
                        style: AppFontStyles.bodyRegular14
                            .copyWith(color: AppColors.grey900),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 17.h,
                  decoration: BoxDecoration(
                    border: BoxBorder.fromLTRB(
                        bottom: BorderSide(
                            width: 1, color: AppColors.grey100)),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16.h),
                      Text(
                        '무엇이 불편하셨나요?',
                        style: AppFontStyles.bodyBold16
                            .copyWith(color: AppColors.grey900),
                      ),
                      SizedBox(
                        height: 144.h,
                        child: Column(
                          children: [
                            ReasonBox(text: '더 이상 앱을 사용하지 않아요'),
                            ReasonBox(text: '원하는 기능이 없어요'),
                            ReasonBox(text: '사용이 불편했어요'),
                            ReasonBox(text: '직접 입력'),
                          ],
                        ),
                      ),
                      SizedBox(
                          width: double.infinity,
                          height: 48.h,
                          child: TextField(
                            focusNode: _focusNode,
                            controller: _textEditingController,
                            style: AppFontStyles.bodyRegular16
                                .copyWith(
                                    color: AppColors.grey900),
                            decoration: InputDecoration(
                                hintText: '의견을 적어주세요',
                                hintStyle: AppFontStyles.bodyRegular16
                                    .copyWith(
                                        color:
                                            AppColors.grey400),
                                suffixIcon: _textEditingController
                                        .text.isEmpty
                                    ? null
                                    : IconButton(
                                        onPressed: () {
                                          _textEditingController
                                              .clear();
                                        },
                                        icon: Icon(Icons.clear)),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 12.h),
                                filled: true,
                                fillColor: AppColors.green50,
                                border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        width: 1,
                                        color:
                                            AppColors.grey200),
                                    borderRadius:
                                        BorderRadius.circular(
                                            12.r)),
                                focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        width: 1,
                                        color:
                                            AppColors.green500),
                                    borderRadius:
                                        BorderRadius.circular(12.r)),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      width: 1,
                                      color: AppColors.grey200),
                                  borderRadius:
                                      BorderRadius.circular(
                                          12.r),
                                )),
                          ))
                    ],
                  ),
                ),
                ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return ConfirmDialog(
                            isDeleteAccount: true,
                          );
                        },
                      );
                    },
                    child: Text('탈퇴하기'))
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReasonBox extends StatelessWidget {
  final String text;
  const ReasonBox({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 16.h,
            height: 16.h,
            decoration: BoxDecoration(
                color: AppColors.grey50,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.grey200)),
          ),
          SizedBox(width: 8.w),
          Text(
            text,
            style: AppFontStyles.bodyRegular14
                .copyWith(color: AppColors.grey900),
          )
        ],
      ),
    );
  }
}
