import 'package:flutter/foundation.dart';
import '../models/mock_user.dart';

class AuthProvider extends ChangeNotifier {
  MockUser? _user;

  MockUser? get user => _user;
  bool get isLoggedIn => _user != null;

  void loginWithGoogle() {
    _user = MockUser(
      name: 'Peter',
      email: 'peter@gmail.com',
      avatarUrl: '',
    );
    notifyListeners();
  }

  void loginAsGuest() {
    _user = MockUser(
      name: 'Guest',
      email: '',
      avatarUrl: '',
    );
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}
