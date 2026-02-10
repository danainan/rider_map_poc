// import 'package:injectable/injectable.dart';
// import 'package:permission_handler/permission_handler.dart';

// import 'package:rider_map_poc/data/local/hive/hive_operation.dart';
// import 'package:rider_map_poc/data/models/permission/app_permission_status.dart';
// import 'package:rider_map_poc/data/models/permission/permission_request_status.dart';
// import 'package:rider_map_poc/data/services/permission_status/app_permission_status_service.dart';

// const _permissionStatusKey = '__permission_status__';

// enum PermissionType {
//   location,
// }

// @Injectable(as: AppPermissionStatusService)
// class AppPermissionStatusServiceImpl implements AppPermissionStatusService {
//   AppPermissionStatusServiceImpl(this._hiveOperation);

//   final HiveOperation<AppPermissionStatus> _hiveOperation;

//   Permission _mapPermissionType(PermissionType type) {
//     switch (type) {
//       case PermissionType.location:
//         return Permission.location;
//     }
//   }

//   Future<AppPermissionStatus?> _getAllPermissionFirstTimeRequested() async {
//     return await _hiveOperation.getItem(_permissionStatusKey);
//   }

//   Future<bool> _getPermissionFirstTimeRequested(
//     PermissionType permissionType,
//   ) async {
//     final permissionData = await _getAllPermissionFirstTimeRequested();

//     return permissionData?.permissions?.containsKey(permissionType.name) ??
//         false;
//   }

//   Future<void> _savePermissionFirstTimeRequested(
//     PermissionType permissionType,
//     bool isDeniedBefore,
//   ) async {
//     final currentData = await _getAllPermissionFirstTimeRequested() ??
//         const AppPermissionStatus(permissions: {});

//     final updatedData = currentData.copyWith(
//       permissions: {
//         ...currentData.permissions ?? {},
//         permissionType.name: isDeniedBefore,
//       },
//     );

//     await _hiveOperation.insertOrUpdateItem(_permissionStatusKey, updatedData);
//   }

//   Future<PermissionRequestStatus> _requestGeneralPermission(
//     PermissionType permissionType,
//   ) async {
//     final permission = _mapPermissionType(permissionType);

//     final status = await permission.status;
//     if (status == PermissionStatus.granted) {
//       return PermissionRequestStatus.granted;
//     } else {
//       // check has denied before
//       final firstTimeRequested =
//           await _getPermissionFirstTimeRequested(permissionType);
//       if (firstTimeRequested) {
//         return PermissionRequestStatus.hasDeniedBefore;
//       }

//       // request new
//       final newStatus = await permission.request();
//       switch (newStatus) {
//         case PermissionStatus.granted:
//           await _savePermissionFirstTimeRequested(permissionType, true);
//           return PermissionRequestStatus.granted;

//         case PermissionStatus.denied:
//           await _savePermissionFirstTimeRequested(permissionType, false);

//         case PermissionStatus.permanentlyDenied:
//           await _savePermissionFirstTimeRequested(permissionType, false);

//         case PermissionStatus.limited:
//           await _savePermissionFirstTimeRequested(permissionType, true);
//           return PermissionRequestStatus.granted;
//         default:
//           return PermissionRequestStatus.denied;
//       }
//       return PermissionRequestStatus.denied;
//     }
//   }

//   @override
//   Future<PermissionRequestStatus> requestLocationPermission() async {
//     return _requestGeneralPermission(PermissionType.location);
//   }
// }


import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:rider_map_poc/data/local/hive/hive_operation.dart';
import 'package:rider_map_poc/data/models/permission/app_permission_status.dart';
import 'package:rider_map_poc/data/models/permission/permission_request_status.dart';
import 'package:rider_map_poc/data/services/permission_status/app_permission_status_service.dart';

const _permissionStatusKey = '__permission_status__';

enum PermissionType {
  location,
}

@Injectable(as: AppPermissionStatusService)
class AppPermissionStatusServiceImpl implements AppPermissionStatusService {
  AppPermissionStatusServiceImpl(this._hiveOperation);

  final HiveOperation<AppPermissionStatus> _hiveOperation;

  Permission _mapPermissionType(PermissionType type) {
    switch (type) {
      case PermissionType.location:
        return Permission.location;
    }
  }

  Future<AppPermissionStatus?> _getAllPermissionFirstTimeRequested() async {
    return await _hiveOperation.getItem(_permissionStatusKey);
  }

  Future<bool> _getHasDeniedBefore(PermissionType permissionType) async {
    final permissionData = await _getAllPermissionFirstTimeRequested();
    return permissionData?.permissions?[permissionType.name] ?? false;
  }

  Future<void> _savePermissionStatus(
    PermissionType permissionType,
    bool hasDenied,
  ) async {
    final currentData = await _getAllPermissionFirstTimeRequested() ??
        const AppPermissionStatus(permissions: {});

    final updatedData = currentData.copyWith(
      permissions: {
        ...currentData.permissions ?? {},
        permissionType.name: hasDenied,
      },
    );

    await _hiveOperation.insertOrUpdateItem(_permissionStatusKey, updatedData);
  }

  Future<PermissionRequestStatus> _requestGeneralPermission(
    PermissionType permissionType,
  ) async {
    final permission = _mapPermissionType(permissionType);

    // 1. เช็ค status ปัจจุบัน
    final status = await permission.status;

    // ถ้า granted แล้ว → จบ
    if (status == PermissionStatus.granted ||
        status == PermissionStatus.limited) {
      return PermissionRequestStatus.granted;
    }

    // ถ้า permanentlyDenied → ต้องไปเปิดใน settings
    // (Android: "Don't ask again" / iOS: denied ครั้งที่สอง)
    if (status == PermissionStatus.permanentlyDenied) {
      await _savePermissionStatus(permissionType, true);
      return PermissionRequestStatus.hasDeniedBefore;
    }

    // 2. เช็คว่าเคย denied มาก่อนหรือยัง (จาก Hive)
    final hasDeniedBefore = await _getHasDeniedBefore(permissionType);
    if (hasDeniedBefore) {
      // เคย denied แล้ว → ไม่ request ซ้ำ (OS อาจไม่แสดง dialog)
      return PermissionRequestStatus.hasDeniedBefore;
    }

    // 3. Request permission ครั้งแรก
    final newStatus = await permission.request();

    switch (newStatus) {
      case PermissionStatus.granted:
      case PermissionStatus.limited:
        return PermissionRequestStatus.granted;

      case PermissionStatus.permanentlyDenied:
        await _savePermissionStatus(permissionType, true);
        return PermissionRequestStatus.hasDeniedBefore;

      case PermissionStatus.denied:
      default:
        await _savePermissionStatus(permissionType, true);
        return PermissionRequestStatus.denied;
    }
  }

  @override
  Future<PermissionRequestStatus> requestLocationPermission() async {
    return _requestGeneralPermission(PermissionType.location);
  }
}