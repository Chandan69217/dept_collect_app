import 'dart:typed_data';
import 'package:protect/protect.dart';
import 'package:flutter/foundation.dart';

class FileDecryptionService {
  static FileDecryptionService _instance = FileDecryptionService.internal();
  factory FileDecryptionService() => _instance;
  FileDecryptionService.internal();

  static void setMockInstance(FileDecryptionService mock) {
    _instance = mock;
  }

  Future<ProtectResponse> decrypt(Uint8List bytes, String password) async {
    return compute(_decryptIsolateTask, _DecryptIsolateParams(bytes, password));
  }
}

class _DecryptIsolateParams {
  final Uint8List bytes;
  final String password;
  _DecryptIsolateParams(this.bytes, this.password);
}

ProtectResponse _decryptIsolateTask(_DecryptIsolateParams params) {
  return Protect.decryptUint8List(params.bytes, params.password);
}
