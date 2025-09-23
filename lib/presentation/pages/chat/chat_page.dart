// lib/presentation/pages/chat/chat_page.dart
// 0924 변경:
// 1. 홈에서 전달받은 이모지 처리를 위해 `emotionFromHome` 파라미터 추가.
// 2. `initState`에서 `emotionFromHome`이 있으면 ViewModel의 `sendEmojiAsMessage` 호출.
// 3. 자동 스크롤을 위한 `ScrollController` 추가 및 구현.
// 4. AppBar의 title을 userViewModelProvider와 연동하여 동적으로 character_nm을 표시.

import 'package:dailymoji/domain/entities/message.dart';
import 'package:dailymoji/presentation/pages/chat/chat_view_model.dart';
import 'package:dailymoji/presentation/pages/chat/widgets/triangle_painter.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/user_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String? emotionFromHome;

  const ChatPage({super.key, this.emotionFromHome});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage>
    with SingleTickerProviderStateMixin {
  bool showEmojiBar = false;
  String selectedEmojiAsset = "assets/images/smile.png";
  final _messageInputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _emojiCtrl;

  @override
  void initState() {
    super.initState();
    _emojiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700), // 전체 타이밍
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 홈에서 이모지를 선택하고 들어온 경우에만,
      // selectedEmojiAsset 값을 해당 이모지 경로로 덮어쓰고 분석 시작

      if (widget.emotionFromHome != null) {
        final assetPath = "assets/images/${widget.emotionFromHome!}.png";
        setState(() {
          selectedEmojiAsset = assetPath;
        });
        ref
            .read(chatViewModelProvider.notifier)
            .sendEmojiAsMessage(widget.emotionFromHome!);
      }
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageInputController.dispose();
    _scrollController.dispose();
    _emojiCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _toggleEmojiBar() {
    setState(() => showEmojiBar = !showEmojiBar);
    if (showEmojiBar) {
      _emojiCtrl.forward(from: 0); // 열릴 때만 애니메이션 재생
    }
  }

  String _formattedNow(DateTime date) {
    return DateFormat("HH:mm").format(date);
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatViewModelProvider);
    // 캐릭터 이름 연동
    final userState = ref.watch(userViewModelProvider);
    final characterName = userState.userProfile?.characterNm ?? "모지모지";
    final characterImageUrl = userState.userProfile?.aiCharacter; // 캐릭터 프사

    ref.listen(chatViewModelProvider.select((state) => state.messages),
        (_, __) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    });

    return Scaffold(
      backgroundColor: Color(0xFFFEFBF4),
      appBar: AppBar(
        backgroundColor: Color(0xFFFEFBF4),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // 중앙 정렬을 위해 추가

          children: [
            CircleAvatar(
              radius: 16.r,
              backgroundImage:
                  (characterImageUrl != null && characterImageUrl.isNotEmpty)
                      ? NetworkImage(characterImageUrl)
                      : const AssetImage("assets/images/cado_profile.png")
                          as ImageProvider,
            ),
            SizedBox(width: 12.r),
            Text(
              characterName,
              style: TextStyle(
                fontSize: 14.sp,
                color: Color(0xFF333333),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.sp,
              ),
            ),
          ],
        ),
        centerTitle: true,
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
                    controller: _scrollController,
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      final message = chatState.messages[index];
                      // 메시지 타입에 따라 다른 위젯을 보여주도록 분기 처리
                      if (message.sender == Sender.user) {
                        return _userMessage(message);
                      } else {
                        switch (message.type) {
                          case MessageType.analysis:
                            return _analysisMessage(message.content);
                          case MessageType.solutionProposal:
                            return _solutionProposalMessage(message);
                          default:
                            return _botMessage(
                                message.content, message.createdAt);
                        }
                      }
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

// 분석 중 메시지를 표시하기 위한 위젯
  Widget _analysisMessage(String message) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            message,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }

  Widget _userMessage(Message message) {
    // 메시지 타입에 따라 다른 내용을 표시할 위젯 변수
    Widget messageContent;

// branching: 메시지 타입이 'image'이고 이미지 경로가 있으면 Image 위젯을, 아니면 Text 위젯을 표시
    if (message.type == MessageType.image && message.imageAssetPath != null) {
      messageContent = Image.asset(
        message.imageAssetPath!,
        width: 100.w, // 필요에 따라 이미지 크기 조절
        height: 100.w,
      );
    } else {
      messageContent = Text(
        message.content, // 일반 텍스트 메시지 내용
        maxLines: 4,
        softWrap: true,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Color(0xff4A5565),
          letterSpacing: 0.sp,
          fontSize: 14.sp,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formattedNow(message.createdAt),
            style: TextStyle(
              fontSize: 14.sp,
              letterSpacing: 0.sp,
              color: Color(0xff4A5565),
            ),
          ),
          SizedBox(width: 4.r),
          Container(
            // 이미지일 경우와 텍스트일 경우 다른 패딩
            padding: message.type == MessageType.image
                ? EdgeInsets.all(2.r)
                : EdgeInsets.all(16.r),
            constraints: BoxConstraints(maxWidth: 247.w),
            decoration: BoxDecoration(
              color: Color(0xffBAC4A1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                bottomRight: Radius.circular(12.r),
                bottomLeft: Radius.circular(12.r),
              ),
            ),
            child: messageContent, //위에서 만든 위젯을 여기에 배치
          ),
        ],
      ),
    );
  }

  Widget _botMessage(String message, DateTime? date) {
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
            _formattedNow(date ?? DateTime.now()),
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

  Widget _solutionProposalMessage(Message message) {
    final proposal = message.proposal!;
    final options = (proposal['options'] as List).cast<Map<String, dynamic>>();

    // 봇 메시지 위젯을 재사용하여 텍스트를 표시하고, 아래에 버튼을 추가합니다.
    return Column(
      children: [
        _botMessage(message.content, message.createdAt),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: options.map((option) {
            return Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xffF8DA9C),
                  foregroundColor: Color(0xff4A5565),
                ),
                onPressed: () {
                  // 버튼을 누르면 ViewModel의 함수를 호출합니다.
                  ref.read(chatViewModelProvider.notifier).respondToSolution(
                        proposal['solution_id'] as String,
                        option['action'] as String,
                      );
                },
                child: Text(option['label'] as String),
              ),
            );
          }).toList(),
        )
      ],
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
                            : const ColorFilter.mode(
                                Colors.transparent, BlendMode.multiply),
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
              final chatVm = ref.read(chatViewModelProvider.notifier);
              // TODO 전송 로직
              final text = _messageInputController.text.trim();
              if (text.isNotEmpty) {
                final message = Message(
                  userId: "c4349dd9-39f2-4788-a175-6ec4bd4f7aba",
                  content: text,
                  sender: Sender.user,
                  type: MessageType.normal,
                  createdAt: DateTime.now(),
                );
                // ViewModel에 메시지와 함께 선택된 이모지 정보를 전달
                final selectedEmotion =
                    selectedEmojiAsset.split('/').last.split('.').first;
                chatVm.sendMessage(message, selectedEmotion);
                _messageInputController.clear();
              }
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
