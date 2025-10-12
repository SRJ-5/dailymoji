import 'package:dailymoji/core/routers/router.dart';
import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/core/styles/icons.dart';
import 'package:dailymoji/core/styles/images.dart';
import 'package:dailymoji/domain/entities/message.dart';
import 'package:dailymoji/domain/enums/emoji_asset.dart';
import 'package:dailymoji/domain/enums/enum_data.dart';
import 'package:dailymoji/presentation/pages/chat/chat_view_model.dart';
import 'package:dailymoji/presentation/pages/chat/widgets/triangle_painter.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/user_view_model.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
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
  final DateTime? targetDate;

  const ChatPage(
      {super.key, this.emotionFromHome, this.navigationData, this.targetDate});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage>
    with RouteAware, SingleTickerProviderStateMixin {
  bool showEmojiBar = false;
  late String currentSelectedEmojiKey;
  final _messageInputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  RouteObserver<ModalRoute<void>>? _routeObserver;
  final GlobalKey _inputFieldKey = GlobalKey();
  double _inputFieldHeight = 64.h; // 기본 높이
  bool _wasKeyboardVisible = false; // 이전 키보드 상태 추적
  late AnimationController _emojiCtrl; // 이모지 바 애니메이션 컨트롤러
  bool _isInitialLoad = true; // 초기 로딩 상태 추적

  // RouteObserver를 didChangeDependencies에서 지역 변수로 가져오도록 변경
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeObserver = ref.read(routeObserverProvider);
    _routeObserver?.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

// 텍스트 입력 시 UI 업데이트 (전송 버튼 활성화 등)
  void _onInputChanged() {
    setState(() {
      // 텍스트 변경 시 즉시 UI 업데이트 (전송 버튼 활성화 상태)
    });
    _updateInputFieldHeight();
  }

  // 입력 필드의 높이를 측정하여 이모지바 위치 업데이트
  void _updateInputFieldHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? renderBox =
          _inputFieldKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final newHeight = renderBox.size.height;
        if (_inputFieldHeight != newHeight) {
          setState(() {
            _inputFieldHeight = newHeight;
          });
        }
      }
    });
  }

  // 무한 스크롤 리스너
  void _scrollListener() {
    if (_scrollController.hasClients) {
      final chatState = ref.read(chatViewModelProvider);

      // 맨 위로 스크롤했을 때 (minScrollExtent에 가까워졌을 때)
      // 그리고 현재 로딩 중이 아니고, 더 불러올 메시지가 있을 때만 실행
      if (_scrollController.position.pixels <=
              _scrollController.position.minScrollExtent + 200 &&
          !chatState.isLoadingMore &&
          chatState.hasMore &&
          !chatState.isLoading) {
        // 추가 메시지 로드
        ref.read(chatViewModelProvider.notifier).loadMoreMessages();
      }
    }
  }

  @override
  void initState() {
    super.initState();

// 이모지 바 애니메이션 컨트롤러 초기화
    _emojiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

// 봇입력중일때 사용자입력못하게
    _messageInputController.addListener(_onInputChanged);

// 무한 스크롤 리스너 추가
    _scrollController.addListener(_scrollListener);

// emotionFromHome이 있으면 그 이모지로, 없으면 'default'로 초기 상태 설정
    currentSelectedEmojiKey = widget.emotionFromHome ?? 'default';

// Rin: enterChatRoom방식: 홈에서 들어갈때 이 부분 충돌안나게 주의하기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // RIN: SolutionPage에서 보낸 navigationData, 홈에서 보낸 emotionFromHome, 리포트에서 보낸 targetDate 등
      // RIN: 모든 진입 케이스의 데이터를 ViewModel의 단일 진입점인 enterChatRoom 메서드로 전달하기!

      ref.read(chatViewModelProvider.notifier).enterChatRoom(
            emotionFromHome: widget.emotionFromHome,
            specificDate: widget.targetDate,
            navigationData: widget.navigationData,
          );
    });
  }

  @override
  void dispose() {
    _routeObserver?.unsubscribe(this);

    _emojiCtrl.dispose();
    _messageInputController.removeListener(_onInputChanged);
    _scrollController.removeListener(_scrollListener);
    _messageInputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    Future.microtask(() {
      // Check if there's a result from the solution page
      final result = ref.read(solutionResultProvider);

      if (result != null) {
        debugPrint("RIN: didPopNext processing result: $result");

        // Process the result using the ViewModel
        ref.read(chatViewModelProvider.notifier).processSolutionResult(result);

        // IMPORTANT: Consume the result so it's not processed again
        ref.read(solutionResultProvider.notifier).state = null;
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // 위젯 렌더링이 완료된 직후에 스크롤해야 정확한 맨 아래 위치로 갈 수 있음
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  // 초기 진입 시 여러 번 재시도하며 스크롤 (렌더링 지연 대응)
  void _scrollToBottomWithRetry(int attemptCount, [double? previousMaxExtent]) {
    if (!mounted || attemptCount > 5) return; // 최대 5번 시도

    if (_scrollController.hasClients) {
      final maxExtent = _scrollController.position.maxScrollExtent;

      // 이전과 같은 위치면 더 이상 렌더링되지 않는 것이므로 중단
      if (previousMaxExtent != null &&
          (maxExtent - previousMaxExtent).abs() < 1.0) {
        return;
      }

      _scrollController.jumpTo(maxExtent);

      // 50ms 후 다시 시도 (렌더링이 추가로 발생할 수 있음)
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          _scrollToBottomWithRetry(attemptCount + 1, maxExtent);
        }
      });
    } else {
      // ScrollController가 아직 준비되지 않았다면 조금 기다렸다가 재시도
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          _scrollToBottomWithRetry(attemptCount + 1, previousMaxExtent);
        }
      });
    }
  }

  void _toggleEmojiBar() {
    setState(() {
      showEmojiBar = !showEmojiBar;
      if (showEmojiBar) {
        _emojiCtrl.forward(from: 0.0); // 애니메이션 시작
      } else {
        _emojiCtrl.reverse(); // 애니메이션 역재생
      }
    });
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

    // 초기 로딩 완료 시 스크롤을 맨 아래로 이동
    ref.listen(chatViewModelProvider.select((value) => value.isLoading),
        (previous, next) {
      if (previous == true && next == false && _isInitialLoad) {
        _isInitialLoad = false;
        // 여러 프레임에 걸쳐 여러 번 시도하여 확실하게 스크롤
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottomWithRetry(0);
        });
      }
    });

    final chatState = ref.watch(chatViewModelProvider);
    // final isArchivedView = chatState.isArchivedView;

    // 캐릭터 이름 연동
    final userState = ref.watch(userViewModelProvider);
    final characterName = userState.userProfile?.characterNm ?? "모지";
    final characterImageUrl = userState.userProfile?.aiCharacter; // 캐릭터 프사

    // 봇이 입력중일 때 사용자가 입력 못하게
    final isBotTyping = chatState.isTyping;

    final messages = chatState.messages;
    // 전체 대화 목록에서 가장 마지막 메시지의 ID를 가져옵니다.
    final veryLastMessageId = messages.isNotEmpty ? messages.last.id : null;

    //  메시지 리스트가 변경될 때마다 스크롤을 맨 아래로 이동 (무한 스크롤 로딩 중이 아닐 때만)
    ref.listen(chatViewModelProvider.select((state) => state.messages.length),
        (previous, next) {
      if (next > (previous ?? 0) &&
          !chatState.isLoading &&
          !chatState.isLoadingMore) {
        _scrollToBottom();
      }
    });

    return GestureDetector(
      // 키보드가 올라와 있을 때 바깥 영역 터치 시 키보드 내리기 / 이모지 바 닫기
      onTap: () {
        FocusScope.of(context).unfocus();
        if (showEmojiBar) {
          setState(() => showEmojiBar = false);
        }
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: AppColors.yellow50,
        appBar: AppBar(
          scrolledUnderElevation: 0,
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
              AppText(
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
                            itemCount: messages.length +
                                (chatState.isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              // 로딩 인디케이터 표시 (맨 위에 표시됨)
                              if (chatState.isLoadingMore && index == 0) {
                                return Container(
                                  padding: EdgeInsets.all(16.h),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  ),
                                );
                              }

                              // 로딩 인디케이터가 있을 때는 인덱스를 1 감소
                              final messageIndex =
                                  chatState.isLoadingMore ? index - 1 : index;
                              final message = messages[messageIndex];

                              // --- 날짜 구분선 표시 로직 ---
                              bool showDateSeparator = false;

                              // 첫 번째 메시지(시간상 가장 오래된 메시지)일 경우
                              if (messageIndex == 0) {
                                showDateSeparator = true;
                              } else {
                                // 현재 메시지와 바로 이전 메시지의 날짜를 비교
                                final prevMessage = messages[messageIndex - 1];
                                if (!isSameDay(
                                    prevMessage.createdAt, message.createdAt)) {
                                  showDateSeparator = true;
                                }
                              }

                              final bool isLastProposal =
                                  !chatState.isArchivedView &&
                                      (message.id == veryLastMessageId);

                              final messageWidget = _buildMessageWidget(
                                message,
                                key: ValueKey(message.tempId),
                                isLastProposal: isLastProposal,
                              );

                              // 날짜 구분선이 메시지 위에 표시됨
                              if (showDateSeparator) {
                                return Column(
                                  children: [
                                    _DateSeparator(date: message.createdAt),
                                    messageWidget,
                                  ],
                                );
                              }
                              return messageWidget;
                            },
                          ),
                  ),
                  if (widget.targetDate == null)
                    _buildInputField(isBotTyping: isBotTyping),
                ],
              ),
            ),
            if (showEmojiBar)
              KeyboardVisibilityBuilder(builder: (context, isKeyboardVisible) {
                // 키보드가 새로 올라왔을 때 감지 (false → true)
                if (!_wasKeyboardVisible && isKeyboardVisible && showEmojiBar) {
                  // 키보드 애니메이션이 완료될 때까지 대기 후 재조정
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (mounted && showEmojiBar) {
                        setState(() {
                          // 이모지바 위치 재조정
                          _updateInputFieldHeight();
                        });
                      }
                    });
                  });
                }
                _wasKeyboardVisible = isKeyboardVisible;

                return Positioned(
                  left: 0,
                  right: 0,
                  bottom: (isKeyboardVisible
                          ? MediaQuery.of(context).viewInsets.bottom
                          : 34.h) +
                      _inputFieldHeight,
                  child: _buildEmojiSelector(),
                );
              }),
          ],
        ),
      ),
    );
  }

  // (따로 뺌) --- 메시지 종류에 따라 위젯을 분기하는 Helper 함수 ---
  Widget _buildMessageWidget(Message message,
      {required Key key, required bool isLastProposal}) {
    if (message.sender == Sender.user) {
      return _userMessage(message, key: key);
    } else {
      switch (message.type) {
        case MessageType.analysis:
          return _analysisMessage(message, key: key);
        case MessageType.solutionProposal:
          // return _solutionProposalMessage(message, key: key, isLastProposal: isLastProposal);
          return _solutionProposalCardMessage(message, key: key);
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
            color: AppColors.white, // 하얀 네모 박스
            borderRadius: BorderRadius.circular(20.r), // 라운드 처리
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: AppText(
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
          child: AppText(
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
      // print(
      //     "RIN: ✅ [ChatPage] Rendering image with path: ${message.imageAssetPath}");

      // 동그랗게 만들기! (--> 그래야 하얀 박스안에 들어가지 않음)
      messageContent = ClipRRect(
        borderRadius: BorderRadius.circular(50.r),
        child: Image.asset(
          message.imageAssetPath!,
          width: 80.w,
          height: 80.w,
          fit: BoxFit.cover,
        ),
      );
    } else {
      // 텍스트 메시지
      messageContent = AppText(
        message.content,
        style: AppFontStyles.bodyRegular14.copyWith(color: AppColors.grey900),
      );
    }

    return Padding(
      key: key,
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AppText(
            _formattedNow(message.createdAt),
            style:
                AppFontStyles.bodyRegular14.copyWith(color: AppColors.grey900),
          ),
          SizedBox(width: 4.w),
          Container(
            padding: message.type == MessageType.image
                ? EdgeInsets.zero
                : EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),

            constraints: BoxConstraints(maxWidth: 292.w), // 말풍선 가로 길이 최대
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
            constraints: BoxConstraints(maxWidth: 292.w),
            decoration: BoxDecoration(
              color: AppColors.yellow200,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(12.r),
                bottomRight: Radius.circular(12.r),
                bottomLeft: Radius.circular(12.r),
              ),
            ),
            child: AppText(
              message.content.replaceAll(r'\n', '\n'),
              style: AppFontStyles.bodyRegular14
                  .copyWith(color: AppColors.grey900),
            ),
          ),
          SizedBox(width: 4.w),
          AppText(
            _formattedNow(message.createdAt),
            style:
                AppFontStyles.bodyRegular14.copyWith(color: AppColors.grey900),
          ),
        ],
      ),
    );
  }

  Widget _solutionProposalMessage(Message message,
      {required Key key, required bool isLastProposal}) {
    final proposal = message.proposal!;
    final options = (proposal['options'] as List).cast<Map<String, dynamic>>();
    // debugPrint("RIN: Rendering solution proposal text: ${message.content}");

// 과거의 솔루션이면 다시보기로!
    if (!isLastProposal) {
      return Column(
        key: key,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _botMessage(message, key: ValueKey('${message.tempId}_text')),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.only(left: 8.w),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green50,
                foregroundColor: AppColors.grey900,
                padding:
                    EdgeInsets.symmetric(vertical: 9.5.h, horizontal: 16.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  side: BorderSide(color: AppColors.grey200, width: 1),
                ),
                textStyle: AppFontStyles.bodyRegular14,
              ),
              onPressed: () {
                ref.read(chatViewModelProvider.notifier).respondToSolution(
                      message.proposal!,
                      'accept_solution',
                      isReview: true, // 다시보기 모드임을 알림
                    );
              },
              child: AppText("솔루션 다시 볼래!"),
            ),
          ),
        ],
      );
    }

    // 상황 결정 버튼 UI 전체 수정
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _botMessage(message, key: ValueKey('${message.tempId}_text')),
        SizedBox(height: 12.h),
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
              final bool isPositiveAction =
                  action == 'accept_solution' || action == 'safety_crisis';
              final double buttonWidth = isPositiveAction ? 104.w : 128.w;

              final buttonStyle = ElevatedButton.styleFrom(
                backgroundColor:
                    isPositiveAction ? AppColors.yellow700 : AppColors.green50,
                foregroundColor:
                    isPositiveAction ? AppColors.grey50 : AppColors.grey900,
                padding:
                    EdgeInsets.symmetric(vertical: 9.5.h, horizontal: 16.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  side: BorderSide(
                      color: AppColors.grey200,
                      width: isPositiveAction ? 0 : 1), // 테두리
                ),
                textStyle: AppFontStyles.bodyRegular14,
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
                            message.proposal!,
                            action,
                          );
                    },
                    child: AppText(
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

  // 새로운 솔루션 제안 카드 UI (세로 버튼 레이아웃)
  Widget _solutionProposalCardMessage(Message message, {required Key key}) {
    String msg =
        "[2분 솔루션 추천]\n불안과 분노가 치밀어 오를 때는, 창밖 도시 불빛과 떨어지는 빗방울을 바라보며, 호흡을 가다듬는 것이 좋습니다. 호흡 → 영상 → 행동 순으로 진행해보면 기분이 좀 더 나아질거예요.";
    final proposal = message.proposal!;
    final options = (proposal['options'] as List).cast<Map<String, dynamic>>();

    return Padding(
      key: key,
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            constraints: BoxConstraints(maxWidth: 292.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(12.r),
                bottomRight: Radius.circular(12.r),
                bottomLeft: Radius.circular(12.r),
              ),
              border: Border.all(color: AppColors.yellow200, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  message.content.replaceAll(r'\n', '\n').split("\n")[0],
                  style: AppFontStyles.bodyMedium14
                      .copyWith(color: AppColors.grey900),
                ),
                // 본문
                AppText(
                  message.content.replaceAll(r'\n', '\n').split("\n")[1],
                  style: AppFontStyles.bodyRegular14
                      .copyWith(color: AppColors.grey900),
                ),
                SizedBox(height: 16.h),
                // 버튼들 (세로로 쌓기)
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // TODO 호흡 솔루션 진행
                      },
                      child: Container(
                        height: 40.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.yellow700,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Center(
                          child: AppText(
                            "호흡하러 가기",
                            style: AppFontStyles.bodyMedium14
                                .copyWith(color: AppColors.grey50),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    GestureDetector(
                      onTap: () {
                        // TODO 영상 솔루션 진행
                      },
                      child: Container(
                        height: 40.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.yellow700,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Center(
                          child: AppText(
                            "영상보러 가기",
                            style: AppFontStyles.bodyMedium14
                                .copyWith(color: AppColors.grey50),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    GestureDetector(
                      onTap: () {
                        // TODO 미션 솔루션 진행
                      },
                      child: Container(
                        height: 40.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.yellow700,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Center(
                          child: AppText(
                            "미션하러 가기",
                            style: AppFontStyles.bodyMedium14
                                .copyWith(color: AppColors.grey50),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 4.w),
          AppText(
            _formattedNow(message.createdAt),
            style:
                AppFontStyles.bodyRegular14.copyWith(color: AppColors.grey900),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiSelector() {
    final emojis = EmojiAsset.withoutDefault;

    // 0.0~0.25 구간: 배경 페이드인
    final bgOpacity = CurvedAnimation(
      parent: _emojiCtrl,
      curve: const Interval(0.0, 0.25, curve: Curves.easeOutCubic),
    );

    // 스태거 간격(각 이모지 시작 시점 간격)
    const step = 0.1; // 100ms 간격
    final baseStart = 0.25; // 배경이 떠오른 뒤부터 시작

    return FadeTransition(
      opacity: bgOpacity,
      child: Container(
        padding: EdgeInsets.all(12.r),
        margin: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.grey200),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF1D293D).withValues(alpha: 0.1),
              blurRadius: 4.h,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 닫기 버튼
            Row(
              children: [
                SizedBox(width: 24.w),
                Expanded(
                  child: Center(
                    child: AppText(
                      '현재 나의 감정',
                      style: AppFontStyles.bodySemiBold16
                          .copyWith(color: AppColors.grey900),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _emojiCtrl.reverse(); // 애니메이션 역재생하여 닫기
                    setState(() => showEmojiBar = false);
                  },
                  child: Container(
                    padding: EdgeInsets.all(2.4.r),
                    child: SvgPicture.asset(
                      AppIcons.close,
                      width: 19.2.w,
                      height: 19.2.w,
                      colorFilter: ColorFilter.mode(
                        AppColors.grey400,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            // Row(
            // children: List.generate(
            Container(
              height: 72.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: emojis.length,
                separatorBuilder: (context, index) => SizedBox(width: 4.w),
                itemBuilder: (context, index) {
                  // children: List.generate(emojis.length, (index) {
                  final emoji = emojis[index];
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
                        begin: Offset(-0.2, 0),
                        end: Offset.zero,
                      ).animate(curved),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (currentSelectedEmojiKey == emoji.label) {
                              currentSelectedEmojiKey = "default";
                            } else {
                              currentSelectedEmojiKey = emoji.label;
                            }
                            // showEmojiBar = false;
                          });
                          // _emojiCtrl.reverse(); // 애니메이션 역재생하여 닫기
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          width: 62.2.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.r),
                            color: currentSelectedEmojiKey == emoji.label
                                ? AppColors.grey100
                                : Colors.transparent,
                          ),
                          child: Column(
                            children: [
                              Image.asset(
                                emoji.asset,
                                width: 34.w,
                                height: 34.h,
                              ),
                              SizedBox(height: 4.h),
                              AppText(
                                emoji.display,
                                textAlign: TextAlign.center,
                                style: AppFontStyles.bodyRegular12.copyWith(
                                  color: AppColors.grey900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // ),
          ],
        ),
      ),
    );
  }

// 봇 입력중일 때 사용자 입력 불가 설정
  Widget _buildInputField({required bool isBotTyping}) {
    final bool isSendButtonEnabled = !isBotTyping &&
        (_messageInputController.text.trim().isNotEmpty ||
            currentSelectedEmojiKey != 'default');

    return KeyboardVisibilityBuilder(
      builder: (context, isKeyboardVisible) {
        return Container(
          key: _inputFieldKey,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          margin: EdgeInsets.only(bottom: isKeyboardVisible ? 0 : 34.h),
          child: Container(
            decoration: BoxDecoration(
              // color: isBotTyping ? AppColors.grey100 : Colors.white,
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.grey200),
            ),
            constraints: BoxConstraints(
              minHeight: 40.h,
              maxHeight: 142.h,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: TextField(
                      //입력 비활성화 로직
                      enabled: !isBotTyping,
                      controller: _messageInputController,
                      maxLength: 300, // 300자 제한
                      maxLines: 6,
                      minLines: 1,
                      decoration: InputDecoration(
                        counterText: "", // 글자 수 카운터 숨기기
                        hintText: isBotTyping
                            ? ""
                            : "무엇이든 입력하세요", // TODO: 입력 못하게 멘트를 넣어야하나..?
                        hintStyle: AppFontStyles.bodyRegular14
                            .copyWith(color: AppColors.grey600),
                        fillColor: Colors.transparent, // 컨테이너 색상을 따르도록 투명화
                        filled: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        // 비활성화 상태일 때 밑줄 제거
                        disabledBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                // 봇 입력 중에는 이모지 선택 비활성화
                Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 8.h).copyWith(right: 12),
                  child: Row(
                    children: [
                      AbsorbPointer(
                        absorbing: isBotTyping,
                        child: GestureDetector(
                          onTap: _toggleEmojiBar,
                          child: Container(
                            padding: EdgeInsets.all(2.r),
                            child: Image.asset(
                              EmojiAsset.fromString("default").asset,
                              width: 24.w,
                              height: 24.h,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      GestureDetector(
                        // 봇 입력 중이거나 텍스트가 비어있으면 onTap을 null로 처리하여 비활성화
                        onTap: isSendButtonEnabled
                            ? () {
                                final chatVm =
                                    ref.read(chatViewModelProvider.notifier);
                                final text =
                                    _messageInputController.text.trim();
                                // RIN ♥ 텍스트만, 이모지만, 텍스트+이모지 케이스 분리
                                if (text.isNotEmpty &&
                                    currentSelectedEmojiKey != 'default') {
                                  // 케이스 3: 텍스트 + 이모지 같이 입력
                                  chatVm.sendTextAndEmojiAsMessages(
                                      text, currentSelectedEmojiKey);
                                } else if (text.isNotEmpty) {
                                  // 케이스 1: 텍스트만 입력
                                  chatVm.sendMessage(text, null);
                                } else if (currentSelectedEmojiKey !=
                                    'default') {
                                  // 케이스 2: 이모지만 입력
                                  // 디폴트 이미지면 아예 안보내지게!!
                                  chatVm.sendEmojiAsMessage(
                                      currentSelectedEmojiKey);
                                }

                                _messageInputController.clear();
                                setState(() {
                                  currentSelectedEmojiKey =
                                      'default'; // 이모지 전송 후 디폴트로 다시 돌아오기
                                  showEmojiBar = false;
                                });
                              }
                            : null,
                        child: Container(
                          padding: EdgeInsets.all(2.r),
                          width: 24.w,
                          height: 24.h,
                          child: SvgPicture.asset(
                            currentSelectedEmojiKey != "default" ||
                                    _messageInputController.text.isNotEmpty
                                ? AppIcons.send_orange
                                : AppIcons.send,
                            colorFilter: currentSelectedEmojiKey != "default" ||
                                    _messageInputController.text.isNotEmpty
                                ? null
                                : ColorFilter.mode(
                                    isBotTyping
                                        ? AppColors.grey200
                                        : AppColors.grey400,
                                    BlendMode.srcIn,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
            color: AppColors.white, // 하얀 네모 박스
            borderRadius: BorderRadius.circular(20.r), // 라운드 처리
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: AppText(DateFormat('yyyy년 MM월 dd일').format(date),
              style: AppFontStyles.bodyRegular12
                  .copyWith(color: AppColors.grey900)),
        ),
      ),
    );
  }
}
