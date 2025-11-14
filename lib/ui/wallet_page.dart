import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_nou/services/firestore_service.dart';
import 'package:expense_tracker_nou/ui/add_account_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker_nou/providers/settings_provider.dart';
import 'package:expense_tracker_nou/theme/theme.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  // 1. Adaugă serviciul
  final FirestoreService _firestoreService = FirestoreService();

  // 2. Funcția de afișare a ferestrei de adăugare (o vom crea imediat)
  void _showAddAccountSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite ferestrei să fie mai înaltă
      builder: (context) {
        return AddAccountSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Portofel & Conturi')),

      // --- ÎNCEPE MODIFICAREA ---
      body: Column(
        children: [
          // Partea 1: Cardul cu Balanța Totală
          _buildTotalBalanceCard(settings), // O funcție nouă
          // Partea 2: Lista de conturi (într-un 'Expanded')
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getAccountsStream(),
              builder: (context, snapshot) {
                // ... (TOT CODUL TĂU 'StreamBuilder' DE DINAINTE ...
                // ... DE LA 'if (snapshot.connectionState...' ...

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('A apărut o eroare: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Nici un cont adăugat'));
                }

                var accounts = snapshot.data!.docs;

                return ListView.builder(
                  padding: EdgeInsets.all(16), // Am mărit padding-ul
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    var account = accounts[index];
                    var data = account.data() as Map<String, dynamic>;

                    // Apelăm noua funcție helper
                    return _buildAccountCard(
                      data: data,
                      settings: settings,
                      // Vom adăuga o logică pentru a alege culoarea/iconița mai târziu
                      icon: Icons.account_balance_wallet,
                      color: accentGreen, // Culoarea noastră verde
                    );
                  },
                );
                // --- Sfârșitul codului vechi 'StreamBuilder' ---
              },
            ),
          ),
        ],
      ),

      // 4. Adăugăm un buton `+`
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAccountSheet,
        tooltip: 'Adaugă Cont',
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- FUNCȚIE NOUĂ PENTRU CARDUL CU BALANȚA TOTALĂ ---
  Widget _buildTotalBalanceCard(SettingsProvider settings) {
    return Card(
      margin: EdgeInsets.all(16.0),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            children: [
              Text(
                'Balanță Totală Conturi',
                style: TextStyle(fontSize: 18, color: Colors.grey[400]),
              ),
              SizedBox(height: 10),

              // Ascultă CONTURILE pentru Balanța Totală
              StreamBuilder<QuerySnapshot>(
                stream: _firestoreService.getAccountsStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return CircularProgressIndicator();
                  }

                  double totalBalance = 0;
                  for (var doc in snapshot.data!.docs) {
                    totalBalance +=
                        (doc.data() as Map<String, dynamic>)['balance'] ?? 0.0;
                  }

                  return Text(
                    '${settings.currencySymbol}${totalBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: totalBalance >= 0
                          ? const Color(0xff2f7e79)
                          : Colors.red[400],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- FUNCȚIE NOUĂ PENTRU CARDUL DE CONT ---
  Widget _buildAccountCard({
    required Map<String, dynamic> data,
    required SettingsProvider settings,
    required IconData icon,
    required Color color,
  }) {
    String name = data['name'] ?? 'N/A';
    double balance = (data['balance'] ?? 0.0).toDouble();

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Container(
        // Containerul pentru a aplica gradientul și colțurile
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rândul de sus (Iconiță și Nume)
              Row(
                children: [
                  Icon(icon, size: 30, color: Colors.white),
                  SizedBox(width: 15),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Textul "Balanță"
              Text(
                'BALANȚĂ',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                  letterSpacing: 1.1,
                ),
              ),
              SizedBox(height: 5),

              // Suma (Balanța)
              Text(
                '${settings.currencySymbol}${balance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
