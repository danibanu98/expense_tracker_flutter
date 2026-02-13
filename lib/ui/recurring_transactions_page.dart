import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_nou/providers/settings_provider.dart';
import 'package:expense_tracker_nou/services/brand_service.dart';
import 'package:expense_tracker_nou/services/firestore_service.dart';
import 'package:expense_tracker_nou/ui/add_recurring_transaction_sheet.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class RecurringTransactionsPage extends StatefulWidget {
  const RecurringTransactionsPage({super.key});

  @override
  State<RecurringTransactionsPage> createState() =>
      _RecurringTransactionsPageState();
}

class _RecurringTransactionsPageState extends State<RecurringTransactionsPage> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _firestoreService.runDueRecurringTransactions();
  }

  String _freqLabel(String freq, int interval) {
    final n = interval <= 0 ? 1 : interval;
    switch (freq) {
      case 'daily':
        return n == 1 ? 'Zilnic' : 'La $n zile';
      case 'weekly':
        return n == 1 ? 'Săptămânal' : 'La $n săptămâni';
      case 'monthly':
        return n == 1 ? 'Lunar' : 'La $n luni';
      case 'yearly':
        return n == 1 ? 'Anual' : 'La $n ani';
      default:
        return 'Recursiv';
    }
  }

  void _openAdd({DocumentSnapshot? edit}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddRecurringTransactionSheet(recurringToEdit: edit),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recurența a fost salvată.')),
      );
    }
  }

  Future<void> _confirmDelete(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final name = (data['description'] ?? 'această recurență').toString();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Șterge recurența?'),
        content: Text('Ești sigur că vrei să ștergi "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Anulează'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Șterge', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await _firestoreService.deleteRecurringTransaction(doc.id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Recurrența a fost ștearsă.')));
  }

  // --- NOU: PANOU DETALIAT (BOTTOM SHEET) LA APĂSAREA CARDULUI ---
  void _showRecurringDetailsSheet(DocumentSnapshot doc) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDarkMode
        ? const Color(0xff1E1E1E)
        : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color subTextColor = isDarkMode
        ? Colors.grey[400]!
        : Colors.grey[600]!;
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final data = doc.data() as Map<String, dynamic>;
        final description = (data['description'] ?? '').toString();
        final category = (data['category'] ?? 'Altele').toString();
        final type = (data['type'] ?? 'expense').toString();
        final isExpense = type == 'expense';
        final amount = (data['amount'] ?? 0.0).toDouble();
        final frequency = (data['frequency'] ?? 'monthly').toString();
        final interval = (data['interval'] ?? 1) as int;
        final active = (data['active'] ?? true) == true;
        final Timestamp? nextTs = data['nextRunAt'];
        final nextRun = nextTs?.toDate();

        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.only(
            top: 12,
            left: 24,
            right: 24,
            bottom: 30,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mânerul de drag
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 25),

              // Iconița Mare
              BrandService.getBigTransactionIcon(
                description: description,
                category: category,
                isExpense: isExpense,
                getIconForCategory: BrandService.getIconForCategory,
              ),
              const SizedBox(height: 16),

              // Titlul
              Text(
                description.isEmpty ? '(Fără descriere)' : description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),

              // Suma uriașă
              Text(
                '${amount.toStringAsFixed(2)} ${settings.currencySymbol}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isExpense
                      ? const Color(0xff7b0828)
                      : const Color(0xff2f7e79),
                ),
              ),

              const SizedBox(height: 25),
              const Divider(),
              const SizedBox(height: 10),

              // Lista de Detalii
              _buildDetailRow(
                'Status',
                active ? 'Activă' : 'Inactivă',
                active ? const Color(0xff2f7e79) : Colors.grey,
                subTextColor,
              ),
              _buildDetailRow(
                'Frecvență',
                _freqLabel(frequency, interval),
                textColor,
                subTextColor,
              ),
              if (nextRun != null)
                _buildDetailRow(
                  'Următoarea plată',
                  DateFormat('d MMMM yyyy', 'ro').format(nextRun),
                  textColor,
                  subTextColor,
                ),

              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 20),

              // Rândul cu Acțiuni (Switch, Edit, Delete)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Switch(
                        value: active,
                        activeColor: Theme.of(context).colorScheme.primary,
                        onChanged: (v) async {
                          Navigator.pop(
                            ctx,
                          ); // Închidem meniul ca să forțăm refresh-ul listei
                          await _firestoreService.updateRecurringTransaction(
                            recurringId: doc.id,
                            description: description,
                            amount: amount,
                            type: type,
                            accountId: (data['accountId'] ?? '').toString(),
                            category: category,
                            frequency: frequency,
                            interval: interval,
                            startDate: (data['startDate'] as Timestamp)
                                .toDate(),
                            active: v,
                          );
                          if (mounted) setState(() {});
                        },
                      ),
                      Text(
                        'Status',
                        style: TextStyle(color: subTextColor, fontSize: 12),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.blue,
                          size: 28,
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openAdd(edit: doc);
                        },
                      ),
                      Text(
                        'Editează',
                        style: TextStyle(color: subTextColor, fontSize: 12),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Color(0xff7b0828),
                          size: 28,
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmDelete(doc);
                        },
                      ),
                      Text(
                        'Șterge',
                        style: TextStyle(color: subTextColor, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    Color valueColor,
    Color labelColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: labelColor)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final Color backgroundColor = isDarkMode
        ? const Color(0xff121212)
        : Colors.grey[50]!;
    final Color cardColor = isDarkMode ? const Color(0xff1E1E1E) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color subTextColor = isDarkMode
        ? Colors.grey[400]!
        : Colors.grey[600]!;
    final Color shadowColor = isDarkMode
        ? Colors.black.withValues(alpha: 0.5)
        : Colors.grey.withValues(alpha: 0.15);

    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_recurring',
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        onPressed: () => _openAdd(),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER-UL PERSONALIZAT ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: textColor,
                      size: 22,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Plăți Recurente',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Rulează acum recurențele scadente',
                    icon: Icon(
                      Icons.play_circle_outline,
                      color: textColor,
                      size: 26,
                    ),
                    onPressed: () async {
                      await _firestoreService.runDueRecurringTransactions();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Recurențele au fost verificate.'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // --- LISTA ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestoreService.getRecurringTransactionsStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return Center(
                      child: Text(
                        'Nu ai recurențe. Apasă + ca să adaugi.',
                        style: TextStyle(color: textColor),
                      ),
                    );
                  }

                  final sorted = List<QueryDocumentSnapshot>.from(docs)
                    ..sort((a, b) {
                      final aNext =
                          (a.data() as Map<String, dynamic>)['nextRunAt']
                              as Timestamp?;
                      final bNext =
                          (b.data() as Map<String, dynamic>)['nextRunAt']
                              as Timestamp?;
                      if (aNext == null && bNext == null) return 0;
                      if (aNext == null) return 1;
                      if (bNext == null) return -1;
                      return aNext.compareTo(bNext);
                    });

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: sorted.length,
                    itemBuilder: (context, index) {
                      final doc = sorted[index];
                      final data = doc.data() as Map<String, dynamic>;

                      final description = (data['description'] ?? '')
                          .toString();
                      final category = (data['category'] ?? 'Altele')
                          .toString();
                      final type = (data['type'] ?? 'expense').toString();
                      final isExpense = type == 'expense';
                      final amount = (data['amount'] ?? 0.0).toDouble();
                      final frequency = (data['frequency'] ?? 'monthly')
                          .toString();
                      final interval = (data['interval'] ?? 1) as int;
                      final active = (data['active'] ?? true) == true;

                      // CARDUL CURĂȚAT ȘI CLICKABIL
                      return Card(
                        color: cardColor,
                        elevation: active
                            ? 2
                            : 0, // Dacă e inactiv, cardul e plat
                        shadowColor: shadowColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () => _showRecurringDetailsSheet(doc),
                          child: Opacity(
                            opacity: active
                                ? 1.0
                                : 0.5, // Ușor transparent dacă e dezactivat
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              child: Row(
                                children: [
                                  BrandService.getTransactionLeading(
                                    description: description,
                                    category: category,
                                    isExpense: isExpense,
                                    getIconForCategory:
                                        BrandService.getIconForCategory,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          description.isEmpty
                                              ? '(Fără descriere)'
                                              : description,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _freqLabel(
                                            frequency,
                                            interval,
                                          ), // Doar frecvența (fără data)
                                          style: TextStyle(
                                            color: subTextColor,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${amount.toStringAsFixed(2)} ${settings.currencySymbol}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isExpense
                                          ? const Color(0xff7b0828)
                                          : const Color(0xff2f7e79),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right,
                                    color: subTextColor,
                                  ),
                                ],
                              ),
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
    );
  }
}
