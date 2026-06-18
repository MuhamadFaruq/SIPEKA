import 'package:sipeka/core/services/sync_service.dart';
import '../models/wishlist_model.dart';

abstract class WishlistRemoteDataSource {
  Future<List<WishlistModel>> getWishlistFromCloud();
  Future<void> syncWishlistToCloud(List<WishlistModel> items);
}

class WishlistRemoteDataSourceImpl implements WishlistRemoteDataSource {
  final SyncService syncService;

  WishlistRemoteDataSourceImpl(this.syncService);

  @override
  Future<List<WishlistModel>> getWishlistFromCloud() async {
    return [];
  }

  @override
  Future<void> syncWishlistToCloud(List<WishlistModel> items) async {
  }
}
