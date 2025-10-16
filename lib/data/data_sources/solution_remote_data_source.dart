abstract class SolutionRemoteDataSource {
  Future<Map<String, dynamic>> proposeSolution({
    required String userId,
    required String sessionId,
    required String topCluster,
  });

  Future<Map<String, dynamic>> fetchSolutionById(String solutionId);
  Future<String?> fetchSolutionTextById(String solutionId);
}
