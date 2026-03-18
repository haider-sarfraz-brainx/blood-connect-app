import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';

class ConnectivityChecker {
  final Connectivity _connectivity = Connectivity();

  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      }

      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 3));
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } catch (e) {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> hasWeakConnection() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      
      if (connectivityResult.contains(ConnectivityResult.mobile)) {
        final stopwatch = Stopwatch()..start();
        try {
          await InternetAddress.lookup('google.com')
              .timeout(const Duration(seconds: 5));
          stopwatch.stop();
          return stopwatch.elapsedMilliseconds > 2000;
        } catch (e) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<String> getConnectivityStatus() async {
    final hasConnection = await hasInternetConnection();
    if (!hasConnection) {
      return 'No internet connection. Please check your network settings.';
    }
    
    final isWeak = await hasWeakConnection();
    if (isWeak) {
      return 'Weak internet connection. Please try again.';
    }
    
    return '';
  }
}
