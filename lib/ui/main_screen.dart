import 'package:expense_tracker_nou/ui/add_transaction_sheet.dart'; // Avem nevoie de asta acum
import 'package:expense_tracker_nou/ui/home_page.dart';
import 'package:expense_tracker_nou/ui/profile_page.dart';
import 'package:expense_tracker_nou/ui/statistics_page.dart';
import 'package:expense_tracker_nou/ui/wallet_page.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Definim lista goală
  late final List<Widget> _widgetOptions;

  // Definim funcția de navigare
  void _navigateTo(int index) {
    _onItemTapped(index);
  }

  @override
  void initState() {
    super.initState();
    // Inițializăm lista de widget-uri AICI
    _widgetOptions = <Widget>[
      HomePage(
        onSeeAllPressed: () => _navigateTo(1),
      ), // <-- Trimitem funcția către HomePage (Index 1 = Statistici)
      StatisticsPage(),
      WalletPage(),
      ProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- FUNCȚIE NOUĂ PENTRU BUTONUL + ---
  void _showAddTransactionSheet() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionSheet(), // Navighează la ecran
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Afișează ecranul selectat
      // Afișează ecranul selectat, dar le păstrează pe celelalte "vii"
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),

      // --- BUTONUL + MUTAT AICI ȘI MĂRIT ---
      floatingActionButton: SizedBox(
        width: 64.0, // Mărimea nouă (implicit e 56.0)
        height: 64.0, // Mărimea nouă
        child: FloatingActionButton(
          onPressed: _showAddTransactionSheet,
          child: Icon(
            Icons.add,
            color: Colors.white,
            size: 32.0,
          ), // Am mărit și iconița
          // Culoarea și forma sunt preluate din temă
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked, // Îl punem în centru
      // --- MENIUL DE JOS MODIFICAT ---
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(), // Creează "gaura" pentru buton
        notchMargin: 8.0, // Spațiul din jurul butonului

        child: Row(
          // Am împărțit item-urile în două perechi, cu spațiu la mijloc
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            // --- Stânga ---
            _buildNavItem(icon: Icons.home, index: 0, label: 'Acasă'),
            _buildNavItem(icon: Icons.bar_chart, index: 1, label: 'Statistici'),

            // Spațiul gol pentru butonul +
            SizedBox(width: 40),

            // --- Dreapta ---
            _buildNavItem(icon: Icons.wallet, index: 2, label: 'Portofel'),
            _buildNavItem(icon: Icons.person, index: 3, label: 'Profil'),
          ],
        ),
      ),
    );
  }

  // --- FUNCȚIE HELPER PENTRU NOUL MENIU ---
  Widget _buildNavItem({
    required IconData icon,
    required int index,
    required String label,
  }) {
    return IconButton(
      icon: Icon(
        icon,
        size: 35,
        color: _selectedIndex == index
            ? Theme.of(context)
                  .colorScheme
                  .primary // Culoare activă (verde)
            : Colors.grey[600], // Culoare inactivă
      ),
      onPressed: () => _onItemTapped(index),
      tooltip: label,
    );
  }
}
