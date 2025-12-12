import 'package:thryfto/database/auth_screen.dart' as db_auth;

/// IAuthService: Abstraction for authentication operations.
///
/// SOLID notes:
/// - Single Responsibility: keeps auth logic isolated from UI widgets.
/// - Open/Closed: new implementations can be added without modifying callers.
/// - Liskov Substitution: any implementation of `IAuthService` can replace
///   another one without changing client code.
/// - Interface Segregation: only auth-related methods are exposed here.
/// - Dependency Inversion: UI depends on this abstraction, not on concrete
///   implementations or static helpers.
abstract class IAuthService {
  Future<Map<String, dynamic>> login(String email, String password);

  Future<Map<String, dynamic>> signUp({
    required String fullName,
    required String username,
    required String email,
    required String cityState,
    required String password,
    required String confirmPassword,
  });

  List<Map<String, String>> getAllUsers();
}

/// A simple, local/mock implementation of `IAuthService`.
///
/// This adapter delegates to the existing static `AuthService` in
/// `lib/database/auth_screen.dart`. In a real app you would provide a
/// production implementation here (e.g. Firebase, REST API) that also
/// implements `IAuthService`.
class MockAuthService implements IAuthService {
  const MockAuthService();

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    // Simulate network latency and return the existing static result.
    await Future.delayed(const Duration(milliseconds: 250));
    return db_auth.AuthService.login(email, password);
  }

  @override
  Future<Map<String, dynamic>> signUp({
    required String fullName,
    required String username,
    required String email,
    required String cityState,
    required String password,
    required String confirmPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return db_auth.AuthService.signUp(
      fullName: fullName,
      username: username,
      email: email,
      cityState: cityState,
      password: password,
      confirmPassword: confirmPassword,
    );
  }

  @override
  List<Map<String, String>> getAllUsers() => db_auth.AuthService.getAllUsers();
}
