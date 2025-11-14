import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_nou/services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker_nou/providers/settings_provider.dart';
import 'package:expense_tracker_nou/theme/theme.dart'; // Importăm noul verde

class HomePage extends StatefulWidget {
  final VoidCallback onSeeAllPressed;
  const HomePage({super.key, required this.onSeeAllPressed});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreService _firestoreService = FirestoreService();

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Mâncare':
        return Icons.fastfood;
      case 'Transport':
        return Icons.directions_car;
      case 'Facturi':
        return Icons.receipt_long;
      case 'Timp Liber':
        return Icons.sports_esports;
      case 'Cumpărături':
        return Icons.shopping_bag;
      case 'Salariu':
        return Icons.work;
      case 'Bonus':
        return Icons.card_giftcard;
      case 'Cadou':
        return Icons.cake;
      default:
        return Icons.money;
    }
  }

  // --- FUNCȚIE NOUĂ PENTRU A OBȚINE SALUTUL ---
  String _getGreeting() {
    final int currentHour = DateTime.now().hour;

    if (currentHour >= 5 && currentHour < 12) {
      return 'Bună dimineața,';
    } else if (currentHour >= 12 && currentHour < 18) {
      return 'Bună ziua,';
    } else {
      // De la 18:00 seara până la 4:59 dimineața
      return 'Bună seara,';
    }
  }

  // --- FUNCȚIE NOUĂ PENTRU A ALEGE LOGO SAU ICONIȚĂ ---
  Widget _buildTransactionLeading(Map<String, dynamic> data, bool isExpense) {
    String description = (data['description'] ?? '').toLowerCase();
    String category = data['category'] ?? 'Altul';

    // 1. Verifică brand-urile specifice (pe baza descrierii)
    // Adaugă oricâte vrei tu aici
    if (description.contains('netflix')) {
      return CircleAvatar(
        backgroundColor: Colors.white, // Culoarea de fundal a logo-ului
        child: Image.asset('assets/images/netflix.png', width: 28, height: 28),
      );
    }
    if (description.contains('orange')) {
      return CircleAvatar(
        backgroundColor: Colors.white,
        child: Image.asset('assets/images/orange.png', width: 28, height: 28),
      );
    }
    if (description.contains('digi')) {
      return CircleAvatar(
        backgroundColor: Colors.white, // Un fundal deschis pentru Upwork
        child: Image.asset('assets/images/digi.png', width: 28, height: 28),
      );
    }
    if (description.contains('enel')) {
      return CircleAvatar(
        backgroundColor: Colors.white, // Un fundal deschis pentru Upwork
        child: Image.asset('assets/images/enel.png', width: 28, height: 28),
      );
    }
    if (description.contains('eon')) {
      return CircleAvatar(
        backgroundColor: Colors.white, // Un fundal deschis pentru Upwork
        child: Image.asset('assets/images/eon.png', width: 28, height: 28),
      );
    }
    if (description.contains('revolut')) {
      return CircleAvatar(
        backgroundColor: Colors.white, // Un fundal deschis pentru Upwork
        child: Image.asset('assets/images/revolut.png', width: 28, height: 28),
      );
    }
    if (description.contains('starbucks')) {
      return CircleAvatar(
        backgroundColor: Colors.white, // Un fundal deschis pentru Upwork
        child: Image.asset(
          'assets/images/starbucks.png',
          width: 28,
          height: 28,
        ),
      );
    }
    // 2. Dacă nu e un brand, folosește iconița de categorie (logica veche)
    return CircleAvatar(
      backgroundColor: isExpense
          ? Colors.red.withOpacity(0.1)
          : const Color(0xff2f7e79).withOpacity(0.1),
      child: Icon(
        _getIconForCategory(category),
        color: isExpense ? Colors.red[300] : const Color(0xff2f7e79),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final user = FirebaseAuth.instance.currentUser;

    // Scaffold este exterior
    return Scaffold(
      // StreamBuilder este BODY-ul Scaffold-ului
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestoreService.users.doc(user?.uid).snapshots(),
        builder: (context, userSnapshot) {
          // 1. Loading
          if (!userSnapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          // 2. Extrage numele
          String userName = 'Utilizator';
          if (userSnapshot.data!.exists) {
            var userData = userSnapshot.data!.data() as Map<String, dynamic>;
            userName = userData['name'] ?? userName;
          }
          String greeting = _getGreeting();
          // 3. Returnează interfața (Stack-ul)
          return Stack(
            children: [
              // --- 1. FUNDALUL VERDE (VALUL) ---
              // --- 1. FUNDALUL VERDE (CU IMAGINE) ---
              ClipPath(
                clipper: _TopCurveClipper(),
                child: Container(
                  height: 350, // Înălțimea valului
                  decoration: BoxDecoration(
                    // --- MODIFICAT PENTRU A FOLOSI IMAGINEA ---
                    image: DecorationImage(
                      image: AssetImage(
                        'assets/images/fundal.png',
                      ), // <-- Numele imaginii
                      fit: BoxFit.cover, // Acoperă tot spațiul
                    ),
                  ),
                ),
              ),

              // --- 2. CONȚINUTUL PAGINII ---
              SafeArea(
                child: Column(
                  children: [
                    // --- A. ANTETUL (HEADER) ---
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 10.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                greeting,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              Text(
                                userName,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),

                          // --- RÂND NOU PENTRU ICONIȚE ---
                          Row(
                            children: [
                              // --- BUTONUL PENTRU TEMĂ (NOU) ---
                              IconButton(
                                icon: Icon(
                                  // Verifică care este tema curentă
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Icons
                                            .light_mode // E întunecat? Arată soarele
                                      : Icons
                                            .dark_mode, // E luminos? Arată luna
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  // Obține provider-ul (fără să asculte)
                                  final settings =
                                      Provider.of<SettingsProvider>(
                                        context,
                                        listen: false,
                                      );

                                  // Schimbă tema
                                  if (Theme.of(context).brightness ==
                                      Brightness.dark) {
                                    settings.updateTheme(ThemeMode.light);
                                  } else {
                                    settings.updateTheme(ThemeMode.dark);
                                  }
                                },
                              ),

                              // --- BUTONUL DE NOTIFICĂRI (CLOPOȚELUL) ---
                              IconButton(
                                icon: Icon(
                                  Icons.notifications,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  /* TODO: Pagina de notificări */
                                },
                              ),
                            ],
                          ),
                          // --- SFÂRȘIT RÂND NOU ---
                        ],
                      ),
                    ),

                    // --- B. CARDUL-SUMAR ---
                    _buildSummaryCard(settings),

                    // --- C. TITLUL LISTEI ---
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Istoric Tranzacții',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed:
                                widget.onSeeAllPressed, // <-- APELĂM FUNCȚIA
                            child: Text('Vezi Tot'),
                          ),
                        ],
                      ),
                    ),

                    // --- D. LISTA DE TRANZACȚII ---
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _firestoreService.getExpensesStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'A apărut o eroare: ${snapshot.error}',
                              ),
                            );
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Text('Nici o tranzacție adăugată'),
                            );
                          }
                          var expenses = snapshot.data!.docs;

                          return ListView.builder(
                            itemCount: expenses.length,
                            itemBuilder: (context, index) {
                              var expense = expenses[index];
                              var data = expense.data() as Map<String, dynamic>;
                              String description = data['description'] ?? 'N/A';
                              double amount = (data['amount'] ?? 0.0)
                                  .toDouble();
                              String type = data['type'] ?? 'expense';
                              bool isExpense = type == 'expense';
                              String expenseOwnerUid = data['uid'] ?? '';
                              String currentUserUid =
                                  FirebaseAuth.instance.currentUser?.uid ?? '';
                              bool isMyExpense =
                                  expenseOwnerUid == currentUserUid;

                              return Dismissible(
                                key: Key(expense.id),
                                onDismissed: (direction) {
                                  _firestoreService.deleteExpense(expense.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '$description a fost șters',
                                      ),
                                    ),
                                  );
                                },
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child: Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                child: ListTile(
                                  leading: _buildTransactionLeading(
                                    data,
                                    isExpense,
                                  ), // <-- APELĂM FUNCȚIA NOUĂ
                                  title: Text(description),
                                  subtitle: Text(
                                    "${data['category'] ?? 'Fără categorie'} • ${isMyExpense ? 'Tu' : 'Soția'}",
                                  ),
                                  trailing: Text(
                                    '${isExpense ? '-' : '+'}${settings.currencySymbol}${amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: isExpense
                                          ? Colors.red[400]
                                          : const Color(0xff2f7e79),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- FUNCȚIILE HELPER ---
  Widget _buildSummaryCard(SettingsProvider settings) {
    return Card(
      margin: EdgeInsets.all(16.0),
      elevation: 0,
      color: accentGreen.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Suma Totală',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getAccountsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return CircularProgressIndicator(color: Colors.white);
                }
                double totalBalance = 0;
                for (var doc in snapshot.data!.docs) {
                  totalBalance +=
                      (doc.data() as Map<String, dynamic>)['balance'] ?? 0.0;
                }
                return Text(
                  '${settings.currencySymbol}${totalBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            Divider(color: Colors.white.withOpacity(0.3)),
            SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getExpensesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return SizedBox.shrink();
                double totalIncome = 0;
                double totalExpenses = 0;
                for (var doc in snapshot.data!.docs) {
                  var data = doc.data() as Map<String, dynamic>;
                  if (data['type'] == 'income') {
                    totalIncome += data['amount'] ?? 0.0;
                  } else {
                    totalExpenses += data['amount'] ?? 0.0;
                  }
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildIncomeExpenseRow(
                      icon: Icons.arrow_downward,
                      color: Colors.greenAccent[100]!,
                      label: 'Venituri',
                      amount: totalIncome,
                      currencySymbol: settings.currencySymbol,
                    ),
                    _buildIncomeExpenseRow(
                      icon: Icons.arrow_upward,
                      color: Colors.redAccent[100]!,
                      label: 'Cheltuieli',
                      amount: totalExpenses,
                      currencySymbol: settings.currencySymbol,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeExpenseRow({
    required IconData icon,
    required Color color,
    required String label,
    required double amount,
    required String currencySymbol,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Colors.white.withOpacity(0.1),
          child: Icon(icon, color: color, size: 30),
        ),
        SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8))),
            Text(
              '$currencySymbol${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
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
