import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_nou/services/firestore_service.dart';
import 'package:expense_tracker_nou/theme/theme.dart';
import 'package:expense_tracker_nou/ui/add_account_sheet.dart';
import 'package:expense_tracker_nou/ui/recurring_transactions_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker_nou/providers/settings_provider.dart';

class WalletPage extends StatefulWidget {
  final VoidCallback? onBackTap;
  const WalletPage({super.key, this.onBackTap});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    // Ținem balanțele/istoricul la zi când intri în Portofel.
    _firestoreService.runDueRecurringTransactions();
  }

  void _showAccountSheet({DocumentSnapshot? account}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddAccountSheet(accountToEdit: account),
    );
  }

  void _showDeleteAccountDialog(DocumentSnapshot accountDoc) {
    final accountData = accountDoc.data() as Map<String, dynamic>;
    final accountName = accountData['name'] ?? 'acest cont';

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Șterge Cont'),
        content: Text(
          'Ești sigur că vrei să ștergi "$accountName"?\n\n'
          'Această acțiune va șterge:\n'
          '• Contul\n'
          '• Toate tranzacțiile asociate\n\n'
          'Această acțiune este ireversibilă și va actualiza automat balanțele.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Anulează'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                await _firestoreService.deleteAccount(accountDoc.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Contul "$accountName" a fost șters'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Eroare la ștergere: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Șterge',
              style: TextStyle(color: const Color(0xff7b0828)),
            ),
          ),
        ],
      ),
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
                  // AM MODIFICAT AICI: Am schimbat din symmetric în only pentru a adăuga spațiu specific sus
                  padding: const EdgeInsets.only(
                    top:
                        40.0, // <-- Aici este spațiul adăugat deasupra. Poți crește la 50.0 sau 60.0 dacă vrei mai jos.
                    bottom: 10.0,
                    left: 8.0,
                    right: 8.0,
                  ),
                  // Folosim un Row pentru a alinia elementele orizontal
                  child: Row(
                    children: [
                      // 1. Butonul de Back (Săgeata din stânga)
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                        ),
                        // Navighează înapoi la pagina anterioară
                        onPressed: () {
                          // 1. Dacă pagina a primit o funcție de la părinte (ex: să schimbe tab-ul), o executăm.
                          if (widget.onBackTap != null) {
                            widget.onBackTap!();
                          }
                          // 2. Altfel, verificăm dacă e sigur să dăm pop (dacă am intrat aici din altă pagină prin Navigator.push)
                          else if (Navigator.canPop(context)) {
                            Navigator.of(context).pop();
                          }
                          // 3. Dacă niciuna nu e valabilă, butonul nu va face nimic, evitând astfel crash-ul / ecranul negru.
                        },
                      ),

                      // 2. Titlul Centrat
                      Expanded(
                        child: Text(
                          'Portofel & Conturi',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      // 3. Spacer invizibil pentru echilibrare
                      // Deoarece am pus un buton în stânga, trebuie să punem un spațiu gol
                      // de aceeași dimensiune în dreapta pentru ca titlul să rămână perfect centrat.
                      // Un IconButton standard are cam 48px lățime.
                      const SizedBox(width: 48),

                      // AM ELIMINAT: Butonul IconButton cu iconița Icons.repeat a fost șters de aici.
                    ],
                  ),
                ),
                const SizedBox(height: 25.0),
                _buildTotalBalanceCard(settings),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.repeat,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: const Text(
                        'Recurențe',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Adaugă plăți/venituri recurente și aplică-le automat.',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const RecurringTransactionsPage(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
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
                      if (snapshot.hasError) {
                        return Center(child: Text('Eroare: ${snapshot.error}'));
                      }
                      // OPTIMISTIC UI
                      if (snapshot.hasData) {
                        var accounts = snapshot.data!.docs;
                        if (accounts.isEmpty) {
                          return Center(
                            child: Text(
                              'Niciun cont. Apasă + pentru a adăuga.',
                            ),
                          );
                        }
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
        backgroundColor: accentGreen,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
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
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(
                Icons.account_balance_wallet,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${balance.toStringAsFixed(2)} $symbol',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, size: 20, color: Colors.grey),
                  onPressed: () => _showAccountSheet(account: doc),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    size: 20,
                    color: const Color(0xff7b0828),
                  ),
                  onPressed: () => _showDeleteAccountDialog(doc),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalBalanceCard(SettingsProvider settings) {
    return Card(
      margin: EdgeInsets.all(16.0),
      elevation: 0,
      color: const Color(0xff2f7e79).withValues(alpha: 0.97),
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
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: _firestoreService.getAccountsStream(),
                builder: (context, snapshot) {
                  // OPTIMISTIC UI
                  if (snapshot.hasData) {
                    double total = 0;
                    for (var doc in snapshot.data!.docs) {
                      total +=
                          (doc.data() as Map<String, dynamic>)['balance'] ??
                          0.0;
                    }
                    return Text(
                      '${total.toStringAsFixed(2)} ${settings.currencySymbol}',
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
