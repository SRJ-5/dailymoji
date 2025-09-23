import 'dart:math';

import 'package:dailymoji/core/constants/presets.dart';
import 'package:dailymoji/core/constants/solution_scripts.dart';
import 'package:dailymoji/core/providers.dart';
import 'package:dailymoji/core/routers/router.dart';
import 'package:dailymoji/domain/entities/emotional_record.dart';
import 'package:dailymoji/domain/entities/message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ChatState {
  final List<Message> messages;
  final bool isTyping; // 봇이 입력 중인지 표시 - 'isLoading' 또는 'isAnalyzing'으로 사용
  final String? errorMessage;

  ChatState({
    this.messages = const [],
    this.isTyping = false,
    this.errorMessage,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isTyping,
    String? errorMessage,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      errorMessage: errorMessage,
    );
  }
}

class ChatViewModel extends Notifier<ChatState> {
  final _userId = "c4349dd9-39f2-4788-a175-6ec4bd4f7aba";
  @override
  ChatState build() {
    _init(_userId);
    return ChatState();
  }

  Future<void> _init(String userId) async {
    await _loadMessages(userId);
    _subscribeToMessages(userId);
  }

  // 메세지 불러오기 + 실시간 구독 시작
  Future<void> _loadMessages(String userId) async {
    try {
      // 메세지 불러오기
      final loadMessagesUseCase = ref.read(loadMessagesUseCaseProvider);
      final msgs = await loadMessagesUseCase.execute(userId: userId);
      state = state.copyWith(messages: msgs);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  void _subscribeToMessages(String userId) {
    // 실시간 구독
    final subscribeUseCase = ref.read(subscribeMessagesUseCaseProvider);
    subscribeUseCase.execute(
      userId: userId,
      onNewMessage: (message) {
        final isExist = state.messages.any((m) => m.id == message.id);
        if (!isExist) {
          // // 봇의 응답만 구독을 통해 받도록 필터링 (내가 보낸 메시지는 즉시 추가되므로)
          // if (message.sender == Sender.bot) {
          state = state.copyWith(messages: [...state.messages, message]);
          // }
        }
      },
    );
  }

  // 메세지 전송
  Future<void> sendMessage(Message message, String emotion) async {
    final sendMessageUseCase = ref.read(sendMessageUseCaseProvider);
    final analyzeEmotionUseCase = ref.read(analyzeEmotionUseCaseProvider);
    final updateSessionIdUseCase =
        ref.read(updateMessageSessionIdUseCaseProvider);

    // 1. 사용자 메시지 UI에 먼저 표시하고 DB에 저장
    state = state.copyWith(messages: [...state.messages, message]);
    final savedMessage = await sendMessageUseCase.execute(message);
    // UI의 메시지를 DB에 저장된 버전(ID 포함)으로 교체
    final updatedMessages = [...state.messages]..removeLast();
    updatedMessages.add(savedMessage);
    state = state.copyWith(messages: updatedMessages);

    try {
      // --- TODO: 사용자 온보딩 점수를 가져오기!!  ---
      // 이 부분은 나중에 User Repository에서 가져오는 로직으로 대체하면 됨.
      final onboardingData = {
        "q1": 2,
        "q2": 3,
        "q3": 1,
        "q4": 2,
        "q5": 1,
        "q6": 2,
        "q7": 1,
        "q8": 2,
        "q9": 1
      };

      // 3. 감정 분석 시작 (UI에 분석 중 메시지 표시)
      final analyzingMessage = Message(
        userId: _userId,
        content: "모지가 입력하고 있어요...", // TODO: 이거 닉네임 연결해야함
        sender: Sender.bot,
        type: MessageType.analysis,
      );
      // 봇이 입력 중
      state = state.copyWith(
        isTyping: true,
        messages: [...state.messages, analyzingMessage],
      );
      // 4. 백앤드 API 호출하여
      final EmotionalRecord emotionalRecord =
          await analyzeEmotionUseCase.execute(
        userId: _userId,
        text: message.content,
        emotion: emotion,
        onboarding: onboardingData,
      );
      // "입력 중..." 메시지 제거 (봇의 최종 응답을 추가하기 전)
      final tempMessages = [...state.messages]..removeLast();
      state = state.copyWith(messages: tempMessages);

      // 5. 응답 결과에 따라 분기 처리!
      // Message botResponseMessage;
      // final String? newSessionId = emotionalRecord.sessionId;

      final presetId = emotionalRecord.interventionPresetId;
      print("✅ Received presetId from backend: '$presetId'");

      switch (presetId) {
        // 5-1. 친구 모드
        case PresetIds.friendlyReply:
          final botMessage = Message(
            userId: _userId,
            content: emotionalRecord.intervention['text'] as String,
            sender: Sender.bot,
          );
          await _addBotMessageToChat(botMessage);
          break;

        // 5-2. 안전 위기 모드
        case PresetIds.safetyCrisisModal:
        case PresetIds.safetyCrisisSelfHarm:
        case PresetIds.safetyCrisisAngerAnxiety:
        case PresetIds.safetyCheckIn:
          final cluster = emotionalRecord.intervention['cluster'] as String;
          final solutionId =
              emotionalRecord.intervention['solution_id'] as String;
          // 안전 위기 멘트는 Flutter에 내장된 라이브러리에서 가져옴
          final safetyText = kSolutionProposalScripts[cluster]?.first ??
              "많이 힘드시군요. 도움이 필요하시면 연락주세요.";

          final botMessage = Message(
              userId: _userId,
              content: safetyText,
              sender: Sender.bot,
              type: MessageType.solutionProposal, // 제안 타입으로 버튼 표시
              proposal: {
                "solution_id": solutionId,
                "options": [
                  {"label": "도움받기", "action": "accept_solution"},
                  {"label": "괜찮아요", "action": "decline_solution_and_talk"}
                ]
              });
          await _addBotMessageToChat(botMessage);
          break;

        // 5-3. 일반 분석 및 솔루션 제안 모드
        case PresetIds.solutionProposal:
          final interventionData = emotionalRecord.intervention;

          final topCluster =
              emotionalRecord.intervention['top_cluster'] as String;

          // 0. [분석 결과 요약] 메시지를 먼저 생성하기!!! (예: "우울/무기력 감정이 81%...")
          final summaryMessage = Message(
            userId: _userId,
            content: emotionalRecord.toSummaryMessage(),
            sender: Sender.bot,
          );
          // DB 저장 후 UI에 즉시 추가
          await _addBotMessageToChat(summaryMessage);

          // 사용자가 읽을 시간을 주기 위해 잠시 대기
          await Future.delayed(const Duration(milliseconds: 1200));

          // 1. 과학적 설명 멘트 (랜덤 선택)
          final summaryScripts = kClusterSummaryScripts[topCluster]!;
          final summaryText =
              summaryScripts[Random().nextInt(summaryScripts.length)];
          final scientificMessage = Message(
              userId: _userId, content: summaryText, sender: Sender.bot);
          await _addBotMessageToChat(scientificMessage);

          await Future.delayed(const Duration(milliseconds: 1200));

          // 2. [솔루션 제안] 멘트와 버튼을 생성합니다.
          final proposalScripts = kSolutionProposalScripts[topCluster]!;
          final proposalText =
              proposalScripts[Random().nextInt(proposalScripts.length)];
          final proposalMessage = Message(
              userId: _userId,
              content: proposalText,
              sender: Sender.bot,
              type: MessageType.solutionProposal,
              proposal: {
                "solution_id": emotionalRecord.intervention['solution_id'],
                "options": [
                  {"label": "좋아, 해볼게", "action": "accept_solution"},
                  {"label": "아니, 그냥 말할래", "action": "decline_solution_and_talk"}
                ]
              });
          await _addBotMessageToChat(proposalMessage);
          break;

        default:
          final errorMessage = Message(
              userId: _userId,
              content: "죄송해요, 응답을 이해할 수 없었어요.",
              sender: Sender.bot);
          await _addBotMessageToChat(errorMessage);
      }

      // "분석 모드" 계열일 때만 session_id 업데이트
      final newSessionId = emotionalRecord.sessionId;
      if (newSessionId != null && savedMessage.id != null) {
        await updateSessionIdUseCase.execute(
          messageId: savedMessage.id!,
          sessionId: newSessionId,
        );
      }
    } catch (e, stackTrace) {
      print("sendMessage or analyzeEmotion error : $e");
      print(stackTrace);
      final updatedMessages = [...state.messages]..removeLast();
      state = state.copyWith(
        messages: updatedMessages,
        errorMessage: "감정 분석에 실패했어요. 😥",
      );
    } finally {
      state = state.copyWith(isTyping: false);
    }
  }

  // --- 봇 메시지를 DB 저장 후 UI에 추가하는 헬퍼 메소드 ---
  Future<void> _addBotMessageToChat(Message botMessage) async {
    final savedBotMessage =
        await ref.read(sendMessageUseCaseProvider).execute(botMessage);
    state = state.copyWith(messages: [...state.messages, savedBotMessage]);
  }

  // --- 버튼 클릭 시 호출될 새로운 메소드 ---
  Future<void> respondToSolution(String solutionId, String action) async {
    if (action == "decline_solution_and_talk") {
      final message = Message(
          userId: _userId,
          content: "네, 좋아요. 귀 기울여 듣고 있을게요.",
          sender: Sender.bot);
      await _addBotMessageToChat(message);
      return;
    }

    if (action == "accept_solution") {
      // solutionId를 가지고 Breathing 페이지로 이동
      navigatorkey.currentContext?.go('/breathing/$solutionId');
    }
  }

  /// 에러 초기화
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final chatViewModelProvider = NotifierProvider<ChatViewModel, ChatState>(
  () => ChatViewModel(),
);
