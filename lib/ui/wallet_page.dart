import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_nou/services/firestore_service.dart';
import 'package:expense_tracker_nou/theme/theme.dart'; // Importăm tema
import 'package:expense_tracker_nou/ui/add_account_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker_nou/providers/settings_provider.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final FirestoreService _firestoreService = FirestoreService();

  void _showAccountSheet({DocumentSnapshot? account}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return AddAccountSheet(accountToEdit: account);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // --- 1. FUNDALUL VERDE (VALUL) ---
          ClipPath(
            clipper: _TopCurveClipper(),
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/fundal.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // --- 2. CONȚINUTUL PAGINII ---
          SafeArea(
            child: Column(
              children: [
                // --- A. ANTETUL ---
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 10.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Portofel & Conturi',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // --- B. CARDUL CU BALANȚA TOTALĂ ---
                _buildTotalBalanceCard(settings),

                // --- C. TITLUL LISTEI ---
                Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 40,
                    bottom: 10,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Conturile Tale',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        // Culoarea textului se adaptează automat la temă
                      ),
                    ),
                  ),
                ),

                // --- D. LISTA DE CONTURI ---
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestoreService.getAccountsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Eroare: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      var accounts = snapshot.data!.docs;

                      if (accounts.isEmpty) {
                        return Center(
                          child: Text('Niciun cont. Apasă + pentru a adăuga.'),
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: accounts.length,
                        itemBuilder: (context, index) {
                          var accountDoc = accounts[index];
                          var data = accountDoc.data() as Map<String, dynamic>;

                          // Folosim noul design "discret"
                          return _buildAccountListTile(accountDoc, data);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAccountSheet(),
        backgroundColor: accentGreen,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- CARD STILIZAT CA ÎN STATISTICI (DISCRET) ---
  Widget _buildAccountListTile(
    DocumentSnapshot doc,
    Map<String, dynamic> data,
  ) {
    String name = data['name'] ?? 'N/A';
    double balance = (data['balance'] ?? 0.0).toDouble();
    String currency = data['currency'] ?? 'RON';

    String symbol = '\$';
    if (currency == 'RON') symbol = 'RON ';
    if (currency == 'EUR') symbol = '€';
    if (currency == 'GBP') symbol = '£';

    return Card(
      elevation: 2, // Umbră mică, discretă
      margin: EdgeInsets.only(bottom: 12), // Spațiu între ele
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      // 'Card' preia automat culoarea corectă pentru Light/Dark mode
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),

        // Iconița din stânga (Cerc verde cu portofel)
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withOpacity(0.1),
          child: Icon(
            Icons.account_balance_wallet,
            color: Theme.of(context).colorScheme.primary, // Verdele nostru
            size: 24,
          ),
        ),

        // Numele Contului
        title: Text(
          name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),

        // Balanța și Butonul Editare în dreapta
        trailing: Row(
          mainAxisSize: MainAxisSize.min, // Ocupă spațiu minim
          children: [
            // Suma
            Text(
              '$symbol${balance.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary, // Verde
              ),
            ),
            SizedBox(width: 10),
            // Butonul Editare (Mic și gri)
            IconButton(
              icon: Icon(Icons.edit, size: 20, color: Colors.grey),
              onPressed: () => _showAccountSheet(account: doc),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(), // Scoate padding-ul default
            ),
          ],
        ),
      ),
    );
  }

  // --- CARDUL CU BALANȚA TOTALĂ ---
  Widget _buildTotalBalanceCard(SettingsProvider settings) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      elevation: 5,
      color: accentGreen.withOpacity(0.8), // Rămâne alb pe fundalul verde
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(60.0),
        child: Center(
          child: Column(
            children: [
              Text(
                'Balanță Totală Portofele',
                style: TextStyle(
                  fontSize: 16,
                  color: const Color.fromARGB(255, 209, 208, 208),
                ),
              ),
              SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: _firestoreService.getAccountsStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return CircularProgressIndicator(color: accentGreen);
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
                      color: Colors.white,
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
}

class _TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 80);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 80,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
