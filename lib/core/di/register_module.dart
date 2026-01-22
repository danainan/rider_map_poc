import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:injectable/injectable.dart';

import 'package:rider_map_poc/data/local/hive/hive_operation.dart';
import 'package:rider_map_poc/data/local/primitive/primitive_database.dart';
import 'package:rider_map_poc/data/local/secure/secure_storage_manager.dart';
import 'package:rider_map_poc/data/models/permission/app_permission_status.dart';

@module
abstract class RegisterModule {
  @singleton
  HiveInterface get hive => Hive;

  @lazySingleton
  Dio get dio => Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

  @LazySingleton(as: PrimitiveDatabase)
  SecureStorageManager get secureStorageManager => SecureStorageManager<String>(
        const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions:
              IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        ),
      );

  @lazySingleton
  HiveOperation<AppPermissionStatus> get appPermissionStatusHiveOperation =>
      HiveOperation<AppPermissionStatus>(hive, secureStorageManager);
}
