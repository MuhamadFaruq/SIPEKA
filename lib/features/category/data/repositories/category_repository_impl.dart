import 'package:sipeka/core/utils/storage.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  @override
  Future<List<CategoryEntity>> getCategories() async {
    final list = await Storage.loadCategories();
    return list.map((json) => CategoryModel.fromJson(json)).toList();
  }

  @override
  Future<void> saveCategories(List<CategoryEntity> categories) async {
    final list = categories.map((c) => CategoryModel.fromEntity(c).toJson()).toList();
    await Storage.saveCategories(list);
  }
}
