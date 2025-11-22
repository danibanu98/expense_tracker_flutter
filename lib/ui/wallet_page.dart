import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_nou/services/firestore_service.dart';
import 'package:expense_tracker_nou/ui/add_account_sheet.dart';
import 'package:flutter/material.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final FirestoreService _firestoreService = FirestoreService();

  // Funcție pentru a deschide fereastra (Adăugare sau Editare)
  void _showAccountSheet({DocumentSnapshot? account}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        // Dacă trimitem 'account', suntem în mod Editare
        return AddAccountSheet(accountToEdit: account);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Notă: Nu mai folosim settings.currencySymbol aici pentru conturi,
    // ci moneda specifică fiecărui cont!

    return Scaffold(
      appBar: AppBar(title: Text('Portofel')),

      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getAccountsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text('Eroare: ${snapshot.error}'));
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          var accounts = snapshot.data!.docs;

          if (accounts.isEmpty) {
            return Center(child: Text('Niciun cont. Apasă + pentru a adăuga.'));
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              var accountDoc = accounts[index];
              var data = accountDoc.data() as Map<String, dynamic>;

              return _buildMinimalistCard(accountDoc, data);
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAccountSheet(), // Mod Adăugare (fără parametri)
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- CARD MINIMALIST (DESIGN NOU) ---
  Widget _buildMinimalistCard(DocumentSnapshot doc, Map<String, dynamic> data) {
    String name = data['name'] ?? 'N/A';
    double balance = (data['balance'] ?? 0.0).toDouble();
    String currency = data['currency'] ?? 'RON'; // Moneda contului

    // Alegem un simbol pe baza monedei salvate
    String symbol = '\$';
    if (currency == 'RON') symbol = 'RON ';
    if (currency == 'EUR') symbol = '€';
    if (currency == 'GBP') symbol = '£';

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface, // Alb pe light mode
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
        // Un mic border subtil
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Iconiță și Nume
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance_wallet,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    name,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              // Butonul de Editare (Creion)
              IconButton(
                icon: Icon(Icons.edit, size: 20, color: Colors.grey),
                onPressed: () =>
                    _showAccountSheet(account: doc), // Deschide editare
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            'Balanță Disponibilă',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '$symbol${balance.toStringAsFixed(2)}', // Folosește simbolul contului
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}
