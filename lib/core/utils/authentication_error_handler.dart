import 'package:supabase_flutter/supabase_flutter.dart';
import 'connectivity_checker.dart';

class AuthenticationErrorHandler {
  final ConnectivityChecker _connectivityChecker = ConnectivityChecker();

  Future<String> handleError(dynamic error) async {
    final connectivityStatus = await _connectivityChecker.getConnectivityStatus();
    if (connectivityStatus.isNotEmpty) {
      return connectivityStatus;
    }

    if (error is AuthException) {
      return _handleAuthException(error);
    }

    if (error is PostgrestException) {
      return _handlePostgrestException(error);
    }

    if (error.toString().contains('SocketException') ||
        error.toString().contains('Failed host lookup') ||
        error.toString().contains('Network is unreachable')) {
      return 'No internet connection. Please check your network settings.';
    }

    if (error.toString().contains('TimeoutException') ||
        error.toString().contains('timeout')) {
      return 'Request timed out. Please check your internet connection and try again.';
    }

    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('email') && errorString.contains('already')) {
      return 'This email is already registered. Please use a different email or sign in.';
    }

    if (errorString.contains('incorrect current password')) {
      return 'Incorrect current password. Please try again.';
    }

    if (errorString.contains('invalid') && errorString.contains('credentials')) {
      return 'Invalid email or password. Please check your credentials and try again.';
    }

    if (errorString.contains('password')) {
      return 'Password error. Please check your password and try again.';
    }

    if (errorString.contains('user not found')) {
      return 'No account found with this email. Please sign up first.';
    }

    return 'An error occurred. Please try again later.';
  }

  String _handleAuthException(AuthException error) {
    switch (error.statusCode) {
      case '400':
        if (error.message.toLowerCase().contains('email')) {
          return 'Invalid email address. Please check and try again.';
        }
        if (error.message.toLowerCase().contains('password')) {
          return 'Invalid password. Password must be at least 6 characters.';
        }
        return 'Invalid request. Please check your information and try again.';
      
      case '401':
        return 'Invalid email or password. Please check your credentials.';
      
      case '422':
        if (error.message.toLowerCase().contains('email')) {
          return 'This email is already registered. Please sign in instead.';
        }
        return 'Invalid information provided. Please check and try again.';
      
      case '429':
        return 'Too many requests. Please wait a moment and try again.';
      
      case '500':
      case '502':
      case '503':
        return 'Server error. Please try again later.';
      
      default:
        final message = error.message.toLowerCase();
        if (message.contains('email already registered') ||
            message.contains('user already registered')) {
          return 'This email is already registered. Please sign in instead.';
        }
        if (message.contains('invalid login credentials') ||
            message.contains('invalid credentials')) {
          return 'Invalid email or password. Please check your credentials.';
        }
        if (message.contains('password')) {
          return 'Password error. Please check your password.';
        }
        return error.message.isNotEmpty
            ? error.message
            : 'Authentication failed. Please try again.';
    }
  }

  String _handlePostgrestException(PostgrestException error) {
    if (error.code == '23505') {
      return 'This information is already in use. Please use different details.';
    }
    
    if (error.code == '23503') {
      return 'Invalid data. Please check your information.';
    }

    return 'Database error. Please try again later.';
  }
}
