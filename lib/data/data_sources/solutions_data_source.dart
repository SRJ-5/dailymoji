import 'package:dailymoji/data/dtos/solutions_dto.dart';

abstract class SolutionsDataSource {
  Future<SolutionsDto?> getSolutions(String solutionId);
}
