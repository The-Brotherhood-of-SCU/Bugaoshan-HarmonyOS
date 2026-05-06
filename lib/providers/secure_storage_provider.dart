import 'package:flutter_secure_storage/flutter_secure_storage.dart'
    if (dart.library.ohos) 'package:flutter_secure_storage_ohos/flutter_secure_storage_ohos.dart';

abstract interface class SecureStorage {
  Future<String?> read({required String key});

  Future<void> write({required String key, required String? value});

  Future<void> delete({required String key});
}

/// 提供跨平台存储实例，统一管理登录凭据。
class SecureStorageProvider {
  const SecureStorageProvider._();

  static const SecureStorage _instance = _FlutterSecureStorageAdapter();

  static SecureStorage get instance => _instance;
}

class _FlutterSecureStorageAdapter implements SecureStorage {
  const _FlutterSecureStorageAdapter();

  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  @override
  Future<String?> read({required String key}) {
    return _storage.read(key: key);
  }

  @override
  Future<void> write({required String key, required String? value}) {
    return _storage.write(key: key, value: value);
  }

  @override
  Future<void> delete({required String key}) {
    return _storage.delete(key: key);
  }
}
