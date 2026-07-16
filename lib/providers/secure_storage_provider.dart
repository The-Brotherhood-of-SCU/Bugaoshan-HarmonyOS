import 'package:bugaoshan/utils/platform_utils.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as standard;
import 'package:flutter_secure_storage_ohos/flutter_secure_storage_ohos.dart'
    as ohos;

abstract interface class SecureStorage {
  Future<String?> read({required String key});

  Future<void> write({required String key, required String? value});

  Future<void> delete({required String key});
}

/// 提供跨平台存储实例，统一管理登录凭据。
class SecureStorageProvider {
  const SecureStorageProvider._();

  static final SecureStorage _instance = AppPlatform.isHarmony
      ? const _OhosSecureStorageAdapter()
      : const _FlutterSecureStorageAdapter();

  static SecureStorage get instance => _instance;
}

class _FlutterSecureStorageAdapter implements SecureStorage {
  const _FlutterSecureStorageAdapter();

  static const _storage = standard.FlutterSecureStorage(
    iOptions: standard.IOSOptions(
      accessibility: standard.KeychainAccessibility.first_unlock_this_device,
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

class _OhosSecureStorageAdapter implements SecureStorage {
  const _OhosSecureStorageAdapter();

  static const _storage = ohos.FlutterSecureStorage();

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
