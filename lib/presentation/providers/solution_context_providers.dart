import 'package:dailymoji/data/data_sources/solutions_data_source.dart';
import 'package:dailymoji/data/data_sources/solutions_data_source_impl.dart';
import 'package:dailymoji/data/repositories/solution_context_repository_impl.dart';
import 'package:dailymoji/domain/repositories/solution_context_repository.dart';
import 'package:dailymoji/domain/use_cases/get_solution_context_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _solutionsDataSourceProvider =
    Provider<SolutionsDataSource>(
  (ref) {
    return SolutionsDataSourceImpl();
  },
);

final _solutionContextRepositoryProvider =
    Provider<SolutionContextRepository>(
  (ref) {
    return SolutionContextRepositoryImpl(
        ref.read(_solutionsDataSourceProvider));
  },
);

final getSolutionContextUseCaseProvider = Provider(
  (ref) {
    return GetSolutionContextUseCase(
        ref.read(_solutionContextRepositoryProvider));
  },
);
