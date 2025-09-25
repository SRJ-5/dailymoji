// domain/usecases/get_reaction_script_use_case.dart

import 'package:dailymoji/data/repositories/reaction_repository.dart';

class GetReactionScriptUseCase {
  final ReactionRepository _repository;
  GetReactionScriptUseCase(this._repository);

  Future<String> execute(String? emotion) {
    return _repository.getReactionScript(emotion);
  }
}
