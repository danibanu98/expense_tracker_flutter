import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker_nou/providers/settings_provider.dart';

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
        ],
      ),
    );
  }
}
