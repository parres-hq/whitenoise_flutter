import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Define the state class
class AuthState with ChangeNotifier {
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

  void login() {
    _isAuthenticated = true;
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }
}

// Define the provider
final authProvider = ChangeNotifierProvider<AuthState>((ref) {
  return AuthState();
});

// Note: In actual implementation, you should consider using a more modern approach
// with StateNotifier/StateNotifierProvider or AsyncNotifier/AsyncNotifierProvider
// and adapting the GoRouter to work with that instead of requiring a Listenable.
// 
// Example of modern approach (requires changes in router_provider.dart):
// 
// class AuthState {
//   final bool isAuthenticated;
//   AuthState({this.isAuthenticated = false});
// }
// 
// class AuthNotifier extends Notifier<AuthState> {
//   @override
//   AuthState build() => AuthState();
//   
//   void login() => state = AuthState(isAuthenticated: true);
//   void logout() => state = AuthState(isAuthenticated: false);
// }
// 
// final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() => AuthNotifier());