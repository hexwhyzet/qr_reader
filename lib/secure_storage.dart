import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  String tokenKey;

  SecureStorage(this.tokenKey);

  static final _storage = FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: tokenKey);
  }
}

SecureStorage tokenStorage = SecureStorage('AUTH_TOKEN');
SecureStorage refreshStorage = SecureStorage('AUTH_REFRESH_TOKEN');
