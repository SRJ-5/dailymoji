import 'package:dailymoji/domain/entities/solution_context.dart';
import 'package:dailymoji/presentation/providers/solution_context_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SolutionContextViewModel
    extends Notifier<SolutionContext> {
  @override
  build() {
    return SolutionContext();
  }

  Future<String> getSolutionContext(String solutionId) async {
    print('솔루션 : $solutionId');
    final result = await ref
        .read(getSolutionContextUseCaseProvider)
        .execute(solutionId);
    state = state.copyWith(context: result!.context);
    print('컨텍스 : ${result.context}');
    return result.context!;
  }
}

final solutionContextViewModelProvider =
    NotifierProvider<SolutionContextViewModel, SolutionContext>(
  () {
    return SolutionContextViewModel();
  },
);
