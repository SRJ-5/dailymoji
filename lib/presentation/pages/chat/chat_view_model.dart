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
          // 봇의 응답만 구독을 통해 받도록 필터링 (내가 보낸 메시지는 즉시 추가되므로)
          if (message.sender == Sender.bot) {
            state = state.copyWith(messages: [...state.messages, message]);
          }
        }
      },
    );
  }

  // 메세지 전송
  Future<void> sendMessage(Message message, String emotion) async {
    final sendMessageUseCase = ref.read(sendMessageUseCaseProvider);
    final analyzeEmotionUseCase = ref.read(analyzeEmotionUseCaseProvider);

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
        content: "모지가 감정을 분석하고 있어요...",
        sender: Sender.bot,
        type: MessageType.analysis,
      );

      // 봇이 입력 중
      state = state.copyWith(
        isTyping: true,
        messages: [...state.messages, analyzingMessage],
      );
      // 4. Supabase Edge Function 호출하여 감정 분석
      final EmotionalRecord emotionalRecord =
          await analyzeEmotionUseCase.execute(
        userId: _userId,
        text: message.content,
        emotion: emotion,
      );

      // 5. 분석 결과 메시지 생성 및 이전 분석 중 메시지 교체
      final analysisResultMessage = Message(
        userId: _userId,
        content: emotionalRecord.toSummaryMessage(),
        sender: Sender.bot,
        type: MessageType.normal,
      );
      final finalMessages = [...state.messages]..removeLast(); // 분석 중 메시지 제거
      finalMessages.add(analysisResultMessage); // 결과 메시지 추가

      state = state.copyWith(messages: finalMessages, isTyping: false);

      // await Future.delayed(const Duration(seconds: 2));
      // state = state.copyWith(isTyping: false);
    } catch (e) {
      print("sendMessage or analyzeEmotion error : $e");
      final errorMessage = Message(
        userId: _userId,
        content: "감정 분석에 실패했어요. 😥",
        sender: Sender.bot,
        type: MessageType.normal,
      );

      // 혹시나 슈퍼베이스 저장 실패 시
      final updatedMessages = [...state.messages]..removeLast();
      state = state.copyWith(
        messages: updatedMessages,
        errorMessage: e.toString(),
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
