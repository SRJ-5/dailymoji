// lib/presentation/pages/chat/chat_view_model.dart
// 0924 변경:
// 1. sendEmojiAsMessage 메서드 추가 (홈 이모지 연동).
// 2. sendMessage 로직을 백엔드 응답 구조 변경에 맞춰 대폭 수정.
//    - 하드코딩된 멘트 조합 로직 제거.
//    - 백엔드가 제공하는 analysisText, proposalText를 바로 사용.
// 3. respondToSolution 메서드 수정 (백엔드 `solution_id` 사용).
// 4. _addBotMessageToChat 헬퍼 메서드 추가하여 코드 중복 제거.

import 'package:dailymoji/core/constants/presets.dart';
import 'package:dailymoji/core/constants/solution_scripts.dart';
import 'package:dailymoji/core/providers.dart';
import 'package:dailymoji/core/routers/router.dart';
import 'package:dailymoji/domain/entities/message.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/user_view_model.dart';
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
  final _userId = "c4349dd9-39f2-4788-a175-6ec4bd4f7aba"; // 임시 사용자 ID
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
      // final loadMessagesUseCase = ref.read(loadMessagesUseCaseProvider);
      final msgs =
          await ref.read(loadMessagesUseCaseProvider).execute(userId: userId);
      state = state.copyWith(messages: msgs);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  void _subscribeToMessages(String userId) {
    // 실시간 구독
    ref.read(subscribeMessagesUseCaseProvider).execute(
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

// 홈에서 온 이모지를 메시지로 보내는 함수
  Future<void> sendEmojiAsMessage(String emotion) async {
    // Unicode 이모지(🥰) 대신, 이미지로 채팅에 입력하기
    final emojiAssetMap = {
      "angry": "assets/images/angry.png",
      "crying": "assets/images/crying.png",
      "shocked": "assets/images/shocked.png",
      "sleeping": "assets/images/sleeping.png",
      "smile": "assets/images/smile.png"
    };

    // 새로운 Message 객체 생성
    final emojiMessage = Message(
      userId: _userId,
      sender: Sender.user,
      type: MessageType.image, // 타입을 'image'로 설정
      imageAssetPath: emojiAssetMap[emotion], // 이미지 경로 전달
      content: "", // 텍스트 내용은 비워둠
    );

    // UI에 이모지 메시지 표시 및 DB 저장
    final savedMessage = await _addUserMessageToChat(emojiMessage);
    // 백엔드에 분석 요청 (이모지 키워드를 text로 전달)
    // 백엔드는 text가 없고 icon만 있는 경우를 감지하여 70/30 로직으로 처리
    await _analyzeAndRespond(savedMessage,
        textForAnalysis: "", emotion: emotion);
  }

  // 일반 텍스트 메시지 전송
  Future<void> sendMessage(Message message, String emotion) async {
    // 1. 사용자 메시지 UI에 표시 및 DB 저장
    final savedMessage = await _addUserMessageToChat(message);
    // 2. 백엔드에 분석 요청
    await _analyzeAndRespond(savedMessage,
        textForAnalysis: message.content, emotion: emotion);
  }

  Future<Message> _addUserMessageToChat(Message message) async {
    state = state.copyWith(messages: [...state.messages, message]);
    final savedMessage =
        await ref.read(sendMessageUseCaseProvider).execute(message);

    // UI 메시지를 DB 저장 버전(ID 포함)으로 교체
    final updatedMessages =
        state.messages.map((m) => m == message ? savedMessage : m).toList();
    state = state.copyWith(messages: updatedMessages);
    return savedMessage;
  }

  Future<void> _analyzeAndRespond(Message userMessage,
      {required String textForAnalysis, required String emotion}) async {
    final userState = ref.read(userViewModelProvider);
    final onboardingData = userState.userProfile?.onboardingScores;
    final characterName = userState.userProfile?.characterNm ?? "모지";

    // 1. 분석 중 메시지 표시
    final analyzingMessage = Message(
      userId: _userId,
      content: "$characterName이(가) 입력하고 있어요...",
      sender: Sender.bot,
      type: MessageType.analysis,
    );
    // 봇이 입력 중
    state = state.copyWith(
        isTyping: true, messages: [...state.messages, analyzingMessage]);

    try {
      final emotionalRecord =
          await ref.read(analyzeEmotionUseCaseProvider).execute(
                userId: _userId,
                text: textForAnalysis,
                emotion: emotion,
                onboarding: onboardingData ?? {},
              );

      // "입력 중..." 메시지 제거
      state = state.copyWith(
          messages: state.messages
              .where((m) => m.type != MessageType.analysis)
              .toList());

      final presetId = emotionalRecord.interventionPresetId;
      print("✅ Received presetId from backend: '$presetId'");

      // 2. 백엔드 응답에 따라 분기 처리
      switch (presetId) {
        case "FRIENDLY_REPLY":
          final botMessage = Message(
            userId: _userId,
            content: emotionalRecord.intervention['text'] as String,
            sender: Sender.bot,
          );
          await _addBotMessageToChat(botMessage);
          break;

        case "SOLUTION_PROPOSAL":
          // 2-1. 분석 결과 메시지 (친근한 문구) 먼저 전송
          if (emotionalRecord.analysisText != null) {
            final analysisMessage = Message(
                userId: _userId,
                content: emotionalRecord.analysisText!,
                sender: Sender.bot);
            await _addBotMessageToChat(analysisMessage);
            await Future.delayed(const Duration(milliseconds: 1200));
          }

          // 2-2. 솔루션 제안 메시지 (멘트+솔루션정보 합쳐진) 전송
          if (emotionalRecord.proposalText != null) {
            final proposalMessage = Message(
              userId: _userId,
              content: emotionalRecord.proposalText!,
              sender: Sender.bot,
              type: MessageType.solutionProposal,
              proposal: {
                "solution_id": emotionalRecord.intervention['solution_id'],
                "options": [
                  {"label": "좋아, 해볼게", "action": "accept_solution"},
                  {"label": "아니, 그냥 말할래", "action": "decline_solution_and_talk"}
                ]
              },
            );
            await _addBotMessageToChat(proposalMessage);
          }
          break;

        // 5-2. 안전 위기 모드
        case PresetIds.safetyCrisisModal:
        case PresetIds.safetyCrisisSelfHarm:
        case PresetIds.safetyCrisisAngerAnxiety:
        case PresetIds.safetyCheckIn:
          final cluster = emotionalRecord.intervention['cluster'] as String;
          final solutionId =
              emotionalRecord.intervention['solution_id'] as String;

          // 백엔드가 알려준 cluster 정보에 따라 적절한 위기 개입 멘트를 선택
          final safetyText = kSolutionProposalScripts[cluster]?.first ??
              "많이 힘드시군요. 지금 도움이 필요할 수 있어요.";

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

        default:
          final errorMessage = Message(
              userId: _userId,
              content: "죄송해요, 응답을 이해할 수 없었어요.",
              sender: Sender.bot);
          await _addBotMessageToChat(errorMessage);
      }

      // 5-3. 일반 분석 및 솔루션 제안 모드
      // 세션 ID 업데이트
      final newSessionId = emotionalRecord.sessionId;
      if (newSessionId != null && userMessage.id != null) {
        await ref.read(updateMessageSessionIdUseCaseProvider).execute(
              messageId: userMessage.id!,
              sessionId: newSessionId,
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

  Future<void> _addBotMessageToChat(Message botMessage) async {
    final savedBotMessage =
        await ref.read(sendMessageUseCaseProvider).execute(botMessage);
    state = state.copyWith(messages: [...state.messages, savedBotMessage]);
  }

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
      navigatorkey.currentContext?.go('/breathing/$solutionId');
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final chatViewModelProvider =
    NotifierProvider<ChatViewModel, ChatState>(() => ChatViewModel());
