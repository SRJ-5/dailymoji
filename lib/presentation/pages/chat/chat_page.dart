// lib/presentation/pages/chat/chat_page.dart
// 0924 변경:
// 1. 홈에서 전달받은 이모지 처리를 위해 `emotionFromHome` 파라미터 추가.
// 2. `initState`에서 `emotionFromHome`이 있으면 ViewModel의 `sendEmojiAsMessage` 호출.
// 3. 자동 스크롤을 위한 `ScrollController` 추가 및 구현.
// 4. AppBar의 title을 userViewModelProvider와 연동하여 동적으로 character_nm을 표시.

import 'package:dailymoji/core/constants/emoji_assets.dart';
import 'package:dailymoji/domain/entities/message.dart';
import 'package:dailymoji/domain/enums/enum_data.dart';
import 'package:dailymoji/presentation/pages/chat/chat_view_model.dart';
import 'package:dailymoji/presentation/pages/chat/widgets/triangle_painter.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/user_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

//(구분선추가) 날짜 비교를 위한 Helper 함수
bool isSameDay(DateTime date1, DateTime date2) {
  return date1.year == date2.year &&
      date1.month == date2.month &&
      date1.day == date2.day;
}

class ChatPage extends ConsumerStatefulWidget {
  final String? emotionFromHome;

  const ChatPage({super.key, this.emotionFromHome});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage>
    with SingleTickerProviderStateMixin {
  bool showEmojiBar = false;
  late String selectedEmojiAsset;
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

// emotionFromHome이 있으면 그 이모지로, 없으면 'smile'로 초기 상태 설정
    selectedEmojiAsset =
        kEmojiAssetMap[widget.emotionFromHome] ?? kEmojiAssetMap['smile']!;

// Rin: enterChatRoom방식: 홈에서 들어갈때 이 부분 충돌안나게 주의하기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(chatViewModelProvider.notifier)
          .enterChatRoom(widget.emotionFromHome);
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
      if (!_scrollController.hasClients) return;
      // reverse: true 상태에서 맨 아래는 스크롤 위치 0.0을 의미합니다.
      final targetPosition = 0.0;

      // 위젯 렌더링이 완료된 직후에 스크롤해야 정확한 맨 아래 위치로 갈 수 있음
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            targetPosition,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _toggleEmojiBar() {
    setState(() => showEmojiBar = !showEmojiBar);
    if (showEmojiBar) {
      _emojiCtrl.forward(from: 0); // 열릴 때만 애니메이션 재생
    } else {
      _emojiCtrl.reverse();
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

    final messages = chatState.messages.reversed.toList();

    //  메시지 리스트가 변경될 때마다 스크롤을 맨 아래로 이동
    ref.listen(chatViewModelProvider.select((state) => state.messages.length),
        (previous, next) {
      if (next > (previous ?? 0) && !chatState.isLoading) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: Color(0xFFFEFBF4),
      appBar: AppBar(
        automaticallyImplyLeading: true, // backbutton
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
                      : const AssetImage("assets/images/cado_face.png")
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
                  child: chatState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            //  reverse된 리스트에서 올바른 메시지 가져오기
                            final messages = chatState.messages;
                            final reversedIndex = messages.length - 1 - index;
                            final message = messages[reversedIndex];

                            // --- 날짜 구분선 표시 로직 ---
                            bool showDateSeparator = false;
                            if (reversedIndex == 0) {
                              showDateSeparator = true;
                            } else {
                              // 현재 메시지와 시간상 이전 메시지의 날짜를 비교
                              final prevMessageInTime =
                                  chatState.messages[reversedIndex - 1];
                              if (!isSameDay(prevMessageInTime.createdAt,
                                  message.createdAt)) {
                                showDateSeparator = true;
                              }
                            }

                            final messageWidget = _buildMessageWidget(message,
                                key: ValueKey(message.tempId));

                            // reverse: true일 때는 메시지 위젯이 먼저, 구분선이 나중에 와야
                            // 화면에서는 구분선 -> 메시지 순으로 올바르게 보인다!
                            if (showDateSeparator) {
                              return Column(
                                children: [
                                  messageWidget, // 메시지가 먼저 나오고
                                  _DateSeparator(
                                      date: message
                                          .createdAt), // 날짜 구분선이 나중에 나옴 (reverse 효과)
                                ],
                              );
                            }
                            return messageWidget;
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

  // (따로 뺌) --- 메시지 종류에 따라 위젯을 분기하는 Helper 함수 ---
  Widget _buildMessageWidget(Message message, {required Key key}) {
    if (message.sender == Sender.user) {
      return _userMessage(message, key: key);
    } else {
      switch (message.type) {
        case MessageType.analysis:
          return _analysisMessage(message, key: key);
        case MessageType.solutionProposal:
          return _solutionProposalMessage(message, key: key);
        // --- 시스템 메시지 UI case 추가 ---
        case MessageType.system:
          return _systemMessage(message, key: key);
        default:
          return _botMessage(message, key: key);
      }
    }
  }

  // (새로 추가) --- 시스템 메시지 위젯 ---
  Widget _systemMessage(Message message, {required Key key}) {
    return Padding(
      key: key,
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white, // 하얀 네모 박스
            borderRadius: BorderRadius.circular(20.r), // 라운드 처리
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Text(
            message.content,
            style: TextStyle(fontSize: 12.sp, color: Colors.black54),
          ),
        ),
      ),
    );
  }

// 분석 중 메시지를 표시하기 위한 위젯
  Widget _analysisMessage(Message message, {required Key key}) {
    return Padding(
      key: key,
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            message.content,
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

  Widget _userMessage(Message message, {required Key key}) {
    // 메시지 타입에 따라 다른 내용을 표시할 위젯 변수
    Widget messageContent;

// branching: 메시지 타입이 'image'이고 이미지 경로가 있으면 Image 위젯을, 아니면 Text 위젯을 표시
    if (message.type == MessageType.image && message.imageAssetPath != null) {
      print(
          "RIN: ✅ [ChatPage] Rendering image with path: ${message.imageAssetPath}");

      // 동그랗게 만들기! (--> 그래야 하얀 박스안에 들어가지 않음)
      messageContent = ClipRRect(
        borderRadius: BorderRadius.circular(50.r),
        child: Image.asset(
          message.imageAssetPath!,
          width: 100.w,
          height: 100.w,
          fit: BoxFit.cover,
        ),
      );
    } else {
      // 텍스트 메시지
      messageContent = Text(
        message.content,
        style: TextStyle(
          color: const Color(0xff4A5565),
          letterSpacing: 0.sp,
          fontSize: 14.sp,
        ),
      );
    }

    return Padding(
      key: key,
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
            padding: message.type == MessageType.image
                ? EdgeInsets.zero // 이모지는 패딩 찔끔
                : EdgeInsets.all(16.r),
            constraints: BoxConstraints(maxWidth: 247.w),
            decoration: BoxDecoration(
              color: message.type == MessageType.image
                  ? Colors.transparent
                  : Color(0xffBAC4A1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                bottomRight: Radius.circular(12.r),
                bottomLeft: Radius.circular(12.r),
              ),
            ),
            child: Container(child: messageContent), //위에서 만든 위젯을 여기에 배치
          ),
        ],
      ),
    );
  }

  Widget _botMessage(Message message, {required Key key}) {
    return Padding(
      key: key,
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
              message.content,
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
            _formattedNow(message.createdAt),
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

  Widget _solutionProposalMessage(Message message, {required Key key}) {
    final proposal = message.proposal!;
    final options = (proposal['options'] as List).cast<Map<String, dynamic>>();
    debugPrint("RIN: Rendering solution proposal text: ${message.content}");

    // 봇 메시지 위젯을 재사용하여 텍스트를 표시하고, 아래에 버튼을 추가합니다.
    return Column(
      key: key,
      children: [
        _botMessage(message, key: ValueKey('${message.tempId}_text')),
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
    final emojiKeys = kEmojiAssetMap.keys.toList();
    final emojiAssets = kEmojiAssetMap.values.toList();

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
                        // emojiKeys 리스트에서 키 값을 가져옴
                        final selectedEmotionKey = emojiKeys[index];

                        setState(() {
                          selectedEmojiAsset = emojiAssets[index];
                          showEmojiBar = false; // 이모지 바 닫기
                        });
                        // 선택된 이모지를 메시지로 전송
                        ref
                            .read(chatViewModelProvider.notifier)
                            .sendEmojiAsMessage(selectedEmotionKey);

                        _emojiCtrl.reverse(); // 애니메이션 역재생하여 닫기
                      },
                      child: ColorFiltered(
                        colorFilter: selectedEmojiAsset != emojiAssets[index]
                            ? const ColorFilter.matrix(<double>[
                                0.2126, 0.7152, 0.0722, 0, 0, //R
                                0.2126, 0.7152, 0.0722, 0, 0, //G
                                0.2126, 0.7152, 0.0722, 0, 0, //B
                                0, 0, 0, 1, 0, //A
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
              final text = _messageInputController.text.trim();

              if (text.isNotEmpty) {
                //     final message = Message(
                //       userId: _userId,
                //       content: text,
                //       sender: Sender.user,
                //       type: MessageType.normal,
                //       createdAt: DateTime.now(),
                //     );
                //     // ViewModel에 메시지와 함께 선택된 이모지 정보를 전달
                //                     final selectedEmotionKey = kEmojiAssetMap.entries.firstWhere((entry) => entry.value == selectedEmojiAsset, orElse: () => kEmojiAssetMap.entries.first).key;

                //        chatVm.sendMessage(message, selectedEmotionKey);
                //     _messageInputController.clear();
                //   }
                // },

                // RIN: Message 객체를 직접 만들지 않고, 텍스트만 ViewModel으로 전달하도록 변경!!
                final selectedEmotionKey = kEmojiAssetMap.entries
                    .firstWhere((entry) => entry.value == selectedEmojiAsset,
                        orElse: () => kEmojiAssetMap.entries.first)
                    .key;

                chatVm.sendMessage(text, selectedEmotionKey);
                _messageInputController.clear();
              }
            },
            child: Container(
              padding: EdgeInsets.all(8.r),
              child: Image.asset("assets/icons/send_icon.png",
                  width: 24.w, height: 24.h, color: const Color(0xff777777)),

              // width: 40.67.w,
              // height: 40.h,
              // child: Image.asset(
              //   "assets/icons/send_icon.png",
              //   color: Color(0xff777777),
              // ),
            ),
          ),
        ],
      ),
    );
  }
}

// (새로 추가) --- 날짜 구분선 위젯 ---
class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white, // 하얀 네모 박스
            borderRadius: BorderRadius.circular(20.r), // 라운드 처리
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Text(
            '${DateFormat('MM.dd').format(date)}',
            style: TextStyle(
              fontSize: 12.sp, // 폰트 12
              color: Colors.black87, // 검은 글씨
              // fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
