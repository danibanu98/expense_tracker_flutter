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

  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment(
        'SENTRY_DSN',
        defaultValue: '',
      );
      options.tracesSampleRate = 0.2;
    },
    appRunner: () {
      runApp(const _AppLoader());
    },
  );
}

/// Încarcă datele asincrone apoi afișează aplicația (necesar deoarece [appRunner] e sincron).
class _AppLoader extends StatefulWidget {
  const _AppLoader();

  @override
  State<_AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<_AppLoader> {
  Future<Widget> _load() async {
    await initializeDateFormatting('ro', null);
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    final settingsProvider = SettingsProvider();
    await settingsProvider.init();
    final prefs = await SharedPreferences.getInstance();
    final int lastTabIndex = prefs.getInt('lastTabIndex') ?? 0;
    return ChangeNotifierProvider.value(
      value: settingsProvider,
      child: MyApp(lastTabIndex: lastTabIndex),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return snapshot.data!;
        }
        return const MaterialApp(
          home: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }
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
          navigatorObservers: [SentryNavigatorObserver()],
          home: AuthPage(lastTabIndex: lastTabIndex),
        );
      },
    );
  }
}
