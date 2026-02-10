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
    // Rulează due când intri în ecran, ca să mențină aplicația la zi.
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
        const SnackBar(content: Text('Recurrența a fost salvată.')),
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
            child: const Text('Șterge'),
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

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plăți & Venituri Recurente'),
        actions: [
          IconButton(
            tooltip: 'Rulează acum recurențele scadente',
            onPressed: () async {
              await _firestoreService.runDueRecurringTransactions();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Recurențele au fost verificate.'),
                ),
              );
            },
            icon: const Icon(Icons.play_circle_outline),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_recurring',
        onPressed: () => _openAdd(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getRecurringTransactionsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text('Nu ai recurențe. Apasă + ca să adaugi.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
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

              // Custom layout to avoid tight constraints that caused
              // the subtitle to wrap vertically (one character per line).
              return Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      BrandService.getTransactionLeading(
                        description: description,
                        category: category,
                        isExpense: isExpense,
                        getIconForCategory: BrandService.getIconForCategory,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              description.isEmpty
                                  ? '(Fără descriere)'
                                  : description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${_freqLabel(frequency, interval)}'
                              '${nextRun != null ? ' • Următoarea: ${DateFormat('d MMM yyyy', 'ro').format(nextRun)}' : ''}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Trailing controls: amount, switch, edit, delete
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isExpense ? '-' : '+'}${settings.currencySymbol}${amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isExpense
                                  ? const Color(0xff7b0828)
                                  : const Color(0xff2f7e79),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: active,
                                onChanged: (v) async {
                                  await _firestoreService
                                      .updateRecurringTransaction(
                                        recurringId: doc.id,
                                        description: description,
                                        amount: amount,
                                        type: type,
                                        accountId: (data['accountId'] ?? '')
                                            .toString(),
                                        category: category,
                                        frequency: frequency,
                                        interval: interval,
                                        startDate:
                                            (data['startDate'] as Timestamp)
                                                .toDate(),
                                        active: v,
                                      );
                                  setState(() {});
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _openAdd(edit: doc),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                onPressed: () => _confirmDelete(doc),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
