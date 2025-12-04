import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:sentry_flutter/sentry_flutter.dart'; // <--- AM COMENTAT SENTRY

import 'firebase_options.dart';
import 'package:expense_tracker_nou/providers/settings_provider.dart';
import 'package:expense_tracker_nou/theme/theme.dart';
import 'package:expense_tracker_nou/ui/auth_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ro', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Încarcă setările
  final settingsProvider = SettingsProvider();
  await settingsProvider.init();

  final prefs = await SharedPreferences.getInstance();
  final int lastTabIndex = prefs.getInt('lastTabIndex') ?? 0;

  // --- PORNIRE SIMPLĂ (FĂRĂ SENTRY) ---
  // Asta va face aplicația să pornească instantaneu în Debug
  runApp(
    ChangeNotifierProvider.value(
      value: settingsProvider,
      child: MyApp(lastTabIndex: lastTabIndex),
    ),
  );
}

class MyApp extends StatelessWidget {
  final int lastTabIndex;
  const MyApp({super.key, required this.lastTabIndex});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'Expense Tracker',
          themeMode: settings.themeMode,
          theme: lightTheme,
          darkTheme: darkTheme,
          // navigatorObservers: [SentryNavigatorObserver()], // <--- AM COMENTAT ȘI AICI
          home: AuthPage(lastTabIndex: lastTabIndex),
        );
      },
    );
  }
}
