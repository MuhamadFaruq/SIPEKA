import '../entities/category_entity.dart';

abstract class CategoryRepository {
  Future<List<CategoryEntity>> getCategories();
  Future<void> saveCategories(List<CategoryEntity> categories);
}
