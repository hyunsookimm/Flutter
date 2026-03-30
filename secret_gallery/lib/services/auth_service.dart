import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _appPasswordKey = 'app_password';

  Future<bool> hasAppPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_appPasswordKey);
  }

  Future<bool> checkAppPassword(String input) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_appPasswordKey);
    return saved == input;
  }

  Future<void> setAppPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appPasswordKey, password);
  }

  /// 비밀 앨범 비밀번호 확인
  bool checkAlbumPassword(String? saved, String input) {
    return saved != null && saved == input;
  }
}
