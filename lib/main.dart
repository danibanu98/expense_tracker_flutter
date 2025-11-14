import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:expense_tracker_nou/theme/theme.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker_nou/providers/settings_provider.dart';

// 1. Importă pachetele pe care le-am instalat
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Fișierul generat de flutterfire

// Aici vom adăuga ecranele noastre (Login, Home etc.)
import 'package:expense_tracker_nou/ui/auth_page.dart';

void main() async {
  // 2. Asigură-te că uneltele Flutter sunt gata
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ro', null);

  // 3. Inițializează Firebase folosind fișierul de opțiuni
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 4. Pornește aplicația
  runApp(
    ChangeNotifierProvider(
      create: (context) => SettingsProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- AM MODIFICAT AICI ---
    // Ascultă schimbările din SettingsProvider
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'Expense Tracker',

          // Folosește tema selectată din provider
          themeMode: settings.themeMode,

          // Tema noastră întunecată (pe care am făcut-o)
          darkTheme: darkTheme,

          // TODO: Vom crea o temă luminoasă
          theme: lightTheme, // O temă luminoasă de bază

          home: AuthPage(),
        );
      },
    );
    // --- SFÂRȘIT MODIFICARE ---
  }
}
