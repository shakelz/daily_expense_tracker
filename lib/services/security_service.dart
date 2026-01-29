import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import 'preferences_service.dart';

class SecurityService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final PreferencesService _prefs = PreferencesService();

  /// Check if biometric authentication is available on the device
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Authenticate user with biometrics (fingerprint, face, etc.)
  /// Returns true if authentication is successful, false otherwise
  Future<bool> authenticateUser({bool forceAuthentication = false}) async {
    try {
      // Check if biometric lock is enabled
      final isBioEnabled = await _prefs.isBiometricEnabled();
      
      if (!isBioEnabled && !forceAuthentication) {
        print('Biometric lock is disabled');
        return true;
      }

      // Check if biometric authentication is available
      final bool isAvailable = await isBiometricAvailable();
      
      if (!isAvailable) {
        print('Biometric authentication not available on this device');
        // Allow access if biometric is not available
        return true;
      }

      // Get available biometrics
      final List<BiometricType> availableBiometrics = await getAvailableBiometrics();
      print('Available biometrics: $availableBiometrics');

      if (availableBiometrics.isEmpty) {
        print('No biometric types available');
        return true;
      }

      // Authenticate
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your expense tracker',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );

      if (didAuthenticate) {
        // Update last authentication time
        await _prefs.setLastAuthTime(DateTime.now());
        print('✓ Authentication successful');
        return true;
      } else {
        print('✗ Authentication cancelled by user');
        return false;
      }
    } on PlatformException catch (e) {
      print('PlatformException during authentication: ${e.code}');
      print('Error message: ${e.message}');
      
      // Handle specific error codes
      if (e.code == 'NotAvailable') {
        print('Biometric authentication not available');
        return true;
      } else if (e.code == 'NotEnrolled') {
        print('No biometrics enrolled on device');
        return true;
      } else if (e.code == 'LockedOut') {
        print('Too many failed attempts - locked out');
        return false;
      } else if (e.code == 'PermanentlyLockedOut') {
        print('Biometric authentication permanently locked');
        return false;
      } else if (e.code == 'UserCanceled') {
        print('User cancelled authentication');
        return false;
      } else if (e.code == 'NotInteractive') {
        print('Authentication dialog not interactive');
        return false;
      }
      
      // For other errors, allow access (graceful degradation)
      print('Unknown authentication error: ${e.code} - ${e.message}');
      return true;
    } catch (e) {
      print('Unexpected error during authentication: $e');
      // Allow access on unexpected errors
      return true;
    }
  }

  /// Stop authentication (cancel ongoing authentication)
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      print('Error stopping authentication: $e');
    }
  }
}
