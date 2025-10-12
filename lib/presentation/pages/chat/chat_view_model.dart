import 'package:dailymoji/core/constants/app_text_strings.dart';
import 'package:dailymoji/core/providers.dart';
import 'package:dailymoji/core/routers/router.dart';
import 'package:dailymoji/domain/entities/emotional_record.dart';
import 'package:dailymoji/domain/entities/message.dart';
import 'package:dailymoji/domain/enums/enum_data.dart';
import 'package:dailymoji/domain/enums/emoji_asset.dart';
import 'package:dailymoji/domain/enums/preset_id.dart';
import 'package:dailymoji/domain/enums/solution_proposal.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/user_view_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

final solutionResultProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);

class ChatState {
  final List<Message> messages;
  final bool isTyping;
  final String? errorMessage;
  final bool isLoading; // 초기 로딩 상태
  final bool isLoadingMore; // 추가 메시지 로딩 상태
  final bool hasMore; // 더 불러올 메시지가 있는지
  final bool clearPendingEmoji; // RIN : UI의 이모지 상태를 초기화하기 위해 추가
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

  String? get _userId => ref.read(userViewModelProvider).userProfile?.id;

//사용자의 텍스트 답변을 기다리는 이모지 상태
  String? _pendingEmotionForAnalysis;
  String? _lastEmojiOnlyCluster; // RIN ♥ 이모지 전송 직후의 클러스터 저장
  String? _lastEmojiMessageId; // RIN ♥ 이모지 전송 직후의 메시지 ID 저장 (세션 업데이트용)
  DateTime? _targetDate; // 현재 로드 중인 특정 날짜 (무한 스크롤 제어용)
  Map<String, dynamic>?
      _adhdContextForNextRequest; // RIN: ADHD 분기 대화의 상태를 관리하기 위한 변수
  String?
      _lastProposedSolutionCluster; // RIN: 마지막으로 제안된 솔루션의 클러스터 종류를 저장하기 위한 변수

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
      final solutionType = navigationData['solution_type'] as String?;

      if (solutionId != null && sessionId != null && solutionType != null) {
        // 후속 메시지 요청 후, 새로운 로직이 중복 실행되지 않도록 상태를 초기화합니다.
        // _pendingSessionIdForFollowUp = null;
        await sendFollowUpMessageAfterSolution(
          reason: reason,
          solutionId: solutionId,
          sessionId: sessionId,
          solutionType: solutionType,
          topCluster: _lastProposedSolutionCluster,
        );
      }
    } else if (emotionFromHome != null) {
      final emojiMessage = Message(
        userId: currentUserId,
        sender: Sender.user,
        type: MessageType.image,
        imageAssetPath: EmojiAsset.fromString(emotionFromHome).asset,
      );
      final savedMessage = await _addMessage(emojiMessage);
      await _startConversationWithEmoji(savedMessage, emotionFromHome);
      state = state.copyWith(clearPendingEmoji: true);
    }
  }

// RIN ♥ : UI에서 초기화 신호를 확인한 후, 다시 false로 돌려놓는 함수
  void consumeClearPendingEmojiSignal() {
    state = state.copyWith(clearPendingEmoji: false);
  }

  Future<void> processSolutionResult(Map<String, dynamic> result) async {
    final reason = result['reason'] as String? ?? 'video_ended';
    final solutionId = result['solutionId'] as String?;
    final sessionId = result['sessionId'] as String?;
    final solutionType = result['solution_type'] as String?;

    if (solutionId != null && sessionId != null && solutionType != null) {
      await sendFollowUpMessageAfterSolution(
        reason: reason,
        solutionId: solutionId,
        sessionId: sessionId,
        solutionType: solutionType,
        topCluster: _lastProposedSolutionCluster,
      );
    }
  }

// // ---------------------------------------------------------------------------
// // 메시지 로드 & 구독
// // ---------------------------------------------------------------------------

  /// 사용자 텍스트 메시지 전송
  Future<void> sendMessage(String content, String? selectedEmotionKey) async {
    final currentUserId = _userId;
    if (currentUserId == null) return;

    final message = Message(
      userId: currentUserId,
      content: content,
      sender: Sender.user,
      // type: MessageType.normal,
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
    // EmotionalRecord? emotionalRecordFromEmojiOnly;
    if (_lastEmojiOnlyCluster != null &&
        _lastEmojiMessageId != null &&
        emotionForAnalysis != null) {
// 백엔드에 _pendingEmotionForAnalysis (이모지)와 텍스트를 함께 전달하여 풀파이프라인 분석 요청
// 이모지+텍스트 가중치를 붙여 최종 점수로 저장
      await _analyzeAndRespond(
        userMessage: savedMessage,
        textForAnalysis: message.content,
        emotion: emotionForAnalysis,
        updateSessionIdForMessageId:
            _lastEmojiMessageId, // 이전 이모지 메시지의 세션ID를 업데이트
        adhdContext: _adhdContextForNextRequest, // ADHD 컨텍스트도 함께 전달
      );
// 이모지-텍스트 연계 분석이 완료되면 상태 초기화
      _lastEmojiOnlyCluster = null;
      _lastEmojiMessageId = null;
    } else {
// 일반적인 텍스트 메시지 전송 로직: 백엔드에 종합 분석 요청
      await _analyzeAndRespond(
        userMessage: savedMessage,
        textForAnalysis: message.content,
        emotion: emotionForAnalysis, //이모지 키 전달
        adhdContext: _adhdContextForNextRequest,
      );
      // 어떤 경우든, 한 번 사용된 ADHD 컨텍스트는 초기화
      _adhdContextForNextRequest = null;
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
      imageAssetPath: EmojiAsset.fromString(emotion).asset,
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
        imageAssetPath: EmojiAsset.fromString(emotionKey).asset));
    // 2. 텍스트 메시지 객체를 바로 생성해서 전달
    final savedTextMessage = await _addMessage(Message(
      userId: currentUserId,
      content: text,
      sender: Sender.user,
      // type: MessageType.normal
    ));

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
// RIN: 캐릭터 성향 넘기기
        characterPersonality: userProfile?.characterPersonality,
      );

// 이모지 전송 직후의 클러스터와 메시지 ID 저장
      _lastEmojiOnlyCluster =
          emotionalRecord.intervention['top_cluster'] as String?;
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
      final reactionText =
          emotionalRecord.intervention['empathy_text'] as String?;

      await _addMessage(Message(
        userId: currentUserId,
        sender: Sender.bot,
        content: reactionText ?? AppTextStrings.fallbackEmojiQuestion,
      ));
    } catch (e) {
      print("RIN: 🚨 Failed to start conversation with emoji: $e");
      await _addMessage(Message(
          userId: currentUserId,
          sender: Sender.bot,
          content: AppTextStrings.fallbackEmojiQuestion));
    }
  }

// 백엔드에 감정 분석 및 솔루션 제안 요청
// RIN ♥ : EmotionalRecord? 타입 반환, updateSessionIdForMessageId 파라미터 추가
  Future<EmotionalRecord?> _analyzeAndRespond({
    required Message userMessage,
    required String textForAnalysis,
    required String? emotion, // nullable
    String? updateSessionIdForMessageId, // 세션 ID 업데이트할 메시지 ID
    Map<String, dynamic>? adhdContext,
  }) async {
    final currentUserId = _userId;
    if (currentUserId == null) return null;

    final userState = ref.read(userViewModelProvider);
    final userProfile = userState.userProfile;
    final characterName = userProfile?.characterNm ?? "모지";

// "입력 중..." 메시지 표시
    final analyzingMessage = Message(
        userId: currentUserId,
        content: AppTextStrings.botIsTyping.replaceAll('%s', characterName),
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
                adhdContext: adhdContext,
              );

// "입력 중..." 메시지 제거
      state = state.copyWith(
          messages: state.messages
              .where((m) => m.type != MessageType.analysis)
              .toList());

      final sessionId = emotionalRecord.sessionId;
      // 1. intervention 객체 먼저 추출
      final intervention = emotionalRecord.intervention;
      final presetId = intervention['preset_id'] as String?;

      final preset = PresetId.fromString(presetId ?? '');

      switch (preset) {
        // Rin: 칭긔칭긔모드
        case PresetId.friendlyReply:
          // 2. intervention 안에서 botMessageContent를 찾음
          final botMessageContent = intervention['text'] as String? ??
              AppTextStrings.fallbackAnalysisError;

          final botMessage = Message(
              userId: currentUserId,
              content: botMessageContent,
              sender: Sender.bot);
          await _addMessage(botMessage);
          break; // 여기서 대화 흐름이 한번 끝남

// 솔루션 제안 모드
        case PresetId.solutionProposal:
          // 3. intervention 안에서 필요한 모든 텍스트를 찾음
          final empathyText = intervention['empathy_text'] as String?;
          final analysisText = intervention['analysis_text'] as String?;
          final topCluster = intervention['top_cluster'] as String?;

// 1. [공감] 메시지 먼저 보내기 (null이 아닐 때만)
          if (empathyText != null && empathyText.isNotEmpty) {
            await _addMessage(Message(
                userId: currentUserId,
                content: empathyText,
                sender: Sender.bot));
            await Future.delayed(const Duration(milliseconds: 200));
          }

// 2. [분석 결과] 메시지 보내기 (null이 아닐 때만)
          if (analysisText != null && analysisText.isNotEmpty) {
            await _addMessage(Message(
                userId: currentUserId,
                content: analysisText,
                sender: Sender.bot));
            await Future.delayed(const Duration(milliseconds: 200));
          }

// 3. [솔루션 제안]을 위해 /solutions/propose 호출 (모든 조건이 맞을 때만)
          if (sessionId != null && topCluster != null) {
            await _proposeSolution(sessionId, topCluster, currentUserId);
          }
          break;

        // RIN: ADHD 질문 처리 케이스
        case PresetId.adhdPreSolutionQuestion:
          await _addMessage(Message(
            userId: currentUserId,
            content: intervention['text'] as String,
            sender: Sender.bot,
            type: MessageType.solutionProposal,
            proposal: {'options': intervention['options']},
          ));
          _adhdContextForNextRequest =
              intervention['adhd_context'] as Map<String, dynamic>?;
          break;

        case PresetId.adhdAwaitingTaskDescription:
          await _addMessage(Message(
            userId: currentUserId,
            content: intervention['text'] as String,
            sender: Sender.bot,
          ));
          _adhdContextForNextRequest =
              intervention['adhd_context'] as Map<String, dynamic>?;
          break;

        case PresetId.adhdTaskBreakdown:
          final coachingText = intervention['coaching_text'] as String?;
          final missionText = intervention['mission_text'] as String?;
          if (coachingText != null) {
            await _addMessage(Message(
                userId: currentUserId,
                content: coachingText,
                sender: Sender.bot));
            await Future.delayed(const Duration(milliseconds: 200));
          }
          if (missionText != null) {
            await _addMessage(Message(
              userId: currentUserId,
              content: missionText,
              sender: Sender.bot,
              type: MessageType.solutionProposal,
              proposal: {
                'options': intervention['options'],
                'session_id': sessionId
              },
            ));
          }
          break;

// 안전 위기 모드
        case PresetId.safetyCrisisModal:
        case PresetId.safetyCrisisSelfHarm:
        case PresetId.safetyCrisisAngerAnxiety:
        case PresetId.safetyCheckIn:
          // 4. intervention 안에서 위기 관련 정보를 찾음
          final cluster = intervention['cluster'] as String?;
          final solutionId = intervention['solution_id'] as String?;
          final safetyText = intervention['analysis_text'] as String? ??
              SolutionProposal.fromString(cluster ?? '')?.scripts.first ??
              "많이 힘드시군요. 지금 도움이 필요할 수 있어요.";

          if (cluster != null && solutionId != null) {
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
          }
          break;

// RIN ♥ : 이모지 단독 입력 시의 응답 처리 (백엔드에서 EMOJI_REACTION presetId로 옴)
        case PresetId.emojiReaction:
          // 5. intervention 안에서 'empathy_text' 찾기

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
            content: AppTextStrings.fallbackAnalysisError,
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
        errorMessage: AppTextStrings.fallbackAnalysisError,
      );
    } finally {
      state = state.copyWith(isTyping: false);
    }
    return null;
  }

  /// 솔루션 제안 로직
  Future<void> _proposeSolution(
      String sessionId, String topCluster, String currentUserId) async {
    _lastProposedSolutionCluster = topCluster;

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
          "options": proposalResponse['options'],
        },
      );
      await _addMessage(proposalMessage);
    } catch (e) {
      print("RIN: 🚨 [ViewModel] Failed to propose solution: $e");

      _lastProposedSolutionCluster = null;
      final errorMessage = Message(
          userId: currentUserId,
          content: AppTextStrings.fallbackSolutionError,
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

// ---------------------------------------------------------------------------
// User Action Handlers
// ---------------------------------------------------------------------------

  /// 솔루션 완료 후 후속 질문 메시지 전송
  Future<void> sendFollowUpMessageAfterSolution({
    required String reason,
    required String solutionId,
    required String sessionId,
    required String solutionType, //RIN: 솔루션 유형 추가
    String? topCluster,
  }) async {
    /// 솔루션 완료 후 후속 멘트 전송
    final currentUserId = _userId;
    if (currentUserId == null) return;

// 사용자 프로필에서 캐릭터 성향과 닉네임 가져오기
    final userVM = ref.read(userViewModelProvider.notifier);
    final userProfile = userVM.state.userProfile;
    final personalityDbValue = userProfile?.characterPersonality != null
        ? CharacterPersonality.values
            .firstWhere((e) => e.myLabel == userProfile!.characterPersonality,
                orElse: () => CharacterPersonality.probSolver)
            .dbValue
        : null;

// chat 페이지로 넘어가는 reason에 따라 다른 메시지를 선택
// API를 통해 성향에 맞는 후속 질문 멘트 가져오기
    final content =
        await ref.read(homeDialogueRepositoryProvider).fetchFollowUpDialogue(
              reason: reason,
              personality: personalityDbValue,
              userNickNm: userProfile?.userNickNm,
            );
    await _addMessage(
        Message(userId: currentUserId, content: content, sender: Sender.bot));

    if (solutionType == 'video') {
      await _addMessage(Message(
        userId: currentUserId,
        content: "이번 영상은 어떠셨나요?",
        sender: Sender.bot,
        type: MessageType.solutionFeedback,
        proposal: {
          'solution_id': solutionId,
          'session_id': sessionId,
          'solution_type': solutionType
        },
      ));
    }

    if (topCluster == 'sleep') {
      final tip = await userVM.fetchSleepHygieneTip();
      await _addMessage(
          Message(userId: currentUserId, content: tip, sender: Sender.bot));
    } else if (topCluster == 'neg_low') {
      final mission = await userVM.fetchActionMission();
      await _addMessage(
          Message(userId: currentUserId, content: mission, sender: Sender.bot));
    }
    _lastProposedSolutionCluster = null;
  }

  //   // 1. 일반 후속 메시지 전송
  //   final followUpMessage = Message(
  //     userId: currentUserId,
  //     content: content,
  //     sender: Sender.bot,
  //     type: MessageType.normal,
  //   );
  //   await _addMessage(followUpMessage);

  //   // 2. 피드백 요청 메시지 전송
  //   final feedbackMessage = Message(
  //     userId: currentUserId,
  //     content: AppTextStrings.solutionFeedbackQuestion,
  //     sender: Sender.bot,
  //     type: MessageType.solutionFeedback,
  //     proposal: {
  //       'solution_id': solutionId,
  //       'session_id': sessionId,
  //       'solution_type': solutionType,
  //     },
  //   );
  //   await _addMessage(feedbackMessage);

  //   // RIN: 클러스터별 추가 솔루션 제공 로직
  //   if (topCluster == 'sleep') {
  //     final userVM = ref.read(userViewModelProvider.notifier);
  //     final tip = await userVM.fetchSleepHygieneTip();
  //     await _addMessage(
  //         Message(userId: currentUserId, content: tip, sender: Sender.bot));
  //   } else if (topCluster == 'neg_low') {
  //     final userVM = ref.read(userViewModelProvider.notifier);
  //     final mission = await userVM.fetchActionMission();
  //     await _addMessage(
  //         Message(userId: currentUserId, content: mission, sender: Sender.bot));
  //   }
  //   _lastProposedSolutionCluster = null;
  // }

  //RIN: 사용자의 피드백 응답 처리
  Future<void> respondToSolutionFeedback({
    required String solutionId,
    String? sessionId,
    required String solutionType,
    required String feedback,
    required String messageIdToRemove,
  }) async {
    final currentUserId = _userId;
    if (currentUserId == null) return;

    // 1. UI에서 피드백 메시지(버튼) 제거 (Optimistic UI)
    state = state.copyWith(
      messages: state.messages.where((m) => m.id != messageIdToRemove).toList(),
    );

    // 2. ViewModel을 통해 Repository -> DataSource -> Backend API 호출
    try {
      await ref.read(userViewModelProvider.notifier).submitSolutionFeedback(
            solutionId: solutionId,
            sessionId: sessionId,
            solutionType: solutionType,
            feedback: feedback,
          );

      // 3. 사용자에게 감사 메시지 표시
      final thanksMessage = Message(
        userId: currentUserId,
        content: "피드백을 주셔서 고마워요! 다음 솔루션에 꼭 참고할게요. 😊",
        sender: Sender.bot,
      );
      await _addMessage(thanksMessage);
    } catch (e) {
      print("Error submitting feedback: $e");
      // 필요하다면 에러 메시지를 채팅에 표시
    }
  }

// RIN: ADHD 초기 질문에 대한 사용자의 버튼 선택을 처리
  Future<void> respondToAdhdChoice(
      String choiceAction, String choiceLabel) async {
    final currentUserId = _userId;
    if (currentUserId == null) return;

    // 1. 사용자의 선택을 채팅창에 메시지로 표시
    await _addMessage(Message(
      userId: currentUserId,
      content: choiceLabel,
      sender: Sender.user,
    ));

    // 2. adhd_context와 함께 백엔드에 다시 분석 요청
    await _analyzeAndRespond(
      userMessage: state.messages.last,
      textForAnalysis: choiceAction,
      emotion: null,
      adhdContext: _adhdContextForNextRequest,
    );

    _adhdContextForNextRequest = null;
  }

  /// 솔루션 제안에 대한 사용자 응답 처리

  Future<void> respondToSolution(
      Map<String, dynamic> proposalData, String action,
      {bool isReview = false}) async {
    final currentUserId = _userId;
    if (currentUserId == null) return;

    final String solutionId = proposalData['solution_id'] as String;
    final String solutionType = proposalData['solution_type'] as String;
    final String? sessionId = proposalData['session_id'] as String?;

    if (action == "accept_solution") {
      if (solutionType == 'action') {
        final missionText = await ref
            .read(solutionRepositoryProvider)
            .fetchSolutionTextById(solutionId);
        if (missionText != null) {
          await _addMessage(Message(
              userId: currentUserId, content: missionText, sender: Sender.bot));
        }
      } else {
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
        String path = (solutionType == 'breathing')
            ? '/breathing/$solutionId?sessionId=$sessionId&isReview=$isReview'
            : '/solution/$solutionId?sessionId=$sessionId&isReview=$isReview';
        final result = await navigatorkey.currentContext
            ?.push(path, extra: {'solution_type': solutionType});
        if (result is Map<String, dynamic>) {
          processSolutionResult(result);
        }
      }
    } else if (action == "decline_solution_and_talk") {
      // 사용자 프로필에서 캐릭터 성향과 닉네임 가져오기
      final userProfile = ref.read(userViewModelProvider).userProfile;
      final personality = userProfile?.characterPersonality;
      final personalityDbValue = personality != null
          ? CharacterPersonality.values
              .firstWhere((e) => e.myLabel == personality,
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
    } else if (action == "safety_crisis") {
      String title = AppTextStrings.counselingCenter;
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
