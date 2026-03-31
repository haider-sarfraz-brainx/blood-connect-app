import '../../../data/models/user_model.dart';
import 'local_storage.dart';

class SessionManager {
  final LocalStorageManager _storage;
  static const String _userKey = 'user_session';
  static const String _isLoggedInKey = 'is_logged_in';

  SessionManager(this._storage);

  Future<void> saveUser(UserModel user) async {
    await _storage.setString(key: _userKey, value: user.toJson());
    await _storage.setBool(key: _isLoggedInKey, value: true);
  }

  UserModel? get user => getUser();

  UserModel? getUser() {
    final userJson = _storage.getString(key: _userKey);
    if (userJson != null) {
      try {
        return UserModel.fromJson(userJson);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  bool isLoggedIn() {
    return _storage.getBool(key: _isLoggedInKey) ?? false;
  }

  Future<void> clearSession() async {
    await _storage.setString(key: _userKey, value: '');
    await _storage.setBool(key: _isLoggedInKey, value: false);
  }
}
