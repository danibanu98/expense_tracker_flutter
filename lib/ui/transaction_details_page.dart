import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_nou/providers/settings_provider.dart';
import 'package:expense_tracker_nou/services/firestore_service.dart';
import 'package:expense_tracker_nou/services/brand_service.dart';
import 'package:expense_tracker_nou/ui/add_transaction_sheet.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TransactionDetailsPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final String transactionId;

  const TransactionDetailsPage({
    super.key,
    required this.data,
    required this.transactionId,
  });

  // --- FUNCȚIE PENTRU A OBȚINE NUMELE UTILIZATORULUI DIN DB ---
  Future<String> _getUserName(String uid) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (userDoc.exists) {
        return userDoc.get('name') ?? 'Necunoscut';
      }
      return 'Necunoscut';
    } catch (e) {
      return 'Eroare';
    }
  }

  Widget _buildBigTransactionIcon(Map<String, dynamic> data, bool isExpense) {
    final description = data['description'] ?? '';
    final category = data['category'] ?? 'Altele';
    return BrandService.getBigTransactionIcon(
      description: description,
      category: category,
      isExpense: isExpense,
      getIconForCategory: BrandService.getIconForCategory,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final FirestoreService firestoreService = FirestoreService();

    double amount = (data['amount'] ?? 0.0).toDouble();
    String type = data['type'] ?? 'expense';
    bool isExpense = type == 'expense';

    Timestamp timestamp = data['timestamp'] ?? Timestamp.now();
    DateTime date = timestamp.toDate();

    // Formatul de dată și oră pentru România
    String formattedDate = DateFormat('d MMMM yyyy', 'ro').format(date);
    String formattedTime = DateFormat('HH:mm').format(date);
    String ownerUid = data['uid'] ?? '';

    // Culori specifice din design
    final Color primaryGreen = const Color(0xff2f7e79);
    final Color expenseRed = const Color(0xffD32F2F);
    final Color statusColor = isExpense ? expenseRed : primaryGreen;

    return Scaffold(
      // --- AM ȘTERS APPBAR-UL STANDARD DE AICI ---
      body: Stack(
        children: [
          // --- 1. IMAGINEA DE FUNDAL CU CURBĂ ---
          ClipPath(
            clipper: _TopCurveClipper(),
            child: Container(
              height: 320, // Înălțimea imaginii de fundal
              decoration: BoxDecoration(
                color: primaryGreen,
                image: const DecorationImage(
                  image: AssetImage('assets/images/fundal.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // --- 2. HEADER-UL PERSONALIZAT (Centrat pe zona verde) ---
          // Acesta înlocuiește AppBar-ul și stă la mijlocul zonei verzi
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 320 - 140, //Înălțimea imaginii minus curbură, aproximativ
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Buton Back
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),

                      // Titlu
                      const Text(
                        'Detalii Tranzacție',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 20, // Am mărit puțin fontul
                        ),
                      ),

                      // Meniu (3 puncte)
                      IconButton(
                        icon: const Icon(Icons.more_horiz, color: Colors.white),
                        onPressed: () {
                          // Meniu opțiuni (Edit/Delete)
                          showModalBottomSheet(
                            context: context,
                            builder: (ctx) => Wrap(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.edit),
                                  title: const Text('Editează'),
                                  onTap: () async {
                                    Navigator.pop(ctx);
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AddTransactionSheet(
                                              transactionId: transactionId,
                                              transactionData: data,
                                            ),
                                      ),
                                    );
                                    if (result == true && context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  title: const Text(
                                    'Șterge',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    showDialog(
                                      context: context,
                                      builder: (dialogCtx) => AlertDialog(
                                        title: const Text('Ștergi tranzacția?'),
                                        content: const Text(
                                          'Această acțiune este ireversibilă.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(dialogCtx).pop(),
                                            child: const Text('Anulează'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              firestoreService.deleteExpense(
                                                transactionId,
                                              );
                                              Navigator.of(dialogCtx).pop();
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text(
                                              'Șterge',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // --- 3. CONȚINUTUL PAGINII (CARDUL ALB) ---
          Column(
            children: [
              // Am mărit acest spațiu pentru a coborî cardul alb mai jos,
              // lăsând loc pentru titlul centrat
              SizedBox(height: MediaQuery.of(context).padding.top + 130),

              // --- CARDUL ALB PRINCIPAL ---
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 30,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 1. Iconița Brandului
                        _buildBigTransactionIcon(data, isExpense),

                        const SizedBox(height: 10),

                        // 2. Pilula cu Tipul
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isExpense ? 'Cheltuială' : 'Venit',
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 3. Suma Mare
                        Text(
                          '${amount.toStringAsFixed(2)} ${settings.currencySymbol}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // 4. Titlul Secțiunii
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Detalii tranzacție',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_up,
                              color: Colors.black54,
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // 5. Lista de Detalii
                        _buildDetailRow(
                          'Status',
                          isExpense ? 'Cheltuială' : 'Venit',
                          valueColor: statusColor,
                          isBold: true,
                        ),

                        // --- ADAUGĂ ACEASTĂ LINIE AICI ---
                        _buildDetailRow(
                          'Descriere',
                          data['description'] ?? '-',
                          isBold: true,
                        ),

                        // ---------------------------------
                        FutureBuilder<String>(
                          future: _getUserName(ownerUid),
                          builder: (context, snapshot) {
                            String name = snapshot.data ?? '...';
                            return _buildDetailRow(
                              'Adăugat de',
                              name,
                              isBold: true,
                            );
                          },
                        ),

                        const SizedBox(height: 10),
                        const Divider(color: Colors.black12, thickness: 1),
                        const SizedBox(height: 10),

                        _buildDetailRow('Ora', formattedTime, isBold: true),
                        _buildDetailRow('Data', formattedDate, isBold: true),

                        const SizedBox(height: 10),
                        const Divider(color: Colors.black12, thickness: 1),
                        const SizedBox(height: 10),

                        // 6. Total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              '${amount.toStringAsFixed(2)} ${settings.currencySymbol}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper pentru rândurile de detalii
  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: valueColor ?? Colors.black87,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Clasa pentru forma curbată de jos a imaginii
class _TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 80); // Începe din stânga jos (mai sus cu 80px)
    path.quadraticBezierTo(
      size.width / 2, // Punctul de control (mijloc)
      size.height, // Maximul de jos al curbei
      size.width, // Punctul final (dreapta)
      size.height - 80, // Dreapta jos (mai sus cu 80px)
    );
    path.lineTo(size.width, 0); // Dreapta sus
    path.close(); // Închide sus
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
