import 'package:dailymoji/domain/entities/solution.dart';

// SolutionRepository는 반드시 fetchSolutionById 라는 기능을 가져야 한다는 규칙을 정의
abstract class SolutionRepository {
  Future<Solution> fetchSolutionById(String solutionId);
}
