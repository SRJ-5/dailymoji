import 'package:dailymoji/domain/entities/message.dart';
import 'package:dailymoji/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatState {
  final List<Message> messages;
  final bool isTyping; // 봇이 입력 중인지 표시
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
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ChatViewModel extends Notifier<ChatState> {
  @override
  ChatState build() {
    final userId = "8dfc1a65-1fae-47f6-81f4-37257acc3db6";
    _init(userId);
    return ChatState();
  }

  Future<void> _init(String userId) async {
    await loadMessages(userId);
  }

  // 메세지 불러오기 + 실시간 구독 시작
  Future<void> loadMessages(String userId) async {
    try {
      // 메세지 불러오기
      final loadMessagesUseCase = ref.read(loadMessagesUseCaseProvider);
      final msgs = await loadMessagesUseCase.execute(userId: userId);
      state = state.copyWith(messages: msgs);

      // 실시간 구독
      final subscribeUseCase = ref.read(subscribeMessagesUseCaseProvider);
      subscribeUseCase.execute(
        userId: userId,
        onNewMessage: (message) {
          final isExist = state.messages.any((m) => m.id == message.id);
          if (!isExist) {
            state = state.copyWith(messages: [...state.messages, message]);
          }
        },
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  // 메세지 전송
  Future<void> sendMessage(Message message) async {
    final sendMessageUseCase = ref.read(sendMessageUseCaseProvider);
    state = state.copyWith(messages: [...state.messages, message]);
    try {
      final newMessage = await sendMessageUseCase.execute(message);

      final updatedMessages = [...state.messages];

      updatedMessages[updatedMessages.length - 1] = newMessage;

      state = state.copyWith(messages: updatedMessages);

      // 봇이 입력 중
      state = state.copyWith(isTyping: true);
      await Future.delayed(const Duration(seconds: 2));
      state = state.copyWith(isTyping: false);
    } catch (e) {
      print("send error : $e");
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
