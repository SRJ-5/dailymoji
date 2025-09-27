// lib/presentation/pages/chat/chat_page.dart

import 'package:dailymoji/core/constants/emoji_assets.dart';
import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/core/styles/icons.dart';
import 'package:dailymoji/core/styles/images.dart';
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
  final Map<String, dynamic>? navigationData;

  const ChatPage({super.key, this.emotionFromHome, this.navigationData});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage>
    with SingleTickerProviderStateMixin {
  bool showEmojiBar = false;
  late String currentSelectedEmojiKey;
  final _messageInputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _emojiCtrl;

// 봇입력중일때 사용자입력못하게
  void _onInputChanged() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _emojiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700), // 전체 타이밍
    );

// 봇입력중일때 사용자입력못하게
    _messageInputController.addListener(_onInputChanged);

// emotionFromHome이 있으면 그 이모지로, 없으면 'default'로 초기 상태 설정
    currentSelectedEmojiKey = widget.emotionFromHome ?? 'default';

// Rin: enterChatRoom방식: 홈에서 들어갈때 이 부분 충돌안나게 주의하기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navData = widget.navigationData;
      if (navData != null && navData['from'] == 'solution_page') {
        final reason = navData['reason'] as String? ?? 'video_ended'; // 기본값 설정
        ref
            .read(chatViewModelProvider.notifier)
            .sendFollowUpMessageAfterSolution(reason: reason);
      } else {
        // 기존 로직: 홈에서 진입한 경우
        ref
            .read(chatViewModelProvider.notifier)
            .enterChatRoom(widget.emotionFromHome);
      }
    });
  }

  @override
  void dispose() {
    _messageInputController.removeListener(_onInputChanged);
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
    // RIN ♥ : 홈에서 온 이모지 처리가 끝나면 디폴트 이미지로 돌려놓기
    ref.listen(chatViewModelProvider.select((value) => value.clearPendingEmoji),
        (previous, next) {
      if (next == true) {
        setState(() {
          currentSelectedEmojiKey = 'default';
        });
        ref
            .read(chatViewModelProvider.notifier)
            .consumeClearPendingEmojiSignal();
      }
    });

    final chatState = ref.watch(chatViewModelProvider);
    // 캐릭터 이름 연동
    final userState = ref.watch(userViewModelProvider);
    final characterName = userState.userProfile?.characterNm ?? "모지모지";
    final characterImageUrl = userState.userProfile?.aiCharacter; // 캐릭터 프사

// 봇이 입력중일 때 사용자가 입력 못하게
    final isBotTyping = chatState.isTyping;

    final messages = chatState.messages.reversed.toList();

    //  메시지 리스트가 변경될 때마다 스크롤을 맨 아래로 이동
    ref.listen(chatViewModelProvider.select((state) => state.messages.length),
        (previous, next) {
      if (next > (previous ?? 0) && !chatState.isLoading) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.yellow50,
      appBar: AppBar(
        automaticallyImplyLeading: true, // backbutton
        backgroundColor: AppColors.yellow50,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // 중앙 정렬을 위해 추가

          children: [
            CircleAvatar(
              radius: 16.r,
              backgroundImage:
                  (characterImageUrl != null && characterImageUrl.isNotEmpty)
                      ? NetworkImage(characterImageUrl)
                      : const AssetImage(AppImages.cadoFace) as ImageProvider,
            ),
            SizedBox(width: 12.r),
            Text(
              characterName,
              style:
                  AppFontStyles.bodyBold14.copyWith(color: AppColors.grey900),
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
                                  _DateSeparator(
                                      date: message
                                          .createdAt), // 날짜 구분선이 나중에 나옴 (reverse 효과)
                                  messageWidget, // 메시지가 먼저 나오고
                                ],
                              );
                            }
                            return messageWidget;
                          },
                        ),
                ),
                _buildInputField(isBotTyping: isBotTyping),
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
                color: Colors.black.withValues(alpha: 0.05),
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
      messageContent = Text(message.content,
          maxLines: 10,
          overflow: TextOverflow.ellipsis,
          style: AppFontStyles.bodyMedium14.copyWith(color: AppColors.grey900));
    }

    return Padding(
      key: key,
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(_formattedNow(message.createdAt),
              style: AppFontStyles.bodyRegular12
                  .copyWith(color: AppColors.grey700)),
          SizedBox(width: 4.w),
          Container(
            padding: message.type == MessageType.image
                ? EdgeInsets.zero
                : EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),

            constraints: BoxConstraints(maxWidth: 260.w), // 말풍선 가로 길이 최대
            decoration: BoxDecoration(
              color: message.type == MessageType.image
                  ? Colors.transparent
                  : AppColors.green200,
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
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            constraints: BoxConstraints(maxWidth: 260.w),
            decoration: BoxDecoration(
              color: AppColors.yellow200,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(12.r),
                bottomRight: Radius.circular(12.r),
                bottomLeft: Radius.circular(12.r),
              ),
            ),
            child: Text(message.content,
                maxLines: 10,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: AppFontStyles.bodyMedium14
                    .copyWith(color: AppColors.grey900)),
          ),
          SizedBox(width: 4.w),
          Text(_formattedNow(message.createdAt),
              style: AppFontStyles.bodyRegular12
                  .copyWith(color: AppColors.grey700)),
        ],
      ),
    );
  }

  Widget _solutionProposalMessage(Message message, {required Key key}) {
    final proposal = message.proposal!;
    final options = (proposal['options'] as List).cast<Map<String, dynamic>>();
    debugPrint("RIN: Rendering solution proposal text: ${message.content}");

    // 상황 결정 버튼 UI 전체 수정
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _botMessage(message, key: ValueKey('${message.tempId}_text')),
        SizedBox(height: 8.h),
        Padding(
          padding: EdgeInsets.only(left: 8.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: options.asMap().entries.map((entry) {
              final int index = entry.key;
              final Map<String, dynamic> option = entry.value;
              final String action = option['action'] as String;
              final String label = option['label'] as String;

              // 좋아요, 싫어요 버튼 스타일 다르게
              final bool isPositiveAction = action == 'accept_solution';
              final double buttonWidth = isPositiveAction ? 104.w : 128.w;

              final buttonStyle = ElevatedButton.styleFrom(
                backgroundColor:
                    isPositiveAction ? AppColors.yellow700 : AppColors.green50,
                foregroundColor:
                    isPositiveAction ? AppColors.grey50 : AppColors.grey900,
                padding: EdgeInsets.symmetric(vertical: 9.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  side: BorderSide(
                      color: AppColors.grey200,
                      width: isPositiveAction ? 0 : 1), // 테두리
                ),
                textStyle: AppFontStyles.bodyMedium14,
              );

              return Padding(
                // 첫 번째 버튼이 아닐 경우에만 왼쪽에 간격을 줌
                padding: EdgeInsets.only(left: index > 0 ? 12.w : 0),
                child: SizedBox(
                  width: buttonWidth,
                  height: 40.h,
                  child: ElevatedButton(
                    style: buttonStyle,
                    onPressed: () {
                      // 각 답변에 맞는 action
                      ref
                          .read(chatViewModelProvider.notifier)
                          .respondToSolution(
                            proposal['solution_id'] as String,
                            action,
                          );
                    },
                    child: Text(
                      // 좋아, 싫어 레이블
                      label,
                      // style: AppFontStyles.bodyMedium14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        )
      ],
    );
  }

  Widget _buildEmojiBarAnimated() {
    // 애초에 디폴트 이미지는 여기서 안뜨게! (MVP)
    final emojiKeys =
        kEmojiAssetMap.keys.where((key) => key != 'default').toList();
    final emojiAssets = emojiKeys.map((key) => kEmojiAssetMap[key]!).toList();

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
                          currentSelectedEmojiKey = selectedEmotionKey;
                          showEmojiBar = false; // 이모지 바 닫기
                        });
                        // // 선택된 이모지를 메시지로 전송
                        // ref
                        //     .read(chatViewModelProvider.notifier)
                        //     .sendEmojiAsMessage(selectedEmotionKey);

                        // // 이모지를 보낸 후, 즉시 'default'로 돌리기
                        // setState(() {
                        //   currentSelectedEmojiKey = 'default';
                        //   showEmojiBar = false;
                        // });

                        _emojiCtrl.reverse(); // 애니메이션 역재생하여 닫기
                      },
                      child: ColorFiltered(
                        colorFilter: currentSelectedEmojiKey != emojiKeys[index]
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

// 봇 입력중일 때 사용자 입력 불가 설정
  Widget _buildInputField({required bool isBotTyping}) {
    final bool isSendButtonEnabled = !isBotTyping &&
        (_messageInputController.text.trim().isNotEmpty ||
            currentSelectedEmojiKey != 'default');

    return Container(
      margin: EdgeInsets.only(bottom: 46.h),
      decoration: BoxDecoration(
        // // TODO: 봇이 입력중일때 채팅창 색 변화?
        // color: isBotTyping ? AppColors.grey100 : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              //입력 비활성화 로직
              enabled: !isBotTyping,
              controller: _messageInputController,
              maxLength: 300, // 300자 제한
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(
                counterText: "", // 글자 수 카운터 숨기기
                hintText: isBotTyping
                    ? ""
                    : "무엇이든 입력하세요", // TODO: 입력 못하게 멘트를 넣어야하나..?
                hintStyle: AppFontStyles.bodyMedium14
                    .copyWith(color: AppColors.grey600),
                fillColor: Colors.transparent, // 컨테이너 색상을 따르도록 투명화
                filled: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                border: InputBorder.none,
                // 비활성화 상태일 때 밑줄 제거
                disabledBorder: InputBorder.none,
              ),
            ),
          ),
          // 봇 입력 중에는 이모지 선택 비활성화
          AbsorbPointer(
            absorbing: isBotTyping,
            child: GestureDetector(
              onTap: _toggleEmojiBar,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
                child: Image.asset(
                  kEmojiAssetMap[currentSelectedEmojiKey]!,
                  width: 24.w,
                  height: 24.h,
                ),
              ),
            ),
          ),
          GestureDetector(
            // 봇 입력 중이거나 텍스트가 비어있으면 onTap을 null로 처리하여 비활성화
            onTap: isSendButtonEnabled
                ? () {
                    final chatVm = ref.read(chatViewModelProvider.notifier);
                    final text = _messageInputController.text.trim();
                    // RIN ♥ 텍스트만, 이모지만, 텍스트+이모지 케이스 분리
                    if (text.isNotEmpty &&
                        currentSelectedEmojiKey != 'default') {
                      // 케이스 3: 텍스트 + 이모지 같이 입력
                      chatVm.sendTextAndEmojiAsMessages(
                          text, currentSelectedEmojiKey);
                    } else if (text.isNotEmpty) {
                      // 케이스 1: 텍스트만 입력
                      chatVm.sendMessage(text, null);
                    } else if (currentSelectedEmojiKey != 'default') {
                      // 케이스 2: 이모지만 입력
                      // 디폴트 이미지면 아예 안보내지게!!
                      chatVm.sendEmojiAsMessage(currentSelectedEmojiKey);
                    }

                    _messageInputController.clear();
                    setState(() {
                      currentSelectedEmojiKey =
                          'default'; // 이모지 전송 후 디폴트로 다시 돌아오기
                    });
                  }
                : null,
            child: Container(
              padding: EdgeInsets.all(8.r),
              child: Image.asset(AppIcons.send,
                  width: 24.w,
                  height: 24.h,
                  // 봇 입력 중이거나 텍스트가 비어있으면 아이콘 흐리게
                  color: isSendButtonEnabled
                      ? AppColors.grey600
                      : AppColors.grey300),
            ),
          ),
        ],
      ),
    );
  }
}

// 날짜 구분선 위젯
class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

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
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Text(DateFormat('yyyy년 MM월 dd일').format(date),
              style: AppFontStyles.bodyMedium12
                  .copyWith(color: AppColors.grey900)),
        ),
      ),
    );
  }
}
