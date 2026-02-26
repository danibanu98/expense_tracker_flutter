import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'dart:async';

import 'firebase_options.dart';
import 'package:expense_tracker_nou/providers/settings_provider.dart';
import 'package:expense_tracker_nou/theme/theme.dart';
import 'package:expense_tracker_nou/ui/auth_page.dart';
import 'package:expense_tracker_nou/services/brand_service.dart';

Future<void> main() async {
  await SentryFlutter.init((options) {
    options.dsn =
        'https://11a6da941da1bb28885a313862d4e467@o4510359931715584.ingest.de.sentry.io/4510404959928400';
    // Setează tracesSampleRate pentru a monitoriza performanța (ex: 10% din sesiuni)
    options.tracesSampleRate = 0.1;
  }, appRunner: () => runApp(_AppLoader()));
}

/// Încarcă datele asincrone apoi afișează aplicația (necesar deoarece [appRunner] e sincron).
class _AppLoader extends StatefulWidget {
  const _AppLoader();

  @override
  State<_AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<_AppLoader> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Apelăm funcția care bagă TOATE imaginile în cache (și branduri, și fundal)
    _precacheAllImages();
  }

  // --- FUNCȚIA UNIFICATĂ DE CACHE ---
  void _precacheAllImages() {
    try {
      // 1. Încărcăm Brandurile (din BrandService)
      final brands = BrandService.knownBrands;
      for (var brand in brands) {
        final path = BrandService.getAssetPathForBrand(brand);
        if (path != null) {
          precacheImage(AssetImage(path), context);
        }
      }

      // 2. Încărcăm imaginile Statice de UI (Fundalul, etc.)
      final List<String> staticUiImages = [
        'assets/images/fundal.png', // <--- Aici este fundalul tău verde
        // Dacă mai ai alte imagini (ex: logo), adaugă-le aici:
        // 'assets/images/logo.png',
      ];

      for (var imagePath in staticUiImages) {
        precacheImage(AssetImage(imagePath), context);
      }
    } catch (e) {
      debugPrint('Eroare la precache imagini: $e');
    }
  }

  Future<Widget> _load() async {
    await initializeDateFormatting('ro', null);
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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
          home: Scaffold(body: Center(child: CircularProgressIndicator())),
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
