import 'package:flutter/foundation.dart';

import '../data.dart';
import 'api_client.dart';
import 'auth_storage.dart';
import 'repositories.dart';

/// App-wide auth state. Listen to it via Provider to react to sign-in/out.
class AuthState extends ChangeNotifier {
  AuthState() {
    // If the API client detects a forced logout (refresh failed) it calls back.
    ApiClient.instance.onSessionExpired = () {
      _currentUser = null;
      _bootstrapped = true;
      notifyListeners();
    };
  }

  User? _currentUser;
  bool _bootstrapped = false;

  User? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;
  bool get bootstrapped => _bootstrapped;

  /// On app launch: if a token is on disk, try to fetch /me. If that fails,
  /// drop the user back on the splash screen.
  Future<void> bootstrap() async {
    final access = await AuthStorage.instance.readAccess();
    if (access == null) {
      _bootstrapped = true;
      notifyListeners();
      return;
    }
    try {
      _currentUser = await UsersRepository.instance.me();
    } catch (_) {
      _currentUser = null;
      await AuthStorage.instance.clear();
    }
    _bootstrapped = true;
    notifyListeners();
  }

  Future<void> signin({required String identifier, required String password}) async {
    _currentUser = await AuthRepository.instance.login(
      identifier: identifier, password: password,
    );
    notifyListeners();
  }

  Future<void> signup({
    required String name,
    required String username,
    required String contact,
    required String password,
    required String state,
    required bool agree,
  }) async {
    _currentUser = await AuthRepository.instance.signup(
      name: name, username: username, contact: contact,
      password: password, state: state, agree: agree,
    );
    notifyListeners();
  }

  Future<void> signout() async {
    await AuthRepository.instance.logout();
    _currentUser = null;
    notifyListeners();
  }

  /// Re-fetch /me — useful after a profile edit.
  Future<void> refresh() async {
    if (_currentUser == null) return;
    try {
      _currentUser = await UsersRepository.instance.me();
      notifyListeners();
    } catch (_) {}
  }
}
