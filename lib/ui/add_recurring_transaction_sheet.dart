import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_nou/providers/settings_provider.dart';
import 'package:expense_tracker_nou/services/firestore_service.dart';
import 'package:expense_tracker_nou/utils/validators.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AddRecurringTransactionSheet extends StatefulWidget {
  final DocumentSnapshot? recurringToEdit;

  const AddRecurringTransactionSheet({super.key, this.recurringToEdit});

  @override
  State<AddRecurringTransactionSheet> createState() =>
      _AddRecurringTransactionSheetState();
}

class _AddRecurringTransactionSheetState
    extends State<AddRecurringTransactionSheet> {
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  String _selectedType = 'expense';
  String? _selectedAccountId;
  String? _selectedCategory;
  bool _active = true;

  String _frequency = 'monthly'; // daily/weekly/monthly/yearly
  int _interval = 1;
  DateTime _startDate = DateTime.now();

  List<QueryDocumentSnapshot> _accounts = [];
  bool _isLoadingAccounts = true;

  final List<String> _expenseCategories = [
    'Mâncare & Supermarket', // Lidl, Kaufland, Carrefour
    'Restaurante & Livrări', // Glovo, Tazz, Starbucks, McDonald's
    'Transport & Auto', // Uber, Bolt, OMV, Petrom, Rompetrol, RCA
    'Locuință & Utilități', // Digi, Enel, E.ON, Orange, Chirie
    'Cumpărături & Fashion', // Zara, H&M, Decathlon, Haine
    'Electronice & Electro', // eMAG, Altex, Flanco, Hardware PC
    'Divertisment & Abonamente', // Netflix, YouTube, Spotify, Cinema
    'Sănătate & Farmacie', // NN Asigurări, Farmacii, Dentist
    'Financiar & Taxe', // BT (Rata), Revolut, Comisioane
    'Educație & Cărți', // Cursuri, Cărți
    'Vacanțe & Călătorii', // Hoteluri, Bilete avion
    'Cadouri & Donații', // Cadouri
    'Altele',
  ];
  final List<String> _incomeCategories = [
    'Salariu',
    'Bonus & Prime',
    'Freelancing', // Activități independente
    'Investiții & Dividende', // Bursă, Dobânzi
    'Chirii & Imobiliare', // Dacă încasezi chirie
    'Cadouri & Restituiri', // Bani primiți sau returnați
    'Alocații & Ajutoare', // De la stat sau familie
    'Altele',
  ];

  bool get _isEditing => widget.recurringToEdit != null;

  @override
  void initState() {
    super.initState();
    _loadAccounts();

    if (_isEditing) {
      final data = widget.recurringToEdit!.data() as Map<String, dynamic>;
      _descriptionController.text = (data['description'] ?? '').toString();
      _amountController.text = (data['amount'] ?? 0.0).toString();
      _selectedType = (data['type'] ?? 'expense').toString();
      _selectedAccountId = data['accountId']?.toString();
      _selectedCategory = data['category']?.toString();
      _active = (data['active'] ?? true) == true;

      _frequency = (data['frequency'] ?? 'monthly').toString();
      _interval = (data['interval'] ?? 1) as int;

      final Timestamp? startTs = data['startDate'];
      if (startTs != null) _startDate = startTs.toDate();
    } else {
      _selectedCategory = _expenseCategories.first;
    }
  }

  Future<void> _loadAccounts() async {
    try {
      final accountsList = await _firestoreService.getAccountsList();
      if (!mounted) return;
      setState(() {
        _accounts = accountsList;
        _isLoadingAccounts = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Eroare la încărcarea conturilor: $e');
      if (!mounted) return;
      setState(() => _isLoadingAccounts = false);
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && mounted) {
      setState(() => _startDate = picked);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final description = _descriptionController.text.trim();
    final amountStr = _amountController.text.trim();

    final descErr = Validators.required(description, 'Descrierea');
    if (descErr != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(descErr)));
      return;
    }
    final amtErr = Validators.amount(amountStr);
    if (amtErr != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(amtErr)));
      return;
    }
    if (_selectedAccountId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selectează un cont.')));
      return;
    }
    if (_selectedCategory == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selectează o categorie.')));
      return;
    }

    final amount = double.parse(amountStr.replaceAll(',', '.'));

    try {
      if (_isEditing) {
        await _firestoreService.updateRecurringTransaction(
          recurringId: widget.recurringToEdit!.id,
          description: description,
          amount: amount,
          type: _selectedType,
          accountId: _selectedAccountId!,
          category: _selectedCategory!,
          frequency: _frequency,
          interval: _interval,
          startDate: _startDate,
          active: _active,
        );
      } else {
        await _firestoreService.addRecurringTransaction(
          description: description,
          amount: amount,
          type: _selectedType,
          accountId: _selectedAccountId!,
          category: _selectedCategory!,
          frequency: _frequency,
          interval: _interval,
          startDate: _startDate,
          active: _active,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Eroare: $e')));
    }
  }

  String _freqLabel(String freq) {
    switch (freq) {
      case 'daily':
        return 'Zilnic';
      case 'weekly':
        return 'Săptămânal';
      case 'monthly':
        return 'Lunar';
      case 'yearly':
        return 'Anual';
      default:
        return freq;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    final categories = _selectedType == 'expense'
        ? _expenseCategories
        : _incomeCategories;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing ? 'Editează Recurrența' : 'Adaugă Recurrență',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Switch(
                    value: _active,
                    onChanged: (v) => setState(() => _active = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tip (Cheltuială/Venit)
              Center(
                child: ToggleButtons(
                  isSelected: [
                    _selectedType == 'expense',
                    _selectedType == 'income',
                  ],
                  onPressed: (index) {
                    setState(() {
                      _selectedType = index == 0 ? 'expense' : 'income';
                      _selectedCategory = _selectedType == 'expense'
                          ? _expenseCategories.first
                          : _incomeCategories.first;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  selectedColor: Colors.white,
                  fillColor: _selectedType == 'expense'
                      ? const Color(0xff7b0828)
                      : const Color(0xff2f7e79),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Cheltuială'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Venit'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Categorie',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Sumă',
                  prefixText: settings.currencySymbol,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              if (_isLoadingAccounts)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: _selectedAccountId,
                  decoration: InputDecoration(
                    labelText: 'Cont',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _accounts.map((doc) {
                    final a = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(a['name'] ?? 'Cont'),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedAccountId = v),
                ),
              const SizedBox(height: 12),

              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descriere',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _frequency,
                      decoration: InputDecoration(
                        labelText: 'Frecvență',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'daily', child: Text('Zilnic')),
                        DropdownMenuItem(
                          value: 'weekly',
                          child: Text('Săptămânal'),
                        ),
                        DropdownMenuItem(
                          value: 'monthly',
                          child: Text('Lunar'),
                        ),
                        DropdownMenuItem(value: 'yearly', child: Text('Anual')),
                      ],
                      onChanged: (v) =>
                          setState(() => _frequency = v ?? 'monthly'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 120,
                    child: DropdownButtonFormField<int>(
                      initialValue: _interval,
                      decoration: InputDecoration(
                        labelText: 'La fiecare',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: List.generate(12, (i) => i + 1)
                          .map(
                            (v) =>
                                DropdownMenuItem(value: v, child: Text('$v')),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _interval = v ?? 1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Data de start',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: TextButton(
                  onPressed: _pickStartDate,
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 10),
                      Text(DateFormat('d MMM yyyy', 'ro').format(_startDate)),
                      const Spacer(),
                      Text(_freqLabel(_frequency)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(_isEditing ? 'Actualizează' : 'Salvează'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
