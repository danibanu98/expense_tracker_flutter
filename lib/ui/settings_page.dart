import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker_nou/providers/settings_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final List<String> _currencies = [
    'USD',
    'EUR',
    'RON',
    'GBP',
  ]; // Monedele noastre

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Setări')),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          // --- Secțiunea 1: Setări Temă ---
          Text(
            'Temă (Aspect)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: 10),
          DropdownButtonFormField<ThemeMode>(
            initialValue: settings.themeMode,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.brightness_6),
            ),
            items: [
              DropdownMenuItem(
                value: ThemeMode.system,
                child: Text('Sistem (Automat)'),
              ),
              DropdownMenuItem(
                value: ThemeMode.light,
                child: Text('Luminos (Light)'),
              ),
              DropdownMenuItem(
                value: ThemeMode.dark,
                child: Text('Întunecat (Dark)'),
              ),
            ],
            onChanged: (value) {
              // --- MODIFICAT ---
              if (value != null) {
                // Trimite noua temă către provider
                Provider.of<SettingsProvider>(
                  context,
                  listen: false,
                ).updateTheme(value);
              }
              // --- SFÂRȘIT ---
            },
          ),
          SizedBox(height: 30),

          // --- Secțiunea 2: Setări Monedă ---
          Text(
            'Monedă Principală',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: 10),

          DropdownButtonFormField<String>(
            initialValue: settings.currency,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.currency_exchange),
            ),
            items: _currencies.map((currency) {
              return DropdownMenuItem(value: currency, child: Text(currency));
            }).toList(),
            onChanged: (value) {
              // --- MODIFICAT ---
              if (value != null) {
                // Trimite noua monedă către provider
                Provider.of<SettingsProvider>(
                  context,
                  listen: false,
                ).updateCurrency(value);
              }
              // --- SFÂRȘIT ---
            },
          ),
          SizedBox(height: 30),

          // --- Secțiunea 3: Test Sentry ---
          Text(
            'Monitorizare & Diagnostică',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: 10),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test Sentry',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Trimite un mesaj de test către serviciul Sentry pentru a verifica conexiunea și funcționalitatea de raportare a erorilor.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _testSentry,
                    icon: Icon(Icons.bug_report),
                    label: Text('Trimite Mesaj Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testSentry() async {
    try {
      print('[DEBUG] Sentry Test: Inițiator test mesaj...');

      // Capturează un mesaj cu nivel informational
      final sentryId = await Sentry.captureMessage(
        'Test message from Expense Tracker Settings',
        level: SentryLevel.info,
        withScope: (scope) {
          scope.setTag('source', 'settings_page');
          scope.setTag('action', 'test_sentry');
        },
      );

      print('[DEBUG] Sentry sentryId: $sentryId');

      // Afișează feedback pozitiv
      if (!mounted) return;
      if (sentryId.toString().isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Mesaj trimis cu succes!\nEvent ID: $sentryId'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '⚠️ Sentry DSN nu este configurat.\n'
              'Rulează: flutter run --dart-define=SENTRY_DSN=tău_dsn_url',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('[ERROR] Sentry Test: $e');
      print('[ERROR] StackTrace: $stackTrace');

      // Afișează eroare dacă testul eșuează
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✗ Eroare: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
