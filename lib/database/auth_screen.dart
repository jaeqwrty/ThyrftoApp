class AuthService {
  // Dummy user database
  static final List<Map<String, String>> _users = [
    {
      'fullName': 'nemuel dog',
      'username': 'dog',
      'email': 'dog@test.com',
      'cityState': 'New York, NY',
      'password': 'password123',
    },
    {
      'fullName': 'nemuel cat',
      'username': 'cat',
      'email': 'cat@test.com',
      'cityState': 'Los Angeles, CA',
      'password': 'password456',
    },
  ];

  // Login function
  static Map<String, dynamic> login(String email, String password) {
    if (email.isEmpty || password.isEmpty) {
      return {'success': false, 'message': 'Please fill in all fields'};
    }

    // Check if user exists
    final user = _users.firstWhere(
      (u) => u['email'] == email && u['password'] == password,
      orElse: () => {},
    );

    if (user.isEmpty) {
      return {'success': false, 'message': 'Invalid email or password'};
    }

    return {'success': true, 'message': 'Login successful!', 'user': user};
  }

  // Sign up function
  static Map<String, dynamic> signUp({
    required String fullName,
    required String username,
    required String email,
    required String cityState,
    required String password,
    required String confirmPassword,
  }) {
    // Validation
    if (fullName.isEmpty ||
        username.isEmpty ||
        email.isEmpty ||
        cityState.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      return {'success': false, 'message': 'Please fill in all fields'};
    }

    if (password != confirmPassword) {
      return {'success': false, 'message': 'Passwords do not match'};
    }

    if (password.length < 6) {
      return {
        'success': false,
        'message': 'Password must be at least 6 characters',
      };
    }

    // Check if email already exists
    final emailExists = _users.any((u) => u['email'] == email);
    if (emailExists) {
      return {'success': false, 'message': 'Email already registered'};
    }

    // Check if username already exists
    final usernameExists = _users.any((u) => u['username'] == username);
    if (usernameExists) {
      return {'success': false, 'message': 'Username already taken'};
    }

    // Add new user
    _users.add({
      'fullName': fullName,
      'username': username,
      'email': email,
      'cityState': cityState,
      'password': password,
    });

    return {
      'success': true,
      'message': 'Account created successfully!',
      'user': _users.last,
    };
  }

  // Get all users (for testing)
  static List<Map<String, String>> getAllUsers() => _users;
}
