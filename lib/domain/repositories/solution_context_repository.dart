import 'package:dailymoji/domain/entities/solution_context.dart';

abstract class SolutionContextRepository {
  Future<SolutionContext?> getSolutionContext(String solutionId);
}
