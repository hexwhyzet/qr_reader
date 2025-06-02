import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorage {
  String tokenKey;

  SecureStorage(this.tokenKey);

  // static final _storage = FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(tokenKey);
  }
}

SecureStorage tokenStorage = SecureStorage('AUTH_TOKEN');
SecureStorage refreshStorage = SecureStorage('AUTH_REFRESH_TOKEN');
