import 'package:dailymoji/domain/entities/solution_context.dart';
import 'package:dailymoji/domain/repositories/solution_context_repository.dart';

class GetSolutionContextUseCase {
  GetSolutionContextUseCase(this._solutionContextRepository);
  final SolutionContextRepository _solutionContextRepository;

  Future<SolutionContext?> execute(String solutionId) async {
    final result = await _solutionContextRepository
        .getSolutionContext(solutionId);
    return result;
  }
}
