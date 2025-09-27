import 'package:dailymoji/data/data_sources/solutions_data_source.dart';
import 'package:dailymoji/domain/entities/solution_context.dart';
import 'package:dailymoji/domain/repositories/solution_context_repository.dart';

class SolutionContextRepositoryImpl
    implements SolutionContextRepository {
  SolutionContextRepositoryImpl(this._solutionsDataSource);
  final SolutionsDataSource _solutionsDataSource;

  @override
  Future<SolutionContext?> getSolutionContext(
      String solutionId) async {
    final result =
        await _solutionsDataSource.getSolutions(solutionId);
    if (result != null) {
      return result.toEntity();
    } else {
      return null;
    }
  }
}
