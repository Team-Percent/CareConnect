import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple patient account model (no blockchain/wallet).
class PatientAccount {
  final String name;
  final String id;

  const PatientAccount({required this.name, required this.id});
}

/// Credential database — simple local mock auth.
const _authDb = <String, _PatientCred>{
  'patient@care.x': _PatientCred(
    password: 'password123',
    account: PatientAccount(name: 'Nandakishore V', id: 'patient_1'),
  ),
  'aarav@care.x': _PatientCred(
    password: 'pass123',
    account: PatientAccount(name: 'Aarav Sharma', id: 'patient_2'),
  ),
  'priya@care.x': _PatientCred(
    password: 'pass123',
    account: PatientAccount(name: 'Priya Patel', id: 'patient_3'),
  ),
};

const _kUsernameKey = 'care_x_username';
const _kAccountNameKey = 'care_x_account_name';
const _kAccountIdKey = 'care_x_account_id';

class _PatientCred {
  final String password;
  final PatientAccount account;
  const _PatientCred({required this.password, required this.account});
}

/// Service that handles patient login, logout and session persistence.
@lazySingleton
class PatientAuthService {
  /// Tries to log in with [username] + [password].
  ///
  /// Returns the matching [PatientAccount] on success, or `null` on failure.
  Future<PatientAccount?> login(String username, String password) async {
    final cred = _authDb[username.trim().toLowerCase()];
    if (cred == null || cred.password != password.trim()) return null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccountNameKey, cred.account.name);
    await prefs.setString(_kAccountIdKey, cred.account.id);
    await prefs.setString(_kUsernameKey, username.trim().toLowerCase());
    return cred.account;
  }

  /// Returns the currently logged-in [PatientAccount], or `null`.
  Future<PatientAccount?> getCurrentAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_kAccountNameKey);
    final id = prefs.getString(_kAccountIdKey);
    if (name == null || id == null) return null;
    return PatientAccount(name: name, id: id);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_kAccountNameKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccountNameKey);
    await prefs.remove(_kAccountIdKey);
    await prefs.remove(_kUsernameKey);
  }

  /// Returns the full list of available patient accounts (for display).
  List<PatientAccount> get availableAccounts =>
      _authDb.values.map((c) => c.account).toList();
}
