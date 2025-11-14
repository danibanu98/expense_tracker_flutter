import 'package:flutter/material.dart';

class SettingsProvider with ChangeNotifier {
  // 1. Valorile implicite
  ThemeMode _themeMode = ThemeMode.system;
  String _currency = 'USD';

  // 2. Getters (cum citește restul aplicației valorile)
  ThemeMode get themeMode => _themeMode;
  String get currency => _currency;

  // Un getter "helper" care returnează simbolul corect
  String get currencySymbol {
    switch (_currency) {
      case 'USD':
        return '\$'; // Dolar
      case 'EUR':
        return '€'; // Euro
      case 'RON':
        return 'RON '; // Leu (cu spațiu)
      case 'GBP':
        return '£'; // Liră
      default:
        return '\$'; // Implicit
    }
  }

  // 3. Setters (cum schimbăm valorile și anunțăm aplicația)
  void updateTheme(ThemeMode newTheme) {
    _themeMode = newTheme;
    notifyListeners(); // Anunță toate widget-urile care ascultă că s-a schimbat tema
  }

  void updateCurrency(String newCurrency) {
    _currency = newCurrency;
    notifyListeners(); // Anunță toate widget-urile care ascultă că s-a schimbat moneda
  }
}
