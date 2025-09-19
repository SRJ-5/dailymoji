import 'package:flutter/material.dart';

class AiNameSetting extends StatefulWidget {
  const AiNameSetting({
    super.key,
  });

  @override
  State<AiNameSetting> createState() => _AiNameSettingState();
}

class _AiNameSettingState extends State<AiNameSetting> {
  TextEditingController textEditingController =
      TextEditingController();

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 10,
        ),
        Text(
          'Moji 캐릭터는 사용자의 감정을 분석하여 솔루션을 주고 대화를 할 수 있는 Ai 캐릭터 입니다.',
          softWrap: true,
          overflow: TextOverflow.visible,
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w500),
        ),
        SizedBox(
          height: 20,
        ),
        Text(
          'Moji의 이름을 입력해 주세요.',
          style: TextStyle(fontSize: 20),
        ),
        SizedBox(
          height: 60,
        ),
        Align(
          alignment: Alignment.center,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 30),
            width: double.infinity,
            height: 50,
            child: TextField(
              controller: textEditingController,
              onChanged: (value) {
                // TODO: ViewModel로 상태 관리 하여 저장
              },
              decoration: InputDecoration(
                  hintText: '햄보카도',
                  hintStyle: TextStyle(color: Colors.grey),
                  contentPadding: EdgeInsets.all(12),
                  border: OutlineInputBorder(
                      borderSide: BorderSide(
                          width: 2, color: Colors.amber),
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          width: 2, color: Colors.amber),
                      borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          width: 2, color: Colors.amber),
                      borderRadius: BorderRadius.circular(12))),
            ),
          ),
        )
      ],
    );
  }
}
