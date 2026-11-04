import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class SecurityService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final SharedPreferences _prefs;

  SecurityService(this._prefs);

  bool get isBiometricEnabled => _prefs.getBool(AppConstants.prefBiometricEnabled) ?? false;
  bool get isPinEnabled => _prefs.getBool(AppConstants.prefPinEnabled) ?? false;

  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateBiometric({String reason = 'Authenticate to access MyFinance'}) async {
    if (!isBiometricEnabled) return true;
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.prefBiometricEnabled, enabled);
  }

  Future<bool> verifyPin(String pin) async {
    final storedPin = await _secureStorage.read(key: AppConstants.prefPinCode);
    return storedPin == pin;
  }

  Future<void> setPin(String? pin) async {
    if (pin == null || pin.isEmpty) {
      await _secureStorage.delete(key: AppConstants.prefPinCode);
      await _prefs.setBool(AppConstants.prefPinEnabled, false);
    } else {
      await _secureStorage.write(key: AppConstants.prefPinCode, value: pin);
      await _prefs.setBool(AppConstants.prefPinEnabled, true);
    }
  }
}
