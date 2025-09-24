// 0924 변경: 채팅방 상태 오류 및 분석 누락 해결 (EMOJI ONLY)
import 'package:dailymoji/core/constants/emoji_assets.dart';
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
  final bool isTyping;
  final String? errorMessage;
  final bool isLoading; // 로딩 상태 추가

  ChatState({
    this.messages = const [],
    this.isTyping = false,
    this.errorMessage,
    this.isLoading = true, // 초기값은 true
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
  // UserViewModel에서 실제 ID를 가져오고, 없으면 임시 ID 사용(개발용)
  String? get _userId {
    final realUserId = ref.read(userViewModelProvider).userProfile?.id;

    // 개발이 끝나면 아래 ?? 뒤 부분만 삭제하면 되도록
    return realUserId ?? "ffc9c57c-b744-4924-a3e7-65781ecf6ab3";
  }

  @override
  ChatState build() {
    // build 시점에서는 ID가 없을 수 있으므로, enterChatRoom에서 구독을 시작하도록 변경
    return ChatState();
  }

  // --- Rin: 채팅방 진입 로직 ---
  Future<void> enterChatRoom(String? emotionFromHome) async {
    final currentUserId = _userId; // Getter를 통해 현재 ID 가져오기
    if (currentUserId == null) {
      print("🚨 [ViewModel] ERROR: User ID is null. Cannot enter chat room.");
      state = state.copyWith(isLoading: false, errorMessage: "로그인 정보가 없습니다.");
      return;
    }
    _subscribeToMessages(currentUserId);

    // 1. 오늘 대화 기록 불러오기
    await _loadTodayMessages(currentUserId);

    // 2. 이전 메시지에 이어서 이모지 메시지 전송
    if (emotionFromHome != null) {
      await sendEmojiAsMessage(emotionFromHome);
    }
  }

  // --- Rin: 오늘 메시지만 불러오도록 변경 ---
  Future<void> _loadTodayMessages(String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      final msgs =
          await ref.read(loadMessagesUseCaseProvider).execute(userId: userId);
      state = state.copyWith(messages: msgs, isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  // ---------------------------------------------------------------------------
  // 메시지 로드 & 구독
  // ---------------------------------------------------------------------------
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
  // 사용자 메시지 전송
  // ---------------------------------------------------------------------------
  Future<void> sendEmojiAsMessage(String emotion) async {
    final currentUserId = _userId;
    if (currentUserId == null) return;

    final emojiMessage = Message(
      userId: currentUserId,
      sender: Sender.user,
      type: MessageType.image,
      imageAssetPath: kEmojiAssetMap[emotion],
      content: "",
    );

    final savedMessage = await _addUserMessageToChat(emojiMessage);
    // text 없음, icon만 전달
    await _analyzeAndRespond(
        userMessage: savedMessage, textForAnalysis: "", emotion: emotion);
  }

  Future<void> sendMessage(String content, String emotion) async {
    final currentUserId = _userId;
    if (currentUserId == null) return;

    final message = Message(
      userId: currentUserId,
      content: content,
      sender: Sender.user,
      type: MessageType.normal,
      createdAt: DateTime.now(),
    );

    final savedMessage = await _addUserMessageToChat(message);
    await _analyzeAndRespond(
      userMessage: savedMessage,
      textForAnalysis: message.content,
      emotion: emotion,
    );
  }

// 이모지 이미지가 채팅에 입력 지속되지 않는 문제 해결!
// --> DB에서 돌아온 정보로 기존 메시지를 '업데이트' 하도록 변경
  Future<Message> _addUserMessageToChat(Message message) async {
    // 1. UI에 즉시 메시지 추가
    print(
        "RIN: ✅ 1. Optimistic UI: Adding local message with tempId: ${message.tempId}, path: ${message.imageAssetPath}");
    state = state.copyWith(messages: [...state.messages, message]);

    try {
      // 2. DB에 메시지 저장
      final savedMessageFromDB =
          await ref.read(sendMessageUseCaseProvider).execute(message);
      print(
          "RIN: ✅ 2. DB Response: Got message back with DB id: ${savedMessageFromDB.id}");

      // 3. DB에서 받은 정보(id, createdAt)와 기존 정보(imageAssetPath)를 합침
      final completeMessage = savedMessageFromDB.copyWith(
        imageAssetPath: message.imageAssetPath,
        tempId: message.tempId,
      );
      print(
          "RIN: ✅ 3. Merged Message: Final object has DB id: ${completeMessage.id}, tempId: ${completeMessage.tempId}, path: ${completeMessage.imageAssetPath}");

// ⭐️⭐️⭐️⭐️⭐️ 이모지 이미지가 채팅말풍선에 안남아있던 오류!
//여기서 로컬&DB 매칭 로직이 더 안정적이었어야함!
      // 4. 상태 리스트에서 id가 null이었던 메시지를 완전한 메시지로 교체
      // createdAt으로 비교하는 대신, 방금 추가했던 'message' 객체 uuid를 찾아서 교체
      final updatedMessages = List<Message>.from(state.messages);
      // 임시 ID가 일치하는 메시지의 인덱스를 찾음
      final index =
          updatedMessages.indexWhere((m) => m.tempId == completeMessage.tempId);
      print("RIN: ✅ 4. Finding message to replace: Index found is $index");

      if (index != -1) {
        // 객체를 찾았다면
        updatedMessages[index] = completeMessage;
        print("RIN: ✅ 5. Replacement successful!");
      } else {
        print(
            "RIN: 🚨 5. ERROR: Could not find message with tempId ${completeMessage.tempId} to replace.");
      }

      state = state.copyWith(messages: updatedMessages);

      return completeMessage;
    } catch (e) {
      print("RIN: 🚨 ERROR in _addUserMessageToChat: $e");
      // 에러 발생 시, 낙관적으로 추가했던 메시지를 다시 제거
      state = state.copyWith(
          messages:
              state.messages.where((m) => m.tempId != message.tempId).toList());
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 백엔드 호출 & 응답 처리
  // ---------------------------------------------------------------------------
  Future<void> _analyzeAndRespond({
    required Message userMessage,
    required String textForAnalysis,
    required String emotion,
  }) async {
    final currentUserId = _userId;
    if (currentUserId == null) return;
    final userState = ref.read(userViewModelProvider);
    final onboardingData = userState.userProfile?.onboardingScores;
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
                onboarding: onboardingData ?? {},
              );

      // "입력 중..." 메시지 제거
      state = state.copyWith(
          messages: state.messages
              .where((m) => m.type != MessageType.analysis)
              .toList());

      final presetId = emotionalRecord.interventionPresetId;
      final sessionId = emotionalRecord.sessionId;
      // final topCluster = emotionalRecord.intervention['top_cluster'] as String? ?? emotionalRecord.topCluster;

      switch (presetId) {
        // Rin: 이모지에 대한 공감/질문 응답 처리하는 case
        case PresetIds.emojiReaction:
        case PresetIds.friendlyReply:
          final botMessage = Message(
            userId: currentUserId,
            content: emotionalRecord.intervention['text'] as String,
            sender: Sender.bot,
          );
          await _addBotMessageToChat(botMessage);
          break; // 여기서 대화 흐름이 한번 끝남

        case PresetIds.solutionProposal:
          final topCluster =
              emotionalRecord.intervention['top_cluster'] as String? ??
                  emotionalRecord.topCluster;

          // 1. [공감] 메시지 먼저 보내기
          if (emotionalRecord.empathyText != null) {
            final empathyMessage = Message(
              userId: currentUserId,
              content: emotionalRecord.empathyText!,
              sender: Sender.bot,
            );
            await _addBotMessageToChat(empathyMessage);
            await Future.delayed(const Duration(milliseconds: 1000)); // 잠시 딜레이
          }

          // 2. [분석 결과] 메시지 보내기
          if (emotionalRecord.analysisText != null) {
            final analysisMessage = Message(
                userId: currentUserId,
                content: emotionalRecord.analysisText!,
                sender: Sender.bot);
            await _addBotMessageToChat(analysisMessage);
            await Future.delayed(const Duration(milliseconds: 1200));
          }
          // 3. [솔루션 제안]을 위해 /solutions/propose 호출
          if (sessionId != null && topCluster != null) {
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
          }
          break;

        // 안전 위기 모드
        case PresetIds.safetyCrisisModal:
        case PresetIds.safetyCrisisSelfHarm:
        case PresetIds.safetyCrisisAngerAnxiety:
        case PresetIds.safetyCheckIn:
          final cluster = emotionalRecord.intervention['cluster'] as String;
          final solutionId =
              emotionalRecord.intervention['solution_id'] as String;

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

  // ---------------------------------------------------------------------------
  // 봇 메시지 유틸
  // ---------------------------------------------------------------------------
  Future<void> _addBotMessageToChat(Message botMessage) async {
    final savedBotMessage =
        await ref.read(sendMessageUseCaseProvider).execute(botMessage);
    state = state.copyWith(messages: [...state.messages, savedBotMessage]);
  }

  // ---------------------------------------------------------------------------
  // 솔루션 응답 버튼 처리
  // ---------------------------------------------------------------------------
  Future<void> respondToSolution(String solutionId, String action) async {
    if (action == "decline_solution_and_talk") {
      final currentUserId = _userId;
      if (currentUserId == null) return;
      final message = Message(
        userId: currentUserId,
        content: "저에게 털어놓으세요. 귀 기울여 듣고 있을게요.",
        sender: Sender.bot,
      );
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

// Provider
final chatViewModelProvider =
    NotifierProvider<ChatViewModel, ChatState>(() => ChatViewModel());
