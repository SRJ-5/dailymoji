import 'package:dailymoji/presentation/pages/chat/widgets/triangle_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with SingleTickerProviderStateMixin {
  bool showEmojiBar = false;
  String selectedEmojiAsset = "assets/images/smile.png";
  final _messageInputController = TextEditingController();

  late final AnimationController _emojiCtrl;

  @override
  void initState() {
    super.initState();
    _emojiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700), // 전체 타이밍
    );
  }

  @override
  void dispose() {
    _messageInputController.dispose();
    _emojiCtrl.dispose();
    super.dispose();
  }

  void _toggleEmojiBar() {
    setState(() => showEmojiBar = !showEmojiBar);
    if (showEmojiBar) {
      _emojiCtrl.forward(from: 0); // 열릴 때만 애니메이션 재생
    }
  }

  String _formattedNow() {
    return DateFormat("HH:mm").format(DateTime.now());
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
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: EdgeInsetsGeometry.symmetric(horizontal: 12.w),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    reverse: true, // 최신 메세지가 맨 밑에 보여지게
                    itemCount: 10,
                    itemBuilder: (context, index) {
                      return index % 2 == 0 ? _botMessage("수니슈니님, 오늘 왜 화가 났어요?") : _userMessage("아 그냥 별거 아닌 일들이 계속 겹치니까 괜히 짜증나더라");
                    },
                  ),
                ),
                _buildInputField(),
              ],
            ),
          ),
          if (showEmojiBar)
            Positioned(
              bottom: 99.h,
              right: 12.w,
              child: Material(
                color: Colors.transparent,
                child: _buildEmojiBarAnimated(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _userMessage(String message) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formattedNow(),
            style: TextStyle(
              fontSize: 14.sp,
              letterSpacing: 0.sp,
              color: Color(0xff4A5565),
            ),
          ),
          SizedBox(width: 4.r),
          Container(
            padding: EdgeInsets.all(16.r),
            constraints: BoxConstraints(maxWidth: 247.w),
            decoration: BoxDecoration(
              color: Color(0xffBAC4A1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                bottomRight: Radius.circular(12.r),
                bottomLeft: Radius.circular(12.r),
              ),
            ),
            child: Text(
              message,
              maxLines: 4,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xff4A5565),
                letterSpacing: 0.sp,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botMessage(String message) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: EdgeInsets.all(16.r),
            constraints: BoxConstraints(maxWidth: 247.w),
            decoration: BoxDecoration(
              color: Color(0xffF8DA9C),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(12.r),
                bottomRight: Radius.circular(12.r),
                bottomLeft: Radius.circular(12.r),
              ),
            ),
            child: Text(
              message,
              maxLines: 4,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xff4A5565),
                letterSpacing: 0.sp,
                fontSize: 14.sp,
              ),
            ),
          ),
          SizedBox(width: 4.r),
          Text(
            _formattedNow(),
            style: TextStyle(
              fontSize: 14.sp,
              letterSpacing: 0.sp,
              color: Color(0xff4A5565),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiBarAnimated() {
    final emojiAssets = [
      "assets/images/angry.png",
      "assets/images/crying.png",
      "assets/images/shocked.png",
      "assets/images/sleeping.png",
      "assets/images/smile.png",
    ];

    // 0.0~0.25 구간: 배경 페이드인
    final bgOpacity = CurvedAnimation(
      parent: _emojiCtrl,
      curve: const Interval(0.0, 0.25, curve: Curves.easeOutCubic),
    );

    // 스태거 간격(각 이모지 시작 시점 간격)
    const step = 0.1; // 100ms 간격 느낌
    final baseStart = 0.25; // 배경이 떠오른 뒤부터 시작

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 배경만 먼저 페이드인
        FadeTransition(
          opacity: bgOpacity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 5),
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Opacity(
                  opacity: 0, // 보이지 않게
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(emojiAssets.length, (index) {
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: SizedBox(width: 34.w, height: 34.h),
                      );
                    }),
                  ),
                ),
              ),
              Positioned(
                bottom: -3.6.h,
                right: 40.w,
                child: CustomPaint(
                  size: Size(34.w, 8.h),
                  painter: TrianglePainter(Colors.white),
                ),
              ),
            ],
          ),
        ),

        Container(
          margin: const EdgeInsets.only(bottom: 5),
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            // color: Colors.transparent
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(emojiAssets.length, (index) {
              final start = (baseStart + step * index).clamp(0.0, 1.0);
              final end = (start + 0.4).clamp(0.0, 1.0);

              final curved = CurvedAnimation(
                parent: _emojiCtrl,
                curve: Interval(start, end, curve: Curves.easeOutCubic),
              );

              return FadeTransition(
                opacity: curved,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(-0.2, 0),
                    end: Offset.zero,
                  ).animate(curved),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => selectedEmojiAsset = emojiAssets[index]);
                      },
                      child: ColorFiltered(
                        colorFilter: selectedEmojiAsset != emojiAssets[index]
                            ? const ColorFilter.matrix(<double>[
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
                            : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                        child: Image.asset(
                          emojiAssets[index],
                          width: 34.w,
                          height: 34.h,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField() {
    return Container(
      margin: EdgeInsets.only(bottom: 46.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Color(0xFFD2D2D2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _messageInputController,
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(
                hintText: "무엇이든 입력하세요",
                hintStyle: const TextStyle(color: Color(0xFF777777)),
                fillColor: Colors.white,
                filled: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
                border: InputBorder.none,
              ),
            ),
          ),
          GestureDetector(
            onTap: _toggleEmojiBar,
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
    );
  }
}
