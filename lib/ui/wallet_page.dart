import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_nou/services/firestore_service.dart';
import 'package:expense_tracker_nou/theme/theme.dart'; // Importăm tema pentru culori
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

  // Funcție pentru a deschide fereastra (Adăugare sau Editare)
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
      // Folosim Stack pentru a suprapune fundalul și conținutul
      body: Stack(
        children: [
          // --- 1. FUNDALUL VERDE (VALUL) ---
          ClipPath(
            clipper: _TopCurveClipper(),
            child: Container(
              height: 300, // Înălțimea valului
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    'assets/images/fundal.png',
                  ), // Imaginea ta texturată
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // --- 2. CONȚINUTUL PAGINII ---
          SafeArea(
            child: Column(
              children: [
                // --- A. ANTETUL (Titlu) ---
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 10.0,
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center, // Centrăm titlul
                    children: [
                      Text(
                        'Portofel & Conturi',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Text alb pe fundal verde
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
                    top: 50,
                    bottom: 10,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Conturile Tale',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // --- D. LISTA DE CONTURI ---
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestoreService.getAccountsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError)
                        return Center(child: Text('Eroare: ${snapshot.error}'));
                      if (!snapshot.hasData)
                        return Center(child: CircularProgressIndicator());

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

                          return _buildMinimalistCard(accountDoc, data);
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

      // Butonul de adăugare cont (rămâne aici)
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAccountSheet(),
        child: const Icon(Icons.add),
        backgroundColor: accentGreen, // Ne asigurăm că e verde
        foregroundColor: Colors.white,
      ),
    );
  }

  // --- CARD MINIMALIST (CONT) ---
  Widget _buildMinimalistCard(DocumentSnapshot doc, Map<String, dynamic> data) {
    String name = data['name'] ?? 'N/A';
    double balance = (data['balance'] ?? 0.0).toDouble();
    String currency = data['currency'] ?? 'RON';

    String symbol = '\$';
    if (currency == 'RON') symbol = 'RON ';
    if (currency == 'EUR') symbol = '€';
    if (currency == 'GBP') symbol = '£';

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
              IconButton(
                icon: Icon(Icons.edit, size: 20, color: Colors.grey),
                onPressed: () => _showAccountSheet(account: doc),
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
            '$symbol${balance.toStringAsFixed(2)}',
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

  // --- CARDUL CU BALANȚA TOTALĂ (STILIZAT) ---
  Widget _buildTotalBalanceCard(SettingsProvider settings) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      elevation: 5, // Umbră mai pronunțată
      color: Colors.white, // Card alb pentru contrast cu fundalul verde
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            children: [
              Text(
                'Balanță Totală Portofele',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 10),
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
                      color: accentGreen, // Folosim verdele nostru pentru sumă
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

// --- CLASA CLIPPER (ACEEAȘI CA ÎN CELELALTE FIȘIERE) ---
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
