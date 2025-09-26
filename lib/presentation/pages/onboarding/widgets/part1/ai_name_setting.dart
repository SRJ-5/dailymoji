import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/core/styles/images.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/user_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AiNameSetting extends ConsumerStatefulWidget {
  const AiNameSetting({
    super.key,
  });

  @override
  ConsumerState<AiNameSetting> createState() =>
      _AiNameSettingState();
}

class _AiNameSettingState extends ConsumerState<AiNameSetting> {
  bool _isNameCheck = true;
  TextEditingController _textEditingController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController(
        text: ref
            .read(userViewModelProvider)
            .userProfile
            ?.characterNm);
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              '캐릭터에게\n멋진 이름을 지어주세요',
              style: AppFontStyles.heading2,
            ),
          ),
        ),
        SizedBox(
          height: 24.h,
        ),
        Align(
          alignment: Alignment.center,
          child: Container(
            width: double.infinity,
            height: 64.h,
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextField(
                maxLength: 10,
                controller: _textEditingController,
                style: AppFontStyles.bodyRegular16
                    .copyWith(color: AppColors.grey900),
                onChanged: (value) {
                  final isValid = value.length >= 2;
                  setState(() {
                    if (value.isEmpty) {
                      _isNameCheck = true;
                    } else {
                      _isNameCheck = isValid;
                    }
                  });
                  ref
                      .watch(userViewModelProvider.notifier)
                      .setAiName(check: isValid, aiName: value);
                },
                decoration: InputDecoration(
                    counterText: '',
                    hintText: '캐릭터 이름을 적어주세요',
                    hintStyle: AppFontStyles.bodyRegular16
                        .copyWith(color: AppColors.grey400),
                    suffixIcon: _textEditingController
                            .text.isEmpty
                        ? null
                        : IconButton(
                            icon: Icon(
                              Icons.clear,
                              size: 24.r,
                            ),
                            onPressed: () {
                              _textEditingController.clear();
                              setState(() {
                                _isNameCheck = true;
                              });
                              ref
                                  .watch(userViewModelProvider
                                      .notifier)
                                  .setAiName(
                                      check: false, aiName: '');
                            },
                          ),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w, vertical: 12.h),
                    filled: true,
                    fillColor: AppColors.green50,
                    border: OutlineInputBorder(
                        borderSide: BorderSide(
                            width: 1, color: AppColors.grey200),
                        borderRadius:
                            BorderRadius.circular(12.r)),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            width: 1, color: AppColors.green500),
                        borderRadius:
                            BorderRadius.circular(12.r)),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            width: 1, color: AppColors.grey200),
                        borderRadius:
                            BorderRadius.circular(12.r))),
              ),
            ),
          ),
        ),
        Text('• 2~10자만 사용 가능해요',
            style: AppFontStyles.bodyRegular12.copyWith(
                color: _isNameCheck
                    ? AppColors.grey700
                    : AppColors.noti900)),
        Text(
          '• 나중에 언제든지 변경할 수 있어요',
          style: AppFontStyles.bodyRegular12
              .copyWith(color: AppColors.grey700),
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
    );
  }
}
