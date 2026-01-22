import 'package:hive_flutter/adapters.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

import 'package:rider_map_poc/data/models/permission/app_permission_status.dart';

@injectable
class HiveManager {
  HiveManager(this._hive);

  final HiveInterface _hive;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    await _hive.initFlutter(dir.path);
    registerAdapters();
  }

  Future<void> clear() async {
    await _hive.deleteFromDisk();
  }

  void registerAdapters() {
    if (!_hive.isAdapterRegistered(AppPermissionStatusAdapter().typeId)) {
      _hive.registerAdapter(AppPermissionStatusAdapter());
    }
  }
}
