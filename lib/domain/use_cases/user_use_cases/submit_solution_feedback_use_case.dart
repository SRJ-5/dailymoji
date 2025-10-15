import 'package:dailymoji/domain/repositories/emotion_repository.dart';

// RIN: 솔루션 피드백 제출을 위한 UseCase
class SubmitSolutionFeedbackUseCase {
  final EmotionRepository repository;

  SubmitSolutionFeedbackUseCase(this.repository);

  Future<void> execute({
    required String userId,
    required String solutionId,
    String? sessionId,
    required String solutionType,
    required String feedback,
  }) {
    return repository.submitSolutionFeedback(
      userId: userId,
      solutionId: solutionId,
      sessionId: sessionId,
      solutionType: solutionType,
      feedback: feedback,
    );
  }
}
