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


// import 'package:hive_flutter/adapters.dart';
// import 'package:injectable/injectable.dart';
// import 'package:rider_map_poc/core/helper/file_operation.dart';
// import 'package:rider_map_poc/data/models/permission/app_permission_status.dart';


// @injectable
// class HiveManger {
//   HiveManger(
//     this._hive, {
//     @factoryParam FileOperationHelper? fileOperationHelper,
//   }) : _fileOperationHelper = fileOperationHelper ?? FileOperationHelper();

//   final HiveInterface _hive;
//   late final FileOperationHelper _fileOperationHelper;
//   String get _subDirectory => 'Rider_MAP_POC';

//   Future<void> init() async {
//     await _open();
//     registerAdapters();
//   }

//   Future<void> clear() async {
//     await _hive.deleteFromDisk();
//     await _fileOperationHelper.removeSubDirectory(_subDirectory);
//   }

//   Future<void> _open() async {
//     final subPath =
//         await _fileOperationHelper.createSubDirectory(_subDirectory);
//     await _hive.initFlutter(subPath);
//   }

//   void registerAdapters() {
//     _hive
//       .registerAdapter(AppPermissionStatusAdapter());
//   }
// }
