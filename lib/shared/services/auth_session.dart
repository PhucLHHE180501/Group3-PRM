import 'package:flutter/foundation.dart';

import '../models/user_model.dart';

class AuthSession extends ChangeNotifier {
  static final AuthSession _instance = AuthSession._internal();
  factory AuthSession() => _instance;
  AuthSession._internal();

  UserModel? currentUser;

  void setUser(UserModel? user) {
    currentUser = user;
    notifyListeners();
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }
}
