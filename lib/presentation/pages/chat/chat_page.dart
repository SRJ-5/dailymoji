import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatPage extends StatefulWidget {
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  bool showEmojiBar = false;
  String selectedEmojiAsset = "assets/images/smile.png";
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFEFBF4),
      appBar: AppBar(
        backgroundColor: Color(0xFFFEFBF4),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 16.r,
              backgroundImage: NetworkImage("https://picsum.photos/300/200"),
            ),
            SizedBox(width: 12.r),
            Text(
              "모지모지",
              style: TextStyle(
                fontSize: 14.sp,
                color: Color(0xFF333333),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.sp,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsetsGeometry.symmetric(horizontal: 12.w),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: 10,
                itemBuilder: (context, index) {
                  //
                },
              ),
            ),
            if (showEmojiBar) _buildEmojiBar(),
            _buildInputField(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiBar() {
    final emojiAssets = [
      "assets/images/angry.png",
      "assets/images/crying.png",
      "assets/images/shocked.png",
      "assets/images/sleeping.png",
      "assets/images/smile.png",
    ];
    return Container(
      color: Colors.grey[200],
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      child: Wrap(
        spacing: 8.w,
        children: emojiAssets
            .map(
              (e) => GestureDetector(
                onTap: () {
                  //
                  setState(() {
                    selectedEmojiAsset = e;
                  });
                },
                child: ColorFiltered(
                  colorFilter: selectedEmojiAsset != e
                      ? ColorFilter.matrix(<double>[
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0,
                          0,
                          0,
                          1,
                          0,
                        ])
                      : ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                  child: Image.asset(
                    e,
                    width: 34.w,
                    height: 34.h,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildInputField() {
    return SafeArea(
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: "무엇이든 입력하세요",
          hintStyle: const TextStyle(color: Color(0xFF777777)),
          fillColor: Colors.white,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

          // 모든 상태에 동일하게 적용
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(
              color: Color(0xFFD2D2D2),
              width: 1,
            ),
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() => showEmojiBar = !showEmojiBar);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
                  child: Image.asset(
                    selectedEmojiAsset,
                    width: 24.w,
                    height: 24.h,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  // 전송 로직
                },
                child: Container(
                  width: 40.67.w,
                  height: 40.h,
                  child: Image.asset(
                    "assets/icons/send_icon.png",
                    color: Color(0xff777777),
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
