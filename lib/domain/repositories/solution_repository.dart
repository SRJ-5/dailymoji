import 'package:dailymoji/domain/entities/solution.dart';

abstract class SolutionRepository {
  Future<Map<String, dynamic>> proposeSolution({
    required String userId,
    required String sessionId,
    required String topCluster,
  });

  Future<Solution> fetchSolutionById(String solutionId);

  Future<String?> fetchSolutionTextById(String solutionId);
}
