import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_nou/services/firestore_service.dart';
import 'package:expense_tracker_nou/theme/theme.dart';
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
      builder: (context) => AddAccountSheet(accountToEdit: account),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
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
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 10.0,
                  ),
                  child: Center(
                    child: Text(
                      'Portofel & Conturi',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                _buildTotalBalanceCard(settings),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 20,
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
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestoreService.getAccountsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError)
                        return Center(child: Text('Eroare: ${snapshot.error}'));
                      // OPTIMISTIC UI
                      if (snapshot.hasData) {
                        var accounts = snapshot.data!.docs;
                        if (accounts.isEmpty)
                          return Center(
                            child: Text(
                              'Niciun cont. Apasă + pentru a adăuga.',
                            ),
                          );
                        return ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: accounts.length,
                          itemBuilder: (context, index) {
                            return _buildMinimalistCard(
                              accounts[index],
                              accounts[index].data() as Map<String, dynamic>,
                            );
                          },
                        );
                      }
                      return Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_wallet',
        onPressed: () => _showAccountSheet(),
        child: const Icon(Icons.add),
        backgroundColor: accentGreen,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildMinimalistCard(DocumentSnapshot doc, Map<String, dynamic> data) {
    String name = data['name'] ?? 'N/A';
    double balance = (data['balance'] ?? 0.0).toDouble();
    String currency = data['currency'] ?? 'RON';
    String symbol = currency == 'RON'
        ? 'RON '
        : (currency == 'EUR' ? '€' : (currency == 'GBP' ? '£' : '\$'));

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withOpacity(0.1),
          child: Icon(
            Icons.account_balance_wallet,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
        title: Text(
          name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$symbol${balance.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(width: 10),
            IconButton(
              icon: Icon(Icons.edit, size: 20, color: Colors.grey),
              onPressed: () => _showAccountSheet(account: doc),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
            SizedBox(width: 5),
            IconButton(
              icon: Icon(Icons.delete, size: 20, color: Colors.red[300]),
              onPressed: () {
                // Aici ar trebui să fie logica de ștergere (confirmare + deleteAccount din service)
                // Poți adăuga dialogul de confirmare aici dacă vrei
              },
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalBalanceCard(SettingsProvider settings) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      elevation: 0,
      color: accentGreen.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            children: [
              Text(
                'Balanță Totală Portofele',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: _firestoreService.getAccountsStream(),
                builder: (context, snapshot) {
                  // OPTIMISTIC UI
                  if (snapshot.hasData) {
                    double total = 0;
                    for (var doc in snapshot.data!.docs)
                      total +=
                          (doc.data() as Map<String, dynamic>)['balance'] ??
                          0.0;
                    return Text(
                      '${settings.currencySymbol}${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }
                  return SizedBox(
                    height: 40,
                    width: 40,
                    child: CircularProgressIndicator(color: Colors.white),
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
