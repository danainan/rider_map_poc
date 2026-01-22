import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';

import 'package:hive_flutter/adapters.dart';
import 'package:injectable/injectable.dart';

import 'package:rider_map_poc/data/local/primitive/primitive_database.dart';
import 'package:rider_map_poc/data/local/primitive/primitive_keys.dart';

@lazySingleton
class HiveEncryption {
  HiveEncryption(this._hive, this._primitiveDatabase);

  final HiveInterface _hive;
  final PrimitiveDatabase _primitiveDatabase;

  @visibleForTesting
  Uint8List? encryptionKey;

  Future<Uint8List> getSecureKey() async {
    if (this.encryptionKey != null) {
      return this.encryptionKey!;
    }

    var encryptionKeyString = await _primitiveDatabase.read(
      PrimitiveKeys.secureStorageKey,
    );
    if (encryptionKeyString == null) {
      final key = _hive.generateSecureKey();
      await _primitiveDatabase.write(
        PrimitiveKeys.secureStorageKey,
        data: base64UrlEncode(key),
      );

      encryptionKeyString = await _primitiveDatabase.read(
        PrimitiveKeys.secureStorageKey,
      );
      if (encryptionKeyString == null) {
        throw Exception('Key is null');
      }
    }

    final encryptionKey = base64Url.decode(encryptionKeyString);
    this.encryptionKey = encryptionKey;
    return encryptionKey;
  }
}
