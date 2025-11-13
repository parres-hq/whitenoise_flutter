import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/states/auth_state.dart';

class MockAuthNotifier extends AuthNotifier {
  final bool isAuthenticated;

  MockAuthNotifier({required this.isAuthenticated});

  @override
  AuthState build() {
    return AuthState(isAuthenticated: isAuthenticated);
  }
}
