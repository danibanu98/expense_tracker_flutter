import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import nou

import 'firebase_options.dart';
import 'package:expense_tracker_nou/providers/settings_provider.dart'; // Import nou
import 'package:expense_tracker_nou/theme/theme.dart';
import 'package:expense_tracker_nou/ui/auth_page.dart';

// --- FUNCȚIA MAIN MODIFICATĂ ---
void main() async {
  // 1. Asigură inițializarea
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ro', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. Încarcă setările și ultima filă ÎNAINTE de a porni
  final settingsProvider = SettingsProvider();
  await settingsProvider.init(); // Încarcă tema și moneda

  final prefs = await SharedPreferences.getInstance();
  final int lastTabIndex = prefs.getInt('lastTabIndex') ?? 0; // 0 = Acasă

  // 3. Pornește aplicația și "injectează" setările
  runApp(
    ChangeNotifierProvider.value(
      value: settingsProvider, // Trimitem provider-ul deja inițializat
      child: MyApp(lastTabIndex: lastTabIndex), // Trimitem ultima filă
    ),
  );
}

// --- CLASA MyApp MODIFICATĂ ---
class MyApp extends StatelessWidget {
  // Acceptă ultima filă ca parametru
  final int lastTabIndex;
  const MyApp({super.key, required this.lastTabIndex});

  @override
  Widget build(BuildContext context) {
    // Ascultă provider-ul pentru temă
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'Expense Tracker',
          themeMode: settings.themeMode, // Tema dinamică
          theme: lightTheme, // Tema noastră luminoasă
          darkTheme: darkTheme, // Tema noastră întunecată
          // Trimite 'lastTabIndex' mai departe către AuthPage
          home: AuthPage(lastTabIndex: lastTabIndex),
        );
      },
    );
  }
}
