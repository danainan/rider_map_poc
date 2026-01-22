// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_permission_status.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppPermissionStatusAdapter extends TypeAdapter<AppPermissionStatus> {
  @override
  final int typeId = 0;

  @override
  AppPermissionStatus read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppPermissionStatus(
      permissions: (fields[1] as Map?)?.cast<String, bool>(),
    );
  }

  @override
  void write(BinaryWriter writer, AppPermissionStatus obj) {
    writer
      ..writeByte(1)
      ..writeByte(1)
      ..write(obj.permissions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppPermissionStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
