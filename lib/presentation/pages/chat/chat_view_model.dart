import 'package:dailymoji/core/constants/presets.dart';
import 'package:dailymoji/core/providers.dart';
import 'package:dailymoji/domain/entities/emotional_record.dart';
import 'package:dailymoji/domain/entities/message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final _userId = "8dfc1a65-1fae-47f6-81f4-37257acc3db6";
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

    // 1. 사용자 메시지 UI에 표시
    state = state.copyWith(messages: [...state.messages, message]);

    try {
      // --- TODO: 사용자 온보딩 점수를 가져오기!!  ---
      // 이 부분은 나중에 User Repository에서 가져오는 로직으로 대체하면 됨.
      // 예시: final onboardingData = await ref.read(userRepositoryProvider).getOnboardingScores();
      final onboardingData = {
        "q1": 2,
        "q2": 3,
        "q3": 1,
        "q4": 2,
        "q5": 1,
        "q6": 2,
        "q7": 1,
        /* 3 - 1 = 2점 */ "q8": 2,
        "q9": 1
      };

      // 2. 메시지를 DB에 저장
      final savedMessage = await sendMessageUseCase.execute(message);
      // 로컬 메시지를 DB에 저장된 버전으로 교체
      final updatedMessages = [...state.messages];
      updatedMessages[updatedMessages.length - 1] = savedMessage;
      state = state.copyWith(messages: updatedMessages);

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

      // 5. 응답 결과에 따라 분기 처리!
      Message botResponseMessage;
      final String? newSessionId = emotionalRecord.sessionId;

      final presetId = emotionalRecord.interventionPresetId;
      print("✅ Received presetId from backend: '$presetId'");

      // 5-1. 친구 모드인지 먼저 확인
      if (presetId == PresetIds.friendlyReply) {
        botResponseMessage = Message(
            userId: _userId,
            content: emotionalRecord.intervention['text'] as String? ??
                "죄송해요, 답변을 준비하는 중에 오류가 발생했어요. 다시 한번 말씀해주시겠어요?",
            sender: Sender.bot,
            type: MessageType.normal);
      }
      // 5-2. 그 외 모든 경우("분석", "안전" 등)는 솔루션/개입으로 간주
      else {
        String content;

        // 5-2-1. intervention에 미리 작성된 'text'가 있는지 확인 (안전 모드 등)
        if (emotionalRecord.intervention.containsKey('text')) {
          content = emotionalRecord.intervention['text'] as String? ??
              "분석 결과를 표시할 수 없어요.";
        }
        // 5-2-2. 'text'가 없다면, 점수를 바탕으로 요약문 생성 (일반 분석 모드)
        else {
          content = emotionalRecord.toSummaryMessage();
        }

        botResponseMessage = Message(
            userId: _userId,
            content: content,
            sender: Sender.bot,
            type: MessageType.normal);

        // "분석 모드" 계열일 때만 session_id 업데이트
        final newSessionId = emotionalRecord.sessionId;
        if (newSessionId != null && savedMessage.id != null) {
          await updateSessionIdUseCase.execute(
            messageId: savedMessage.id!,
            sessionId: newSessionId,
          );
        }
      }

      // 6. 생성된 AI 응답 메시지를 DB(raw_chats)에 먼저 저장하고,
      //    'ID가 부여된' 결과 객체를 돌려받습니다.
      final savedBotMessage =
          await sendMessageUseCase.execute(botResponseMessage);

      // 7. UI 최종 업데이트
      // 현재 메시지 목록에서 마지막 항목("모지가 입력하고 있어요...")을 제거합니다.
      final finalMessages = [...state.messages]..removeLast();

      // 이전에 ID 없이 추가했던 botResponseMessage 대신,
      // ID가 포함된 'savedBotMessage'를 화면에 추가합니다.      finalMessages.add(botResponseMessage);
      finalMessages.add(savedBotMessage);

      // 새로운 메시지 목록으로 state를 업데이트하고, isTyping 상태를 false로 변경합니다.
      state = state.copyWith(messages: finalMessages, isTyping: false);
    } catch (e) {
      print("sendMessage or analyzeEmotion error : $e");

      // 혹시나 슈퍼베이스 저장 실패 시
      final updatedMessages = [...state.messages]..removeLast();
      state = state.copyWith(
        messages: updatedMessages,
        errorMessage: "감정 분석에 실패했어요. 😥",
        isTyping: false,
      );
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
