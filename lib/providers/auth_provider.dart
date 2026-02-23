import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'task_provider.dart';
import 'journal_provider.dart';
import 'chat_provider.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // References to data providers so we can clear them on sign-out
  TaskProvider? _taskProvider;
  JournalProvider? _journalProvider;
  ChatProvider? _chatProvider;

  AuthProvider() {
    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      final previousUser = _user;
      _user = user;

      // If a different user signed in (or first sign-in), clear stale data
      if (user != null && previousUser?.uid != user.uid) {
        _clearAllData();
      }

      notifyListeners();
    });
  }

  /// Call this once after all providers are created, to wire up clear-on-signout
  void setDataProviders({
    required TaskProvider taskProvider,
    required JournalProvider journalProvider,
    required ChatProvider chatProvider,
  }) {
    _taskProvider = taskProvider;
    _journalProvider = journalProvider;
    _chatProvider = chatProvider;
  }

  void _clearAllData() {
    _taskProvider?.clear();
    _journalProvider?.clear();
    _chatProvider?.clear();
  }

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;
  String get userEmail => _user?.email ?? 'User';
  String get userInitial => _user?.email?.substring(0, 1).toUpperCase() ?? 'U';

  /// Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signUp(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signIn(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Sign out — also clears all in-memory user data
  Future<void> signOut() async {
    _clearAllData();
    await _authService.signOut();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get user-friendly error messages
  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
