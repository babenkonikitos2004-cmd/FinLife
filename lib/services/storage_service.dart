import 'package:shared_preferences/shared_preferences.dart';
import 'package:finlife/models/user.dart';

class StorageService {
  static const String _userNameKey = 'user_name';
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _lastRecurringCheckKey = 'last_recurring_check';

  // Save user information to SharedPreferences
  Future<void> saveUser(String name) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  // Get saved user information or null if not found
  Future<User?> getUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    final String? name = prefs.getString(_userNameKey);
    
    if (name != null) {
      // Use a consistent user ID based on the username
      final String userId = 'user_$name';
      return User(
        id: userId,
        email: '$name@example.com',
        name: name,
        monthlyIncome: 0.0, // Default value, will be updated when user sets it
        createdAt: DateTime.now(),
      );
    }
    
    return null;
  }

  // Clear user information (logout)
  Future<void> clearUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userNameKey);
  }

  // Save onboarding completion status
  Future<void> saveOnboardingComplete() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);
  }

  // Check if onboarding is complete
  Future<bool> isOnboardingComplete() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  // Save last recurring check date
  Future<void> saveLastRecurringCheck(DateTime date) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastRecurringCheckKey, date.toIso8601String());
  }

  // Get last recurring check date
  Future<DateTime?> getLastRecurringCheck() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? dateString = prefs.getString(_lastRecurringCheckKey);
    if (dateString != null) {
      return DateTime.tryParse(dateString);
    }
    return null;
  }
}