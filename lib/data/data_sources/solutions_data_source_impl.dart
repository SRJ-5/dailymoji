import 'package:dailymoji/data/data_sources/solutions_data_source.dart';
import 'package:dailymoji/data/dtos/solutions_dto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SolutionsDataSourceImpl implements SolutionsDataSource {
  final supabase = Supabase.instance.client;

  @override
  Future<SolutionsDto?> getSolutions(String solutionId) async {
    final result = await supabase
        .from('solutions')
        .select()
        .eq('solution_id', solutionId)
        .maybeSingle();
    if (result != null) {
      return SolutionsDto.fromJson(result);
    } else {
      return null;
    }
  }
}
