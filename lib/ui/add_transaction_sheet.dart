import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_nou/providers/settings_provider.dart';
import 'package:expense_tracker_nou/services/firestore_service.dart';
import 'package:expense_tracker_nou/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AddTransactionSheet extends StatefulWidget {
  // Parametri opționali pentru modul EDITARE
  final String? transactionId;
  final Map<String, dynamic>? transactionData;

  const AddTransactionSheet({
    super.key,
    this.transactionId,
    this.transactionData,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _selectedType = 'expense';

  final FirestoreService _firestoreService = FirestoreService();
  String? _selectedAccountId;
  List<QueryDocumentSnapshot> _accounts = [];
  bool _isLoadingAccounts = true;

  final List<String> _expenseCategories = [
    'Mâncare',
    'Transport',
    'Facturi',
    'Timp Liber',
    'Cumpărături',
    'Altul',
  ];
  final List<String> _incomeCategories = ['Salariu', 'Bonus', 'Cadou', 'Altul'];
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  bool get _isEditing =>
      widget.transactionId != null; // Helper pentru a ști modul

  @override
  void initState() {
    super.initState();
    _loadAccounts();

    // --- LOGICA DE INIȚIALIZARE (EDIT VS NEW) ---
    if (_isEditing) {
      // Suntem în modul EDITARE: Pre-completăm câmpurile
      final data = widget.transactionData!;
      _descriptionController.text = data['description'] ?? '';
      _amountController.text = (data['amount'] ?? 0.0).toString();
      _selectedType = data['type'] ?? 'expense';
      _selectedCategory = data['category'];
      _selectedAccountId = data['accountId']; // Contul original

      Timestamp timestamp = data['timestamp'] ?? Timestamp.now();
      _selectedDate = timestamp.toDate();
    } else {
      // Suntem în modul ADAUGARE: Valori implicite
      _selectedCategory = _expenseCategories.first;
    }
  }

  Future<void> _loadAccounts() async {
    try {
      var accountsList = await _firestoreService.getAccountsList();
      setState(() {
        _accounts = accountsList;
        _isLoadingAccounts = false;
      });
    } catch (e) {
      print("Eroare la încărcarea conturilor: $e");
      setState(() {
        _isLoadingAccounts = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _saveTransaction() async {
    final description = _descriptionController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    if (description.isEmpty ||
        amount <= 0 ||
        _selectedAccountId == null ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Completează toate câmpurile corect.')),
      );
      return;
    }

    try {
      if (_isEditing) {
        // --- APELĂM UPDATE ---
        await _firestoreService.updateTransaction(
          widget.transactionId!,
          description,
          amount,
          _selectedType,
          _selectedCategory!,
          _selectedDate,
          // Notă: Nu trimitem accountId pentru că nu schimbăm contul la editare
        );
        // Întoarce un rezultat 'true' pentru a anunța pagina anterioară să se actualizeze
        if (mounted) Navigator.of(context).pop(true);
      } else {
        // --- APELĂM ADD ---
        await _firestoreService.addTransaction(
          description,
          amount,
          _selectedType,
          _selectedAccountId!,
          _selectedCategory!,
          _selectedDate,
        );
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      print('Eroare la salvare: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Eroare la salvare: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    return Scaffold(
      body: Stack(
        children: [
          // --- 1. FUNDALUL VERDE (VALUL) ---
          ClipPath(
            clipper: _TopCurveClipper(),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.45,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    'assets/images/fundal.png',
                  ), // Asigură-te că ai imaginea
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
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Text(
                        _isEditing
                            ? 'Editează Tranzacția'
                            : (_selectedType == 'expense'
                                  ? 'Adaugă Cheltuială'
                                  : 'Adaugă Venit'),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 48), // Spacer pentru centrare
                    ],
                  ),
                ),
                SizedBox(height: 60),

                // --- B. CARDUL ALB (FORMULARUL) ---
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Toggle Buttons
                          Center(
                            child: ToggleButtons(
                              isSelected: [
                                _selectedType == 'expense',
                                _selectedType == 'income',
                              ],
                              onPressed: (index) {
                                setState(() {
                                  _selectedType = index == 0
                                      ? 'expense'
                                      : 'income';
                                  _selectedCategory = _selectedType == 'expense'
                                      ? _expenseCategories.first
                                      : _incomeCategories.first;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              selectedColor: Colors.white,
                              fillColor: _selectedType == 'expense'
                                  ? Colors.red[400]
                                  : Colors.green[400],
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: Text('Cheltuială'),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: Text('Venit'),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 30),

                          // 1. Categoria
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            hint: Text('Selectează Categoria'),
                            decoration: InputDecoration(
                              labelText: 'Categorie',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items:
                                (_selectedType == 'expense'
                                        ? _expenseCategories
                                        : _incomeCategories)
                                    .map(
                                      (category) => DropdownMenuItem(
                                        value: category,
                                        child: Text(category),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) =>
                                setState(() => _selectedCategory = value),
                          ),
                          SizedBox(height: 20),

                          // 2. Suma
                          TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _selectedType == 'expense'
                                  ? Colors.red[400]
                                  : Colors.green[400],
                            ),
                            decoration: InputDecoration(
                              labelText: 'Sumă',
                              prefixText: settings.currencySymbol,
                              prefixStyle: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              hintText: '0.00',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),

                          // 3. Contul (Dezactivat la Editare)
                          if (_isLoadingAccounts)
                            Center(child: CircularProgressIndicator())
                          else
                            IgnorePointer(
                              // <-- Blochează interacțiunea dacă e editare
                              ignoring: _isEditing,
                              child: Opacity(
                                // <-- Îl face puțin transparent ca să arate dezactivat
                                opacity: _isEditing ? 0.5 : 1.0,
                                child: DropdownButtonFormField<String>(
                                  value: _selectedAccountId,
                                  hint: Text('Selectează Contul'),
                                  decoration: InputDecoration(
                                    labelText:
                                        'Cont ' +
                                        (_isEditing
                                            ? '(Nu poate fi schimbat)'
                                            : ''),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items: _accounts.map((doc) {
                                    var account =
                                        doc.data() as Map<String, dynamic>;
                                    return DropdownMenuItem(
                                      value: doc.id,
                                      child: Text(
                                        account['name'] ?? 'Cont Fără Nume',
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) => setState(
                                    () => _selectedAccountId = value,
                                  ),
                                ),
                              ),
                            ),
                          SizedBox(height: 20),

                          // 4. Descrierea
                          TextField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: 'Descriere',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),

                          // 5. Data
                          InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Dată',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            child: TextButton(
                              onPressed: () => _selectDate(context),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    DateFormat(
                                      'EEE, d MMM yyyy',
                                      'ro',
                                    ).format(_selectedDate),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 30),

                          // Butonul de Salvare
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveTransaction,
                              child: Text(
                                _isEditing ? 'Actualizează' : 'Salvează',
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Clasa Clipper (aceeași)
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
