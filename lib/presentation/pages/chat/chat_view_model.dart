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
      // 2. 메시지를 DB에 저장
      final savedMessage = await sendMessageUseCase.execute(message);
      // 로컬 메시지를 DB에 저장된 버전으로 교체
      final updatedMessages = [...state.messages];
      updatedMessages[updatedMessages.length - 1] = savedMessage;
      state = state.copyWith(messages: updatedMessages);

      // 3. 감정 분석 시작 (UI에 분석 중 메시지 표시)
      final analyzingMessage = Message(
        userId: _userId,
        content: "모지가 입력하고 있어요...", // 그냥 "입력중.."?
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
      );

      // 5. 응답 결과에 따라 분기 처리!
      Message botResponseMessage;
      final String? newSessionId = emotionalRecord.sessionId;

      // 4-A. 백엔드에서 "친구 모드"로 응답했을 때
      // intervention 맵에서 'text' 키를 찾아 AI의 대화 내용을 가져옵니다.

      if (emotionalRecord.interventionPresetId == "FRIENDLY_REPLY") {
        botResponseMessage = Message(
          userId: _userId,
          content: emotionalRecord.intervention['text'] as String? ?? "...",
          sender: Sender.bot,
          type: MessageType.normal,
        );
      } else {
        // 4-B. "분석 모드" 응답
        // toSummaryMessage()를 사용해 분석 요약문을 생성합니다.

        botResponseMessage = Message(
            userId: _userId,
            content: emotionalRecord.toSummaryMessage(),
            sender: Sender.bot,
            type: MessageType.normal);

        // (업데이트) "분석 모드"일 때만 session_id를 연결합니다.
        // newSessionId와 savedUserMessage.id가 모두 유효한 값일 때만 실행합니다.
        if (newSessionId != null && savedMessage.id != null) {
          print("사용자 메시지(${savedMessage.id})에 세션(${newSessionId})을 연결합니다.");
          await updateSessionIdUseCase.execute(
            messageId: savedMessage.id!,
            sessionId: newSessionId,
          );
        }
      }

      // 5. 생성된 AI 응답 메시지를 DB(raw_chats)에 먼저 저장하고,
      //    'ID가 부여된' 결과 객체를 돌려받습니다.
      final savedBotMessage =
          await sendMessageUseCase.execute(botResponseMessage);

      // 6. UI 최종 업데이트
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
