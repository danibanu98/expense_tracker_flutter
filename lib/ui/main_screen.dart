import 'package:expense_tracker_nou/ui/add_transaction_sheet.dart'; // Avem nevoie de asta acum
import 'package:expense_tracker_nou/ui/home_page.dart';
import 'package:expense_tracker_nou/ui/profile_page.dart';
import 'package:expense_tracker_nou/ui/statistics_page.dart';
import 'package:expense_tracker_nou/ui/wallet_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  final int lastTabIndex;
  const MainScreen({super.key, required this.lastTabIndex});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex; // O vom inițializa imediat

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
    _selectedIndex = widget.lastTabIndex;
    _widgetOptions = <Widget>[
      HomePage(
        onSeeAllPressed: () => _navigateTo(1),
      ), // <-- Trimitem funcția către HomePage (Index 1 = Statistici)
      StatisticsPage(),
      WalletPage(),
      ProfilePage(),
    ];
  }

  void _onItemTapped(int index) async {
    // <-- Am făcut-o 'async'
    setState(() {
      _selectedIndex = index;
    });

    // --- LINIE NOUĂ: Salvăm indexul ---
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('lastTabIndex', index);
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
    // Verificăm dacă suntem pe o pagină care trebuie să arate butonul +
    // 0 = Acasă, 2 = Portofel
    bool showFab = (_selectedIndex == 0);

    return Scaffold(
      body: IndexedStack(
        // Folosim IndexedStack-ul nostru
        index: _selectedIndex,
        children: _widgetOptions,
      ),

      // --- MODIFICARE 1: Afișează butonul doar pe anumite pagini ---
      floatingActionButton:
          showFab // Am folosit variabila de mai sus
          ? SizedBox(
              width: 64.0,
              height: 64.0,
              child: FloatingActionButton(
                onPressed: _showAddTransactionSheet,
                child: Icon(Icons.add, color: Colors.white, size: 32.0),
              ),
            )
          : null, // NU arăta butonul pe paginile Statistici sau Profil
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // --- MODIFICARE 2: Meniul de jos se adaptează ---
      bottomNavigationBar: BottomAppBar(
        shape: showFab
            ? CircularNotchedRectangle()
            : null, // Are "gaură" doar dacă butonul e vizibil
        notchMargin: 8.0,

        child: Row(
          // Aici e logica de spațiere
          mainAxisAlignment: showFab
              ? MainAxisAlignment
                    .spaceAround // Spațiere cu "gaură"
              : MainAxisAlignment.spaceEvenly, // Spațiere EGALĂ
          children: <Widget>[
            // Stânga
            _buildNavItem(icon: Icons.home, index: 0, label: 'Acasă'),
            _buildNavItem(icon: Icons.bar_chart, index: 1, label: 'Statistici'),

            // Spațiul gol pentru butonul + (doar dacă e vizibil)
            if (showFab) SizedBox(width: 40),

            // Dreapta
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
