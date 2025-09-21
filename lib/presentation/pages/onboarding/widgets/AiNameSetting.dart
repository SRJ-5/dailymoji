import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/onboarding_view_model.dart';
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
  bool isNameCheck = true;
  final TextEditingController _textEditingController =
      TextEditingController();

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
          height: 24.h,
        ),
        Container(
          width: double.infinity,
          height: 94.h,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '캐릭터에게\n멋진 이름을 지어주세요',
              softWrap: true,
              overflow: TextOverflow.visible,
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold),
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
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextField(
                maxLength: 10,
                controller: _textEditingController,
                onChanged: (value) {
                  final isValid = value.length >= 3;
                  setState(() {
                    if (value.isEmpty) {
                      isNameCheck = true;
                    } else {
                      isNameCheck = isValid;
                    }
                    // final length = value.length;
                    // if (length == 0) {
                    //   isNameCheck = true;
                    // } else if (length < 3) {
                    //   isNameCheck = false;
                    // } else {
                    //   isNameCheck = true;
                    // }
                  });
                  // TODO: ViewModel로 상태 관리 하여 저장
                  ref
                      .watch(
                          onboardingViewModelProvider.notifier)
                      .changeStep12(isValid);
                },
                decoration: InputDecoration(
                    counterText: '',
                    hintText: '캐릭터 이름을 적어주세요',
                    hintStyle:
                        TextStyle(color: AppColors.grey400),
                    suffixIcon:
                        _textEditingController.text.isEmpty
                            ? null
                            : IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () {
                                  _textEditingController.clear();
                                  setState(() {
                                    isNameCheck = true;
                                  });
                                  ref
                                      .watch(
                                          onboardingViewModelProvider
                                              .notifier)
                                      .changeStep12(false);
                                },
                              ),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    filled: true,
                    fillColor: AppColors.green50,
                    border: OutlineInputBorder(
                        borderSide: BorderSide(
                            width: 1, color: AppColors.grey200),
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            width: 1, color: AppColors.green500),
                        borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            width: 1, color: AppColors.grey200),
                        borderRadius:
                            BorderRadius.circular(12))),
              ),
            ),
          ),
        ),
        Text(
          '• 3~10자만 사용 가능해요',
          style: TextStyle(
              color: isNameCheck
                  ? AppColors.grey700
                  : AppColors.orange500),
        ),
        Text(
          '• 나중에 언제든지 변경할 수 있어요',
          style: TextStyle(color: AppColors.grey700),
        )
      ],
    );
  }
}
