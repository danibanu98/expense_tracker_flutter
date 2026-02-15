import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_nou/providers/settings_provider.dart';
import 'package:expense_tracker_nou/services/firestore_service.dart';
import 'package:expense_tracker_nou/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker_nou/services/brand_service.dart';

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
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  bool get _isEditing =>
      widget.transactionId != null; // Helper pentru a ști modul

  @override
  void initState() {
    super.initState();
    _loadAccounts();

    if (_isEditing) {
      // --- MOD DE EDITARE ---
      final data = widget.transactionData!;

      _descriptionController.text = data['description'] ?? '';
      _amountController.text = (data['amount'] ?? 0.0).toString();
      _selectedType = data['type'] ?? 'expense';

      // Aici e problema: categoria salvată în baza de date (ex: "Locuință")
      String savedCategory = data['category'];

      // 1. Verificăm și REPARĂM lista dacă lipsește categoria veche
      if (_selectedType == 'expense') {
        // Dacă categoria salvată NU e în lista nouă de cheltuieli...
        if (!_expenseCategories.contains(savedCategory)) {
          // ...o adăugăm temporar la finalul listei!
          setState(() {
            _expenseCategories.add(savedCategory);
          });
        }
      } else {
        // La fel pentru venituri
        if (!_incomeCategories.contains(savedCategory)) {
          setState(() {
            _incomeCategories.add(savedCategory);
          });
        }
      }

      // Acum putem selecta liniștiți categoria, știind sigur că există în listă
      _selectedCategory = savedCategory;

      _selectedAccountId = data['accountId'];
      Timestamp timestamp = data['timestamp'] ?? Timestamp.now();
      _selectedDate = timestamp.toDate();
    } else {
      // --- MOD DE ADĂUGARE NOUĂ ---
      // Aici nu avem riscuri, luăm pur și simplu prima din listă
      _selectedCategory = _selectedType == 'expense'
          ? _expenseCategories.first
          : _incomeCategories.first;
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
      if (kDebugMode) {
        debugPrint("Eroare la încărcarea conturilor: $e");
      }
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
    final amountStr = _amountController.text.trim();

    final descError = Validators.required(description, 'Descrierea');
    if (descError != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(descError)));
      return;
    }
    final amountError = Validators.amount(amountStr);
    if (amountError != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(amountError)));
      return;
    }
    if (_selectedAccountId == null || _selectedCategory == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selectează contul și categoria.')),
      );
      return;
    }

    final amount = double.parse(amountStr.replaceAll(',', '.'));

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
      if (!mounted) return;
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
                SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          _isEditing
                              ? 'Editează Tranzacția'
                              : (_selectedType == 'expense'
                                    ? 'Adaugă Cheltuială'
                                    : 'Adaugă Venit'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Spacer pentru centrare
                    ],
                  ),
                ),
                SizedBox(height: 40),

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
                            color: Colors.black.withValues(alpha: 0.05),
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
                                  ? const Color(0xff7b0828)
                                  : const Color(0xff2f7e79),
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

                          // 1. Descrierea cu Autocomplete
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return Autocomplete<String>(
                                initialValue: TextEditingValue(
                                  text: _descriptionController.text,
                                ),

                                // A. LOGICA DE FILTRARE
                                optionsBuilder:
                                    (TextEditingValue textEditingValue) {
                                      if (textEditingValue.text.isEmpty) {
                                        return const Iterable<String>.empty();
                                      }
                                      // Filtrăm lista din BrandService
                                      return BrandService.knownBrands.where((
                                        String option,
                                      ) {
                                        // MODIFICARE AICI:
                                        // Transformăm ambele în litere mici pentru comparație
                                        return option.toLowerCase().contains(
                                          textEditingValue.text.toLowerCase(),
                                        );
                                      });
                                    },

                                // B. CAND SE SELECTEAZĂ O OPȚIUNE
                                onSelected: (String selection) {
                                  _descriptionController.text = selection;
                                  // Opțional: Poți selecta automat și categoria dacă vrei
                                  // if (selection == 'netflix') setState(() => _selectedCategory = 'Viață & Divertisment');
                                },

                                // C. CÂMPUL DE TEXT (DESIGN-UL TĂU VECHI)
                                fieldViewBuilder:
                                    (
                                      context,
                                      fieldTextEditingController,
                                      fieldFocusNode,
                                      onFieldSubmitted,
                                    ) {
                                      // Sincronizăm controller-ul tău principal cu cel din Autocomplete
                                      // Astfel, dacă scrie ceva și NU selectează din listă, tot se salvează.
                                      fieldTextEditingController.addListener(
                                        () {
                                          _descriptionController.text =
                                              fieldTextEditingController.text;
                                        },
                                      );

                                      // IMPORTANT: Dacă suntem în modul editare și e prima randare,
                                      // ne asigurăm că textul apare în câmp.
                                      if (_descriptionController
                                              .text
                                              .isNotEmpty &&
                                          fieldTextEditingController
                                              .text
                                              .isEmpty) {
                                        fieldTextEditingController.text =
                                            _descriptionController.text;
                                      }

                                      return TextField(
                                        controller: fieldTextEditingController,
                                        focusNode: fieldFocusNode,
                                        decoration: InputDecoration(
                                          labelText: 'Descriere',
                                          hintText: 'ex: Lidl, Netflix...',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      );
                                    },

                                // D. LISTA DE SUGESTII (CUSTOM UI)
                                optionsViewBuilder: (context, onSelected, options) {
                                  return Align(
                                    alignment: Alignment.topLeft,
                                    child: Material(
                                      elevation: 4.0,
                                      borderRadius: BorderRadius.circular(12),
                                      // Folosim constraints de la LayoutBuilder pentru a avea lățimea corectă
                                      child: Container(
                                        width: constraints.maxWidth,
                                        color: Theme.of(context).cardColor,
                                        constraints: const BoxConstraints(
                                          maxHeight: 200,
                                        ),
                                        child: ListView.builder(
                                          padding: EdgeInsets.zero,
                                          shrinkWrap: true,
                                          itemCount: options.length,
                                          itemBuilder: (BuildContext context, int index) {
                                            final String option = options
                                                .elementAt(index);
                                            final String? assetPath =
                                                BrandService.getAssetPathForBrand(
                                                  option,
                                                );

                                            return ListTile(
                                              leading: assetPath != null
                                                  ? Container(
                                                      width: 30,
                                                      height: 30,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        image: DecorationImage(
                                                          image: AssetImage(
                                                            assetPath,
                                                          ),
                                                          fit: BoxFit.contain,
                                                        ),
                                                      ),
                                                    )
                                                  : const Icon(
                                                      Icons.store,
                                                      size: 20,
                                                    ),
                                              title: Text(
                                                option.toUpperCase(),
                                              ), // Stilizează cum vrei
                                              onTap: () {
                                                onSelected(option);
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          SizedBox(height: 20),

                          // 2. Suma
                          TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            // Stilul pentru textul pe care îl scrie utilizatorul
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _selectedType == 'expense'
                                  ? const Color(0xff7b0828)
                                  : const Color(0xff2f7e79),
                            ),
                            decoration: InputDecoration(
                              labelText: 'Sumă',

                              // --- AICI ESTE MODIFICAREA ---
                              // hintStyle controlează culoarea textului "0.00 RON" când câmpul e gol
                              hintStyle: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _selectedType == 'expense'
                                    ? const Color(0xff7b0828)
                                    : const Color(0xff2f7e79),
                              ),

                              // -----------------------------
                              prefixStyle: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              hintText: '0.00 ${settings.currencySymbol}',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

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
                                  initialValue: _selectedAccountId,
                                  hint: Text('Selectează Contul'),
                                  decoration: InputDecoration(
                                    labelText:
                                        'Cont ${_isEditing ? '(Nu poate fi schimbat)' : ''}',
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

                          // 4. Categoria
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCategory,
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
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _isEditing ? 'Actualizează' : 'Salvează',
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
