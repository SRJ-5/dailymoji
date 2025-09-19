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
  ChatState build() => ChatState();

  // 메세지 불러오기 + 실시간 구독 시작
  Future<void> loadMessages(String userId) async {
    try {
      // 1. 메세지 불러오기
      final loadMessagesUseCase = ref.read(loadMessagesUseCaseProvider);
      final msgs = await loadMessagesUseCase.execute(userId: userId);
      state = state.copyWith(messages: msgs);

      // 2. 실시간 구독
      final subscribeUseCase = ref.read(subscribeMessagesUseCaseProvider);
      subscribeUseCase.execute(
        userId: userId,
        onNewMessage: (message) {
          state = state.copyWith(messages: [...state.messages, message]);
        },
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  // 메세지 전송
  Future<void> sendMessage(Message message) async {
    final sendMessageUseCase = ref.read(sendMessageUseCaseProvider);
    try {
      await sendMessageUseCase.execute(message);

      // 봇이 입력 중
      state = state.copyWith(isTyping: true);
      await Future.delayed(const Duration(seconds: 2));
      state = state.copyWith(isTyping: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isTyping: false);
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
