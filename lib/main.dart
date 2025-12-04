import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
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

  // --- INIȚIALIZARE SENTRY ---
  await SentryFlutter.init(
    (options) {
      // TODO: Înlocuiește cu DSN-ul tău real de pe sentry.io
      options.dsn =
          'https://11a6da941da1bb28885a313862d4e467@o4510359931715584.ingest.de.sentry.io/4510404959928400';

      // Setează la 1.0 pentru a captura 100% din tranzacții pentru testare.
      // În producție, poți reduce numărul (ex: 0.1).
      options.tracesSampleRate = 1.0;
      options.debug = false;
    },
    // Funcția care pornește efectiv aplicația
    appRunner: () => runApp(
      ChangeNotifierProvider.value(
        value: settingsProvider,
        child: MyApp(lastTabIndex: lastTabIndex),
      ),
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
          // Adăugăm observatorul Sentry pentru a urmări navigarea
          navigatorObservers: [SentryNavigatorObserver()],
          home: AuthPage(lastTabIndex: lastTabIndex),
        );
      },
    );
  }
}
