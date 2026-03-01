import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static const _prefsKeyBiometricsEnabled = 'biometric_enabled';

  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<bool> getBiometricsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKeyBiometricsEnabled) ?? false;
    }

  Future<void> setBiometricsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyBiometricsEnabled, enabled);
  }

  Future<bool> authenticate({
    BuildContext? context,
    bool showErrors = false,
  }) async {
    try {
      final supported = await isDeviceSupported();
      final canUse = await canCheckBiometrics();
      if (!supported || !canUse) {
        if (showErrors && context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Dispozitivul nu are configurată nicio metodă biometrică. '
                'Adaugă amprentă sau Face ID în setările telefonului.',
              ),
            ),
          );
        }
        return false;
      }

      final result = await _auth.authenticate(
        localizedReason: 'Autentifică-te pentru a continua',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (!result && showErrors && context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Autentificarea biometrică a fost anulată sau a eșuat.',
            ),
          ),
        );
      }

      return result;
    } on PlatformException catch (_) {
      if (showErrors && context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Autentificarea biometrică nu este disponibilă sau nu este configurată.',
            ),
          ),
        );
      }
      return false;
    } catch (_) {
      if (showErrors && context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A apărut o eroare la autentificarea biometrică.'),
          ),
        );
      }
      return false;
    }
  }

  /// Încearcă să activeze biometria: pornește un flow de autentificare și, dacă
  /// reușește, salvează preferința ca activată.
  Future<bool> enableBiometricsWithCheck(BuildContext context) async {
    final success = await authenticate(context: context, showErrors: true);
    if (!success) {
      await setBiometricsEnabled(false);
      return false;
    }

    await setBiometricsEnabled(true);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Autentificarea biometrică a fost activată.'),
        ),
      );
    }
    return true;
  }
}

