import 'package:equatable/equatable.dart';
import 'package:hive_flutter/adapters.dart';

import 'package:rider_map_poc/core/constants/hive_constants.dart';

part 'app_permission_status.g.dart';

@HiveType(typeId: HiveConstants.appPermissionStatusHiveType)
class AppPermissionStatus extends Equatable {
  const AppPermissionStatus({
    required this.permissions,
  });

  factory AppPermissionStatus.fromJson(Map<String, dynamic> json) {
    return AppPermissionStatus(
      permissions: Map<String, bool>.from(json['permissions']),
    );
  }

  @HiveField(1)
  final Map<String, bool>? permissions;

  AppPermissionStatus copyWith({Map<String, bool>? permissions}) {
    return AppPermissionStatus(
      permissions: permissions ?? this.permissions,
    );
  }

  Map<String, dynamic> toJson() {
    return {'permissions': permissions};
  }

  @override
  List<Object?> get props => [permissions];
}
