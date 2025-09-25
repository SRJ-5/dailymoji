import 'package:dailymoji/domain/repositories/solution_repository.dart';

class ProposeSolutionUseCase {
  final SolutionRepository repository;

  ProposeSolutionUseCase(this.repository);

  Future<Map<String, dynamic>> execute({
    required String userId,
    required String sessionId,
    required String topCluster,
  }) {
    return repository.proposeSolution(
      userId: userId,
      sessionId: sessionId,
      topCluster: topCluster,
    );
  }
}
