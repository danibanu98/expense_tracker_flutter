import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  late SharedPreferences _prefs; // Variabila pentru a ține minte setările

  // Valorile implicite
  ThemeMode _themeMode = ThemeMode.system;
  String _currency = 'USD';

  // Getters
  ThemeMode get themeMode => _themeMode;
  String get currency => _currency;

  // --- FUNCȚIE NOUĂ DE ÎNCĂRCARE ---
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // 1. Încarcă Tema
    final themeIndex = _prefs.getInt('themeMode') ?? 0; // 0 = system
    _themeMode = ThemeMode.values[themeIndex];

    // 2. Încarcă Moneda
    _currency = _prefs.getString('currency') ?? 'USD';

    // Nu apelăm notifyListeners() aici, se încarcă înainte de a porni UI-ul
  }

  // --- FUNCȚIE MODIFICATĂ: Acum salvează ---
  void updateTheme(ThemeMode newTheme) {
    _themeMode = newTheme;
    _prefs.setInt(
      'themeMode',
      newTheme.index,
    ); // Salvează indexul (0, 1, sau 2)
    notifyListeners();
  }

  // --- FUNCȚIE MODIFICATĂ: Acum salvează ---
  void updateCurrency(String newCurrency) {
    _currency = newCurrency;
    _prefs.setString('currency', newCurrency); // Salvează string-ul (ex: "RON")
    notifyListeners();
  }

  // Getter-ul pentru simbol (rămâne la fel)
  String get currencySymbol {
    switch (_currency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'RON':
        return 'RON ';
      case 'GBP':
        return '£';
      default:
        return '\$';
    }
  }
}
