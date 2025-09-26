// 0924 변경: 채팅방 상태 오류 및 분석 누락 해결 (EMOJI ONLY)
import 'package:dailymoji/core/constants/emoji_assets.dart';
import 'package:dailymoji/core/constants/emotion_map.dart';
import 'package:dailymoji/core/constants/presets.dart';
import 'package:dailymoji/core/constants/solution_scripts.dart';
import 'package:dailymoji/core/providers.dart';
import 'package:dailymoji/core/routers/router.dart';
import 'package:dailymoji/domain/entities/message.dart';
import 'package:dailymoji/domain/enums/enum_data.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/user_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ChatState {
  final List<Message> messages;
  final bool isTyping;
  final String? errorMessage;
  final bool isLoading; // 로딩 상태 추가

  ChatState({
    this.messages = const [],
    this.isTyping = false,
    this.errorMessage,
    this.isLoading = true,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isTyping,
    String? errorMessage,
    bool? isLoading,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ChatViewModel extends Notifier<ChatState> {
  // ---------------------------------------------------------------------------
  // State & Dependencies
  // ---------------------------------------------------------------------------

  // UserViewModel에서 실제 ID를 가져오고, 없으면 임시 ID 사용(개발용)
  String? get _userId =>
      ref.read(userViewModelProvider).userProfile?.id ??
      "ffc9c57c-b744-4924-a3e7-65781ecf6ab3";

  //사용자의 텍스트 답변을 기다리는 이모지 상태
  String? _pendingEmotionForAnalysis;

  @override
  ChatState build() => ChatState();

// ---------------------------------------------------------------------------
  // Core Methods
  // ---------------------------------------------------------------------------

  // --- Rin: 채팅방 진입 시 초기화 로직 ---
  Future<void> enterChatRoom(String? emotionFromHome) async {
    final currentUserId = _userId; // Getter를 통해 현재 ID 가져오기
    if (currentUserId == null) {
      print(
          "RIN: 🚨 [ViewModel] ERROR: User ID is null. Cannot enter chat room.");
      state = state.copyWith(isLoading: false, errorMessage: "로그인 정보가 없습니다.");
      return;
    }
    _subscribeToMessages(currentUserId);

    // 1. 오늘 대화 기록 불러오기
    await _loadTodayMessages(currentUserId);

    // 홈에서 이모지를 선택하고 들어온 경우, 대화 흐름 시작
    if (emotionFromHome != null) {
      // 1. UI에 표시할 메시지 객체들을 먼저 생성
      final emojiMessage = Message(
        userId: currentUserId,
        sender: Sender.user,
        type: MessageType.image,
        imageAssetPath: kEmojiAssetMap[emotionFromHome],
      );
      // // 2. 시스템 메시지 객체 생성
      // final displayEmotion =
      //     kEmotionKeyToDisplay[emotionFromHome] ?? emotionFromHome;
      // final systemMessage = Message(
      //   userId: currentUserId,
      //   sender: Sender.bot,
      //   type: MessageType.system,
      //   content: "$displayEmotion 상태에 맞춰 대화를 진행할게요.",
      // );
// // 3. 이모지와 시스템 메시지를 한 번에 UI에 업데이트 (동시 표시)
//       state = state
//           .copyWith(messages: [...state.messages, emojiMessage, systemMessage]);

      state = state.copyWith(messages: [...state.messages, emojiMessage]);

      // 4. UI 업데이트 이후, 백그라운드에서 대화 시작 로직 실행
      await _startConversationWithEmoji(emojiMessage, emotionFromHome);
    }
  }

  // // ---------------------------------------------------------------------------
  // // 메시지 로드 & 구독
  // // ---------------------------------------------------------------------------

  /// 사용자 텍스트 메시지 전송
  Future<void> sendMessage(
      String content, String currentSelectedEmotion) async {
    final currentUserId = _userId;
    if (currentUserId == null) return;

    final message = Message(
      userId: currentUserId,
      content: content,
      sender: Sender.user,
      type: MessageType.normal,
    );
    final savedMessage = await _addUserMessageToChat(message);

// 대기 중인 이모지가 있으면 그것을 분석에 사용하고, 없으면 현재 입력창의 이모지를 사용
    final emotionForAnalysis =
        _pendingEmotionForAnalysis ?? currentSelectedEmotion;

    // 대기 중인 이모지를 사용했으므로, 이제 상태를 초기화
    if (_pendingEmotionForAnalysis != null) {
      _pendingEmotionForAnalysis = null;
    }
    // 백엔드에 종합 분석 요청
    await _analyzeAndRespond(
      userMessage: savedMessage,
      textForAnalysis: message.content,
      emotion: emotionForAnalysis,
    );
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

    // // 2. 시스템 메시지 객체 생성
    // final displayEmotion = kEmotionKeyToDisplay[emotion] ?? emotion;
    // final systemMessage = Message(
    //   userId: currentUserId,
    //   sender: Sender.bot,
    //   type: MessageType.system,
    //   content: "$displayEmotion 상태에 맞춰 대화를 진행할게요.",
    // );

    // // 3. 이모지와 시스템 메시지를 한 번에 UI에 업데이트
    // state = state
    //     .copyWith(messages: [...state.messages, emojiMessage, systemMessage]);

    // 4. 백그라운드에서 대화 시작 로직 실행
    //    (UI에는 이미 추가했으므로, 이 함수는 DB 저장 및 봇 질문 로직만 담당)
    await _startConversationWithEmoji(emojiMessage, emotion);
  }

// ---------------------------------------------------------------------------
// Helper Methods
// ---------------------------------------------------------------------------

  /// 이모지 선택 후 공감 질문으로 이어지는 대화 시작 로직
  /// DB 저장 및 봇 질문 로직을 담당하므로
  /// UI에 메시지를 중복으로 추가하지 않도록 조심하기!!
  Future<void> _startConversationWithEmoji(
      Message emojiMessage, String emotion) async {
    // Optimistic UI: UI에 메시지가 이미 있는지 확인하여 중복 추가 방지
    final isAlreadyInState =
        state.messages.any((m) => m.tempId == emojiMessage.tempId);

// [CHANGED] 저장된 메시지 객체를 반드시 확보해서 sessionId 업데이트에 사용
    Message savedEmojiMsg;

    if (isAlreadyInState) {
      // DB에만 저장하고 UI는 건드리지 않음
      final saved =
          await ref.read(sendMessageUseCaseProvider).execute(emojiMessage);
      savedEmojiMsg = saved;
    } else {
      // 만약 UI에 없다면 추가 (안전장치)
      final saved = await _addUserMessageToChat(
          emojiMessage); // _addUserMessageToChat은 Message를 반환
      savedEmojiMsg = saved;
    }

    _pendingEmotionForAnalysis = emotion;
    final currentUserId = _userId!;

    try {
      //리액션 스크립트로 질문/공감 멘트
      // - 서버 /analyze(text="") 퀵세이브 → sessionId + 대사(text) 동시 수신
      final emojiRepo = ref.read(emojiReactionRepositoryProvider);
      final result = await emojiRepo.getReactionWithSession(
        userId: currentUserId,
        emotion: emotion,
        onboarding:
            ref.read(userViewModelProvider).userProfile?.onboardingScores ?? {},
      );

      // 세션 연결
      if (result.sessionId != null && savedEmojiMsg.id != null) {
        await ref.read(updateMessageSessionIdUseCaseProvider).execute(
              messageId: savedEmojiMsg.id!,
              sessionId: result.sessionId!,
            );
      }

      // 받은 대사 보여지기
      final questionMessage = Message(
        userId: currentUserId,
        sender: Sender.bot,
        content: result.text, // 서버가 준 reaction_text
      );
      await _addBotMessageToChat(questionMessage);
    } catch (e) {
      //fallback
      print("RIN: 🚨 Failed to fetch reaction script: $e");
      final fallbackMessage = Message(
          userId: currentUserId,
          sender: Sender.bot,
          content: "어떤 일 때문에 그렇게 느끼셨나요?");
      await _addBotMessageToChat(fallbackMessage);
    }
  }

  // 백엔드에 감정 분석 및 솔루션 제안 요청
  Future<void> _analyzeAndRespond({
    required Message userMessage,
    required String textForAnalysis,
    required String emotion,
  }) async {
    final currentUserId = _userId;
    if (currentUserId == null) return;

    final userState = ref.read(userViewModelProvider);
    final characterName = userState.userProfile?.characterNm ?? "모지";

    // "입력 중..." 메시지 표시
    final analyzingMessage = Message(
        userId: currentUserId,
        content: "$characterName이(가) 입력하고 있어요...",
        sender: Sender.bot,
        type: MessageType.analysis);
    state = state.copyWith(
        isTyping: true, messages: [...state.messages, analyzingMessage]);

    try {
      // /analyze 앤드포인트 연결
      final emotionalRecord =
          await ref.read(analyzeEmotionUseCaseProvider).execute(
                userId: currentUserId,
                text: textForAnalysis,
                emotion: emotion,
                onboarding: userState.userProfile?.onboardingScores ?? {},
              );

      // "입력 중..." 메시지 제거
      state = state.copyWith(
          messages: state.messages
              .where((m) => m.type != MessageType.analysis)
              .toList());

      final sessionId = emotionalRecord.sessionId;
      // intervention은 이제 항상 Map 형태입니다.
      final intervention = emotionalRecord.intervention;
      final presetId = intervention['preset_id'] as String?;

      switch (presetId) {
        // // Rin: 이모지에 대한 공감/질문 응답 처리하는 case
        // case PresetIds.emojiReaction:
        case PresetIds.friendlyReply:
          final botMessage = Message(
            userId: currentUserId,
            content: emotionalRecord.intervention['text'] as String,
            sender: Sender.bot,
          );
          await _addBotMessageToChat(botMessage);
          break; // 여기서 대화 흐름이 한번 끝남

        case PresetIds.solutionProposal:
          // intervention 맵에서 직접 데이터를 안전하게 추출합니다.
          // `as String?`을 사용하여, 혹시 키가 없더라도 null로 처리되어 앱이 멈추지 않습니다.
          final empathyText = intervention['empathy_text'] as String?;
          final analysisText = intervention['analysis_text'] as String?;
          final topCluster = intervention['top_cluster'] as String?;

          // 1. [공감] 메시지 먼저 보내기 (null이 아닐 때만)
          if (empathyText != null) {
            final empathyMessage = Message(
              userId: currentUserId,
              content: empathyText,
              sender: Sender.bot,
            );
            await _addBotMessageToChat(empathyMessage);
            await Future.delayed(const Duration(milliseconds: 1000));
          }

          // 2. [분석 결과] 메시지 보내기 (null이 아닐 때만)
          if (analysisText != null) {
            final analysisMessage = Message(
                userId: currentUserId,
                content: analysisText,
                sender: Sender.bot);
            await _addBotMessageToChat(analysisMessage);
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
                {"label": "도움받기", "action": "accept_solution"},
                {"label": "괜찮아요", "action": "decline_solution_and_talk"}
              ]
            },
          );
          await _addBotMessageToChat(botMessage);
          break;

        default:
          final errorMessage = Message(
            userId: currentUserId,
            content: "죄송해요, 응답을 이해할 수 없었어요.",
            sender: Sender.bot,
          );
          await _addBotMessageToChat(errorMessage);
      }

      // 세션 ID 업데이트
      if (sessionId != null && userMessage.id != null) {
        await ref.read(updateMessageSessionIdUseCaseProvider).execute(
              messageId: userMessage.id!,
              sessionId: sessionId,
            );
      }
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
          "options": [
            {"label": "좋아, 해볼게", "action": "accept_solution"},
            {"label": "아니, 그냥 말할래", "action": "decline_solution_and_talk"}
          ]
        },
      );
      await _addBotMessageToChat(proposalMessage);
    } catch (e) {
      print("RIN: 🚨 [ViewModel] Failed to propose solution: $e");
      final errorMessage = Message(
          userId: currentUserId,
          content: "솔루션을 제안하는 중에 문제가 발생했어요.",
          sender: Sender.bot);
      await _addBotMessageToChat(errorMessage);
    }
  }

  // ---------------------------------------------------------------------------
  // Data & State Management Utilities
  // ---------------------------------------------------------------------------

  // --- Rin: 오늘 대화 기록 불러오기 ---
  Future<void> _loadTodayMessages(String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      final msgs =
          await ref.read(loadMessagesUseCaseProvider).execute(userId: userId);
      // DB에서 가져온 메시지를 createdAt(생성 시간) 기준으로 정렬해야함!
      msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      state = state.copyWith(messages: msgs, isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
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

  /// UI에 사용자 메시지 추가 및 DB 저장 (Optimistic UI)
  Future<Message> _addUserMessageToChat(Message message) async {
    // 1. UI에 즉시 메시지 추가
    state = state.copyWith(messages: [...state.messages, message]);

    try {
      // 2. DB에 메시지 저장
      final savedMessageFromDB =
          await ref.read(sendMessageUseCaseProvider).execute(message);

      // 3. UI의 임시 메시지를 DB 정보가 포함된 완전한 메시지로 교체
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
      // 에러 발생 시, 낙관적으로 추가했던 메시지를 다시 제거
      state = state.copyWith(
          messages:
              state.messages.where((m) => m.tempId != message.tempId).toList());
      rethrow;
    }
  }

  /// UI에 봇 메시지 추가 및 DB 저장
  Future<void> _addBotMessageToChat(Message botMessage) async {
    final savedBotMessage =
        await ref.read(sendMessageUseCaseProvider).execute(botMessage);
    state = state.copyWith(messages: [...state.messages, savedBotMessage]);
  }

  // ---------------------------------------------------------------------------
  // User Action Handlers
  // ---------------------------------------------------------------------------

  /// 솔루션 제안에 대한 사용자 응답 처리
  Future<void> respondToSolution(String solutionId, String action) async {
    final currentUserId = _userId;
    if (currentUserId == null) return;

    if (action == "decline_solution_and_talk") {
      final message = Message(
          userId: currentUserId,
          content: "저에게 털어놓으세요. 귀 기울여 듣고 있을게요.",
          sender: Sender.bot);
      await _addBotMessageToChat(message);
      return;
    }

    if (action == "accept_solution") {
      navigatorkey.currentContext?.go('/breathing/$solutionId');
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
