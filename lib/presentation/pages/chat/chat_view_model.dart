import 'package:dailymoji/core/constants/emoji_assets.dart';
import 'package:dailymoji/core/constants/emotion_map.dart';
import 'package:dailymoji/core/constants/presets.dart';
import 'package:dailymoji/core/constants/solution_scripts.dart';
import 'package:dailymoji/core/providers.dart';
import 'package:dailymoji/core/routers/router.dart';
import 'package:dailymoji/domain/entities/emotional_record.dart';
import 'package:dailymoji/domain/entities/message.dart';
import 'package:dailymoji/domain/enums/enum_data.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/user_view_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:dailymoji/domain/enums/enum_data.dart';

final solutionResultProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);

class ChatState {
  final List<Message> messages;
  final bool isTyping;
  final String? errorMessage;
  final bool isLoading; // 초기 로딩 상태
  final bool isLoadingMore; // 추가 메시지 로딩 상태
  final bool hasMore; // 더 불러올 메시지가 있는지
  final bool clearPendingEmoji; // RIN ♥ : UI의 이모지 상태를 초기화하기 위해 추가
  final bool isArchivedView;

  ChatState({
    this.messages = const [],
    this.isTyping = false,
    this.errorMessage,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.clearPendingEmoji = false,
    this.isArchivedView = false,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isTyping,
    String? errorMessage,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    bool? clearPendingEmoji,
    bool? isArchivedView,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      clearPendingEmoji: clearPendingEmoji ?? this.clearPendingEmoji,
      isArchivedView: isArchivedView ?? this.isArchivedView,
    );
  }
}

class ChatViewModel extends Notifier<ChatState> {
// ---------------------------------------------------------------------------
// State & Dependencies
// ---------------------------------------------------------------------------

// 페이지네이션 상수
  static const int _pageSize = 50;

// UserViewModel에서 실제 ID를 가져오고, 없으면 임시 ID 사용(개발용)

  String? get _userId =>
      ref.read(userViewModelProvider).userProfile?.id ??
      "ffc9c57c-b744-4924-a3e7-65781ecf6ab3";

//사용자의 텍스트 답변을 기다리는 이모지 상태
  String? _pendingEmotionForAnalysis;
  String? _lastEmojiOnlyCluster; // RIN ♥ 이모지 전송 직후의 클러스터 저장
  String? _lastEmojiMessageId; // RIN ♥ 이모지 전송 직후의 메시지 ID 저장 (세션 업데이트용)
  DateTime? _targetDate; // 현재 로드 중인 특정 날짜 (무한 스크롤 제어용)

  // String? _pendingSessionIdForFollowUp; // 솔루션에서 돌아왔는지 확인하기 위한 로직 추가

// ❤️💛 주석 1: 문제 1번 (대화 기억) 해결을 위한 상태 변수
  // 솔루션이 끝난 직후 "어땠어요?" 라는 질문을 보냈다는 것을 기억하기 위한 상태입니다.
  // 이 값이 true일 때 사용자가 메시지를 보내면, 백엔드에 "이것은 솔루션 피드백에 대한 답변입니다"라는 추가 정보를 함께 보낼 수 있습니다.
  bool _isWaitingForSolutionFeedback = false;

  @override
  ChatState build() => ChatState();

// ---------------------------------------------------------------------------
// Core Methods
// ---------------------------------------------------------------------------
  // 모든 메시지 추가 로직(_addUserMessageToChat, _addBotMessageToChat)을
  // 이 함수(_addMessage) 하나로 통합하였음
  Future<Message> _addMessage(Message message) async {
    state = state.copyWith(messages: [...state.messages, message]);
    try {
      final savedMessageFromDB =
          await ref.read(sendMessageUseCaseProvider).execute(message);
      final completeMessage = savedMessageFromDB.copyWith(
        imageAssetPath: message.imageAssetPath,
        tempId: message.tempId,
      );
      final updatedMessages = List<Message>.from(state.messages);
      final index =
          updatedMessages.indexWhere((m) => m.tempId == completeMessage.tempId);

      if (index != -1) {
        updatedMessages[index] = completeMessage;
        state = state.copyWith(messages: updatedMessages);
      }
      return completeMessage;
    } catch (e) {
      state = state.copyWith(
          messages:
              state.messages.where((m) => m.tempId != message.tempId).toList());
      print("Error in _addMessage: $e");
      rethrow;
    }
  }

// ---------------------------------------------------------------------------
// Public Methods
// ---------------------------------------------------------------------------

// --- Rin: 채팅방 진입 시 초기화 로직 ---
  Future<void> enterChatRoom({
    String? emotionFromHome,
    DateTime? specificDate,
    Map<String, dynamic>? navigationData,
  }) async {
    // 리포트 페이지에서 특정 날짜를 통해 들어온 경우 '과거 기록 보기' 모드로 설정
    final bool isArchived = specificDate != null;
    state = state.copyWith(isArchivedView: isArchived);

    // RIN: 모든 진입 경로의 파라미터를 받도록 통합
    final currentUserId = _userId; // Getter를 통해 현재 ID 가져오기
    if (currentUserId == null) {
      state = state.copyWith(isLoading: false, errorMessage: "로그인 정보가 없습니다.");
      return;
    }
    _subscribeToMessages(currentUserId);

    // RIN: 1. 어떤 경로로 진입하든, 가장 먼저 이전 대화 기록을 불러옴
    await _loadMessages(currentUserId, targetDate: specificDate);
    //[로직 변경] SolutionPage에서 직접 데이터를 보내는 방식은 유지하되, 만약을 대비합니다.
    if (navigationData != null && navigationData['from'] == 'solution_page') {
      final reason = navigationData['reason'] as String? ?? 'video_ended';
      final solutionId = navigationData['solutionId'] as String?;
      final sessionId = navigationData['sessionId'] as String?;

      if (solutionId != null && sessionId != null) {
        // 후속 메시지 요청 후, 새로운 로직이 중복 실행되지 않도록 상태를 초기화합니다.
        // _pendingSessionIdForFollowUp = null;
        await sendFollowUpMessageAfterSolution(
            reason: reason, solutionId: solutionId, sessionId: sessionId);
      }
    } else if (emotionFromHome != null) {
      final emojiMessage = Message(
        userId: currentUserId,
        sender: Sender.user,
        type: MessageType.image,
        imageAssetPath: kEmojiAssetMap[emotionFromHome],
      );
      final savedMessage = await _addMessage(emojiMessage);
      await _startConversationWithEmoji(savedMessage, emotionFromHome);
      state = state.copyWith(clearPendingEmoji: true);
    }
  }

  // // [새 로직 추가] ChatPage가 다시 화면에 보일 때 호출될 함수
  // Future<void> checkForPendingFollowUp() async {
  //   //저장해둔 sessionId가 있는지 확인
  //   if (_pendingSessionIdForFollowUp != null) {
  //     print("솔루션 페이지에서 복귀 감지! sessionId: $_pendingSessionIdForFollowUp");
  //     final sessionId = _pendingSessionIdForFollowUp!;
  //     // 중복 실행을 막기 위해 즉시 null로 초기화
  //     _pendingSessionIdForFollowUp = null;

  //     // 후속 메시지 전송 (solutionId는 현재 알 수 없으므로 임의의 값을 넣거나, 서버에서 무시하도록 처리 필요. 여기서는 'unknown'으로 전달)
  //     await sendFollowUpMessageAfterSolution(
  //       reason: 'returned', // '돌아왔다'는 새로운 이유
  //       solutionId: 'unknown',
  //       sessionId: sessionId,
  //     );
  //   }
  // }

// RIN ♥ : UI에서 초기화 신호를 확인한 후, 다시 false로 돌려놓는 함수
  void consumeClearPendingEmojiSignal() {
    state = state.copyWith(clearPendingEmoji: false);
  }

  Future<void> processSolutionResult(Map<String, dynamic> result) async {
    final reason = result['reason'] as String? ?? 'video_ended';
    final solutionId = result['solutionId'] as String?;
    final sessionId = result['sessionId'] as String?;

    if (solutionId != null && sessionId != null) {
      await sendFollowUpMessageAfterSolution(
        reason: reason,
        solutionId: solutionId,
        sessionId: sessionId,
      );
    }
  }

// // ---------------------------------------------------------------------------
// // 메시지 로드 & 구독
// // ---------------------------------------------------------------------------

  /// 사용자 텍스트 메시지 전송
  Future<void> sendMessage(String content, String? selectedEmotionKey) async {
// ♥ 변경: String? emotion으로 변경
    final currentUserId = _userId;
    if (currentUserId == null) return;

    final message = Message(
      userId: currentUserId,
      content: content,
      sender: Sender.user,
      type: MessageType.normal,
    );
    // final savedMessage = await _addUserMessageToChat(message);
    final savedMessage = await _addMessage(message);

// 대기 중인 이모지가 있으면 그것을 분석에 사용하고, 없으면 현재 입력창의 이모지를 사용
    final emotionForAnalysis = _pendingEmotionForAnalysis ?? selectedEmotionKey;

// 대기 중인 이모지를 사용했으므로, 이제 상태를 초기화
    if (_pendingEmotionForAnalysis != null) {
      _pendingEmotionForAnalysis = null;
    }

// RIN ♥ : 이모지-텍스트 연계 분석 로직 추가!
// 이모지만 보낸 직후에 텍스트가 입력되었고, 두 메시지의 클러스터가 같을 경우
    EmotionalRecord? emotionalRecordFromEmojiOnly;
    if (_lastEmojiOnlyCluster != null &&
        _lastEmojiMessageId != null &&
        emotionForAnalysis != null) {
// 백엔드에 _pendingEmotionForAnalysis (이모지)와 텍스트를 함께 전달하여 풀파이프라인 분석 요청
// 이모지+텍스트 가중치를 붙여 최종 점수로 저장
      emotionalRecordFromEmojiOnly = await _analyzeAndRespond(
        userMessage: savedMessage,
        textForAnalysis: message.content,
        emotion: emotionForAnalysis,
        updateSessionIdForMessageId:
            _lastEmojiMessageId, // 이전 이모지 메시지 ID로 세션 업데이트
      );
// 이모지-텍스트 연계 분석이 완료되면 상태 초기화
      _lastEmojiOnlyCluster = null;
      _lastEmojiMessageId = null;
    } else {
// 백엔드에 종합 분석 요청
      await _analyzeAndRespond(
        userMessage: savedMessage,
        textForAnalysis: message.content,
        emotion: emotionForAnalysis, //이모지 키 전달
      );
    }
  }

  /// 이모지 메시지 전송 (채팅방 내에서 선택 시)
  Future<void> sendEmojiAsMessage(String emotion) async {
    final currentUserId = _userId;
    if (currentUserId == null) return;

    final emojiMessage = Message(
      userId: currentUserId,
      sender: Sender.user,
      type: MessageType.image,
      imageAssetPath: kEmojiAssetMap[emotion],
    );
    final savedEmojiMessage = await _addMessage(emojiMessage);

// 백그라운드에서 대화 시작 로직 실행
// (UI에는 이미 추가했으므로, 이 함수는 DB 저장 및 봇 질문 로직만 담당)
    await _startConversationWithEmoji(savedEmojiMessage, emotion);
  }

// RIN ♥ : 텍스트와 이모지를 별도의 메시지로 전송 (케이스 3)
  Future<void> sendTextAndEmojiAsMessages(
      String text, String emotionKey) async {
    final currentUserId = _userId;
    if (currentUserId == null) return;

// 1. 이모지 메시지 객체를 바로 생성해서 전달
    await _addMessage(Message(
        userId: currentUserId,
        sender: Sender.user,
        type: MessageType.image,
        imageAssetPath: kEmojiAssetMap[emotionKey]));
    // 2. 텍스트 메시지 객체를 바로 생성해서 전달
    final savedTextMessage = await _addMessage(Message(
        userId: currentUserId,
        content: text,
        sender: Sender.user,
        type: MessageType.normal));

    // 3. 분석 요청
    await _analyzeAndRespond(
      userMessage: savedTextMessage,
      textForAnalysis: text,
      emotion: emotionKey,
    );
  }

// ---------------------------------------------------------------------------
// Helper Methods
// ---------------------------------------------------------------------------

// RIN ♥ : 여기서 이모지 전송 직후에 텍스트 받는 로직으로 modify
  /// 이모지 선택 후 공감 질문으로 이어지는 대화 시작 로직
  /// DB 저장 및 봇 질문 로직을 담당하므로
  /// UI에 메시지를 중복으로 추가하지 않도록 조심하기!!
  Future<void> _startConversationWithEmoji(
      Message savedEmojiMsg, String emotion) async {
    _pendingEmotionForAnalysis = emotion; // 텍스트 입력 대기중인 이모지 설정
    final currentUserId = _userId!;
    final userProfile = ref.read(userViewModelProvider).userProfile;

    try {
//리액션 스크립트로 질문/공감 멘트
// - 서버 /analyze(text="") 퀵세이브 → sessionId + 대사(text) 동시 수신
      final emojiRepo = ref.read(emojiReactionRepositoryProvider);
      final EmotionalRecord emotionalRecord =
          await emojiRepo.getReactionWithSession(
// EmotionalRecord 타입으로 받기
        userId: currentUserId,
        emotion: emotion,
        onboarding: userProfile?.onboardingScores ?? {},
// 🤩 RIN: 캐릭터 성향 넘기기
        characterPersonality: userProfile?.characterPersonality,
      );

// 이모지 전송 직후의 클러스터와 메시지 ID 저장
      _lastEmojiOnlyCluster = emotionalRecord.topCluster;
      _lastEmojiMessageId = savedEmojiMsg.id;

// 세션 연결
      if (emotionalRecord.sessionId != null && savedEmojiMsg.id != null) {
//emotionalRecord.sessionId 사용
        await ref.read(updateMessageSessionIdUseCaseProvider).execute(
              messageId: savedEmojiMsg.id!,
              sessionId:
                  emotionalRecord.sessionId!, // emotionalRecord.sessionId 사용
            );
      }
      await _addMessage(Message(
        userId: currentUserId,
        sender: Sender.bot,
        content: emotionalRecord.empathyText ?? "어떤 일 때문에 그렇게 느끼셨나요?",
      ));
    } catch (e) {
      print("RIN: 🚨 Failed to fetch reaction script: $e");
      await _addMessage(Message(
          userId: currentUserId,
          sender: Sender.bot,
          content: "어떤 일 때문에 그렇게 느끼셨나요?"));
    }
  }

// 백엔드에 감정 분석 및 솔루션 제안 요청
// RIN ♥ : EmotionalRecord? 타입 반환, updateSessionIdForMessageId 파라미터 추가
  Future<EmotionalRecord?> _analyzeAndRespond({
    required Message userMessage,
    required String textForAnalysis,
    required String? emotion, // nullable
    String? updateSessionIdForMessageId, // 세션 ID 업데이트할 메시지 ID
  }) async {
    final currentUserId = _userId;
    if (currentUserId == null) return null;

    final userState = ref.read(userViewModelProvider);
    final userProfile = userState.userProfile;
    final characterName = userProfile?.characterNm ?? "모지";

// "입력 중..." 메시지 표시
    final analyzingMessage = Message(
        userId: currentUserId,
        content: "$characterName이(가) 입력하고 있어요...",
        sender: Sender.bot,
        type: MessageType.analysis);
    state = state.copyWith(
        isTyping: true, messages: [...state.messages, analyzingMessage]);

// 이전 대화 기억: 최근 4개의 메시지를 history로 전달
    final history = state.messages.length > 4
        ? state.messages.sublist(state.messages.length - 4)
        : state.messages;

    try {
// /analyze 앤드포인트 연결
      final emotionalRecord =
          await ref.read(analyzeEmotionUseCaseProvider).execute(
                userId: currentUserId,
                text: textForAnalysis,
                emotion: emotion,
                onboarding: userProfile?.onboardingScores ?? {},
                characterPersonality: userProfile?.characterPersonality,
                history: history,
              );

// "입력 중..." 메시지 제거
      state = state.copyWith(
          messages: state.messages
              .where((m) => m.type != MessageType.analysis)
              .toList());

      final sessionId = emotionalRecord.sessionId;
// intervention은 항상 Map 형태
      final intervention = emotionalRecord.intervention;
      final presetId = intervention['preset_id'] as String?;

      switch (presetId) {
// Rin: 칭긔칭긔모드
        case PresetIds.friendlyReply:
          final dynamic textData = emotionalRecord.intervention['text'];
          String botMessageContent;

          if (textData is String) {
            botMessageContent = textData;
          } else {
            print(
                "Warning: Received non-string data for friendly_reply text: $textData");
            botMessageContent = "음.. 잠깐 생각 좀 해볼게! 🤔";
          }

          final botMessage = Message(
            userId: currentUserId,
            content: botMessageContent,
            sender: Sender.bot,
          );
          await _addMessage(botMessage);
          break; // 여기서 대화 흐름이 한번 끝남

// 솔루션 제안 모드
        case PresetIds.solutionProposal:
// intervention 맵에서 직접 데이터 추출 (안전성)
// `as String?`을 사용하여, 혹시 키가 없더라도 null로 처리되어 앱이 멈추지 않도록
          final empathyText = emotionalRecord.empathyText;
          final analysisText = emotionalRecord.analysisText;
          final topCluster =
              emotionalRecord.intervention['top_cluster'] as String?;

// 1. [공감] 메시지 먼저 보내기 (null이 아닐 때만)
          if (empathyText != null && empathyText.isNotEmpty) {
            final empathyMessage = Message(
              userId: currentUserId,
              content: empathyText,
              sender: Sender.bot,
            );
            await _addMessage(empathyMessage);
            await Future.delayed(const Duration(milliseconds: 1000));
          }

// 2. [분석 결과] 메시지 보내기 (null이 아닐 때만)
          if (analysisText != null && analysisText.isNotEmpty) {
            final analysisMessage = Message(
                userId: currentUserId,
                content: analysisText,
                sender: Sender.bot);
            await _addMessage(analysisMessage);
            await Future.delayed(const Duration(milliseconds: 1200));
          }
// 3. [솔루션 제안]을 위해 /solutions/propose 호출 (모든 조건이 맞을 때만)
          if (sessionId != null && topCluster != null) {
            await _proposeSolution(sessionId, topCluster, currentUserId);
          }
          break;

// 안전 위기 모드
        case PresetIds.safetyCrisisModal:
        case PresetIds.safetyCrisisSelfHarm:
        case PresetIds.safetyCrisisAngerAnxiety:
        case PresetIds.safetyCheckIn:
          final cluster = intervention['cluster'] as String;
          final solutionId = intervention['solution_id'] as String;
          final safetyText = kSolutionProposalScripts[cluster]?.first ??
              "많이 힘드시군요. 지금 도움이 필요할 수 있어요.";

          final botMessage = Message(
            userId: currentUserId,
            content: safetyText,
            sender: Sender.bot,
            type: MessageType.solutionProposal,
            proposal: {
              "solution_id": solutionId,
              "options": [
                {"label": "도움받기", "action": "safety_crisis"},
                {"label": "괜찮아요", "action": "decline_solution_and_talk"}
              ]
            },
          );
          await _addMessage(botMessage);
          break;

// RIN ♥ : 이모지 단독 입력 시의 응답 처리 (백엔드에서 EMOJI_REACTION presetId로 옴)
        case PresetIds.emojiReaction:
          final reactionText = intervention['empathy_text'] as String?;
          if (reactionText != null) {
            final botMessage = Message(
              userId: currentUserId,
              content: reactionText,
              sender: Sender.bot,
            );
            await _addMessage(botMessage);
          }
          break;

        default:
          final errorMessage = Message(
            userId: currentUserId,
            content: "죄송해요, 응답을 이해할 수 없었어요.",
            sender: Sender.bot,
          );
          await _addMessage(errorMessage);
      }

// 세션 ID 업데이트
      if (sessionId != null && userMessage.id != null) {
        await ref.read(updateMessageSessionIdUseCaseProvider).execute(
              messageId: userMessage.id!,
              sessionId: sessionId,
            );
      }
// RIN ♥ : 이모지-텍스트 연계 분석 시 이전 이모지 메시지에도 세션 ID 업데이트
      if (sessionId != null && updateSessionIdForMessageId != null) {
        await ref.read(updateMessageSessionIdUseCaseProvider).execute(
              messageId: updateSessionIdForMessageId,
              sessionId: sessionId,
            );
      }
      return emotionalRecord; // emotionalRecord 반환
    } catch (e, stackTrace) {
      print("analyzeAndRespond error : $e\n$stackTrace");
      state = state.copyWith(
        messages: state.messages
            .where((m) => m.type != MessageType.analysis)
            .toList(),
        errorMessage: "감정 분석에 실패했어요. 😥",
      );
    } finally {
      state = state.copyWith(isTyping: false);
    }
    return null;
  }

  /// 솔루션 제안 로직
  Future<void> _proposeSolution(
      String sessionId, String topCluster, String currentUserId) async {
    try {
      final proposalResponse =
          await ref.read(proposeSolutionUseCaseProvider).execute(
                userId: currentUserId,
                sessionId: sessionId,
                topCluster: topCluster,
              );

      final proposalMessage = Message(
        userId: currentUserId,
        content: proposalResponse['proposal_text'] as String,
        sender: Sender.bot,
        type: MessageType.solutionProposal,
        proposal: {
          "solution_id": proposalResponse['solution_id'],
          "session_id": sessionId,
          "options": [
            {"label": "좋아, 해볼게!", "action": "accept_solution"},
            {"label": "아니, 더 대화할래", "action": "decline_solution_and_talk"}
          ]
        },
      );
      await _addMessage(proposalMessage);
    } catch (e) {
      print("RIN: 🚨 [ViewModel] Failed to propose solution: $e");
      final errorMessage = Message(
          userId: currentUserId,
          content: "솔루션을 제안하는 중에 문제가 발생했어요.",
          sender: Sender.bot);
      await _addMessage(errorMessage);
    }
  }

// ---------------------------------------------------------------------------
// Data & State Management Utilities
// ---------------------------------------------------------------------------

// --- Rin: 특정 날짜 또는 오늘 대화 기록 불러오기 ---
  Future<void> _loadMessages(String userId, {DateTime? targetDate}) async {
// private 변수에 targetDate 저장
    _targetDate = targetDate;
    state = state.copyWith(isLoading: true);
    try {
// targetDate가 있으면 해당 날짜의 시작 시점부터, 없으면 전체 메시지
      String? cursorIso;
      if (_targetDate != null) {
// 해당 날짜의 다음 날 00:00:00을 커서로 설정 (그 이전 메시지들을 가져오기 위해)
        final nextDay = DateTime(
            _targetDate!.year, _targetDate!.month, _targetDate!.day + 1);
        cursorIso = nextDay.toIso8601String();
      }

// 특정 날짜의 경우 모든 메시지를 로드하기 위해 limit을 크게 설정
      final limit = _targetDate != null ? 1000 : _pageSize; // 특정 날짜면 최대 1000개까지

      final msgs = await ref.read(loadMessagesUseCaseProvider).execute(
            userId: userId,
            limit: limit,
            cursorIso: cursorIso,
          );

// 특정 날짜가 지정된 경우, 해당 날짜의 메시지만 필터링
      List<Message> filteredMsgs = msgs;
      if (_targetDate != null) {
        final targetDateStart =
            DateTime(_targetDate!.year, _targetDate!.month, _targetDate!.day);
        final targetDateEnd = DateTime(_targetDate!.year, _targetDate!.month,
            _targetDate!.day, 23, 59, 59);

        filteredMsgs = msgs.where((msg) {
          return msg.createdAt.isAfter(targetDateStart) &&
              msg.createdAt.isBefore(targetDateEnd);
        }).toList();
      }

// DB에서 가져온 메시지를 createdAt(생성 시간) 기준으로 정렬해야함!
      filteredMsgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));

// 특정 날짜 모드에서는 무한 스크롤 비활성화, 일반 모드에서는 페이지 사이즈로 판단
      final hasMore = _targetDate != null ? false : (msgs.length >= _pageSize);
      state = state.copyWith(
          messages: filteredMsgs, isLoading: false, hasMore: hasMore);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

// --- 추가 메시지 로드 (무한 스크롤) ---
  Future<void> loadMoreMessages() async {
    if (state.isLoadingMore || !state.hasMore) return;

// 특정 날짜가 설정된 경우 무한 스크롤 비활성화
    if (_targetDate != null) return;

    final currentUserId = _userId;
    if (currentUserId == null) return;

// 가장 오래된 메시지의 timestamp를 cursor로 사용
    if (state.messages.isEmpty) return;

    final oldestMessage = state.messages.first;
    final cursorIso = oldestMessage.createdAt.toIso8601String();

    state = state.copyWith(isLoadingMore: true);

    try {
      final additionalMsgs =
          await ref.read(loadMessagesUseCaseProvider).execute(
                userId: currentUserId,
                limit: _pageSize,
                cursorIso: cursorIso,
              );

      if (additionalMsgs.isNotEmpty) {
// 새로 가져온 메시지들을 정렬 (특정 날짜 모드는 이미 early return으로 제외됨)
        additionalMsgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));

// 기존 메시지 앞에 새 메시지들을 추가
        final updatedMessages = [...additionalMsgs, ...state.messages];

// 페이지 사이즈 미만이면 더 이상 로드할 메시지가 없다고 가정
        final hasMore = additionalMsgs.length >= _pageSize;

        state = state.copyWith(
          messages: updatedMessages,
          isLoadingMore: false,
          hasMore: hasMore,
        );
      } else {
// 더 이상 메시지가 없음
        state = state.copyWith(isLoadingMore: false, hasMore: false);
      }
    } catch (e) {
      state = state.copyWith(
          isLoadingMore: false, errorMessage: "추가 메시지를 불러오는데 실패했어요.");
    }
  }

  /// 새로운 메시지 구독

  void _subscribeToMessages(String userId) {
    ref.read(subscribeMessagesUseCaseProvider).execute(
          userId: userId,
          onNewMessage: (message) {
            final isExist = state.messages.any((m) => m.id == message.id);
            if (!isExist && message.sender == Sender.bot) {
              state = state.copyWith(messages: [...state.messages, message]);
            }
          },
        );
  }

//   /// UI에 사용자 메시지 추가 및 DB 저장 (Optimistic UI)
//   Future<Message> _addUserMessageToChat(Message message) async {
// // 1. UI에 즉시 메시지 추가
//     state = state.copyWith(messages: [...state.messages, message]);

//     try {
// // 2. DB에 메시지 저장
//       final savedMessageFromDB =
//           await ref.read(sendMessageUseCaseProvider).execute(message);

// // 3. UI의 임시 메시지를 DB 정보가 포함된 완전한 메시지로 교체
//       final completeMessage = savedMessageFromDB.copyWith(
//         imageAssetPath: message.imageAssetPath,
//         tempId: message.tempId,
//       );

//       final updatedMessages = List<Message>.from(state.messages);
//       final index =
//           updatedMessages.indexWhere((m) => m.tempId == completeMessage.tempId);
//       if (index != -1) {
//         updatedMessages[index] = completeMessage;
//         state = state.copyWith(messages: updatedMessages);
//       }
//       return completeMessage;
//     } catch (e) {
// // 에러 발생 시, 낙관적으로 추가했던 메시지를 다시 제거
//       state = state.copyWith(
//           messages:
//               state.messages.where((m) => m.tempId != message.tempId).toList());
//       rethrow;
//     }
//   }

//   /// UI에 봇 메시지 추가 및 DB 저장
//   Future<void> _addBotMessageToChat(Message botMessage) async {
//     final savedBotMessage =
//         await ref.read(sendMessageUseCaseProvider).execute(botMessage);
//     state = state.copyWith(messages: [...state.messages, savedBotMessage]);
//   }

// ---------------------------------------------------------------------------
// User Action Handlers
// ---------------------------------------------------------------------------

  /// 솔루션 완료 후 후속 질문 메시지 전송
  Future<void> sendFollowUpMessageAfterSolution(
      {required String reason,
      required String solutionId,
      required String sessionId}) async {
    /// 솔루션 완료 후 후속 멘트 전송
    final currentUserId = _userId;
    if (currentUserId == null) return;

// 사용자 프로필에서 캐릭터 성향과 닉네임 가져오기
    final userProfile = ref.read(userViewModelProvider).userProfile;
    final personality = userProfile?.characterPersonality;
    final personalityDbValue = personality != null
        ? CharacterPersonality.values
            .firstWhere((e) => e.label == personality,
                orElse: () => CharacterPersonality.probSolver)
            .dbValue
        : null;
    final userNickNm = userProfile?.userNickNm;

// chat 페이지로 넘어가는 reason에 따라 다른 메시지를 선택
// API를 통해 성향에 맞는 후속 질문 멘트 가져오기
    final content =
        await ref.read(homeDialogueRepositoryProvider).fetchFollowUpDialogue(
              reason: reason,
              personality: personalityDbValue,
              userNickNm: userNickNm,
            );

//     String content;
//     if (reason == 'user_closed') {
//       content = "대화를 더 해볼까요?";
//     } else {
// // 'video_ended' 또는 기타 경우
//       content = "어때요? 좀 좋아진 것 같아요?😊";
//     }

    final followUpMessage = Message(
      userId: currentUserId,
      content: content,
      sender: Sender.bot,
      type: MessageType.normal,
    );

// 이미 해당 메시지가 있는지 확인하여 중복 전송 방지
// 가장 마지막 메시지가 이 메시지와 동일하면 보내지 않음
// --> 이거 바로 이전 메시지와 내용이 같더라도 후속 메시지는 항상 보내야 하므로 주석처리함.
    // if (state.messages.isNotEmpty &&
    //     state.messages.last.content == followUpMessage.content) {
    //   return;
    // }

    await _addMessage(followUpMessage);
  }

  /// 솔루션 제안에 대한 사용자 응답 처리
  Future<void> respondToSolution(
      Map<String, dynamic> proposalData, String action,
      {bool isReview = false}) async {
    final currentUserId = _userId;
    if (currentUserId == null) return;

    final String solutionId = proposalData['solution_id'] as String;
    final String? sessionId = proposalData['session_id'] as String?;

    if (action == "decline_solution_and_talk") {
      // 사용자 프로필에서 캐릭터 성향과 닉네임 가져오기
      final userProfile = ref.read(userViewModelProvider).userProfile;
      final personality = userProfile?.characterPersonality;
      final personalityDbValue = personality != null
          ? CharacterPersonality.values
              .firstWhere((e) => e.label == personality,
                  orElse: () => CharacterPersonality.probSolver)
              .dbValue
          : null;
      final userNickNm = userProfile?.userNickNm;

      // API를 통해 성향에 맞는 거절 멘트 가져오기
      final content = await ref
          .read(homeDialogueRepositoryProvider)
          .fetchDeclineSolutionDialogue(
            personality: personalityDbValue,
            userNickNm: userNickNm,
          );

      final message =
          Message(userId: currentUserId, content: content, sender: Sender.bot);
      await _addMessage(message);
      return;
    }

    // RIN: 솔루션 페이지로 이동하기 직전에, 돌아왔을 때를 대비해 sessionId를 저장
    if (action == "accept_solution") {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);

      final result = await navigatorkey.currentContext?.push(
          '/breathing/$solutionId?sessionId=$sessionId&isReview=$isReview');

      if (result is Map<String, dynamic>) {
        final reason = result['reason'] as String? ?? 'video_ended';
        final returnedSessionId = result['sessionId'] as String?;

        if (returnedSessionId != null) {
          await sendFollowUpMessageAfterSolution(
            reason: reason,
            solutionId: solutionId,
            sessionId: returnedSessionId,
          );
        }
      }
    } else if (action == "safety_crisis") {
      String title = "상담센터 연결";
      navigatorkey.currentContext?.push('/info/$title');
    }
  }

  /// 에러 메시지 초기화
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// ---------------------------------------------------------------------------
// Provider Definition
// ---------------------------------------------------------------------------

final chatViewModelProvider =
    NotifierProvider<ChatViewModel, ChatState>(ChatViewModel.new);
