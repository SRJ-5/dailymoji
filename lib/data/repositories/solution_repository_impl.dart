import 'package:dailymoji/domain/entities/solution.dart';
import 'package:dailymoji/domain/repositories/solution_repository.dart';
import 'package:dailymoji/data/data_sources/solution_remote_data_source.dart';

class SolutionRepositoryImpl implements SolutionRepository {
  final SolutionRemoteDataSource remoteDataSource;

  SolutionRepositoryImpl(this.remoteDataSource);

  @override
  Future<Map<String, dynamic>> proposeSolution({
    required String userId,
    required String sessionId,
    required String topCluster,
  }) {
    return remoteDataSource.proposeSolution(
      userId: userId,
      sessionId: sessionId,
      topCluster: topCluster,
    );
  }

  @override
  Future<Solution> fetchSolutionById(String solutionId) async {
    final data = await remoteDataSource.fetchSolutionById(solutionId);
    return Solution.fromJson(data);
  }

  @override
  Future<String?> fetchSolutionTextById(String solutionId) {
    return remoteDataSource.fetchSolutionTextById(solutionId);
  }
}
