import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference expenses = FirebaseFirestore.instance.collection(
    'expenses',
  );
  final CollectionReference users = FirebaseFirestore.instance.collection(
    'users',
  );
  final CollectionReference accounts = FirebaseFirestore.instance.collection(
    'accounts',
  );
  final CollectionReference households = FirebaseFirestore.instance.collection(
    'households',
  );

  // --- 1. ADĂUGARE TRANZACȚIE ---
  Future<void> addTransaction(
    String description,
    double amount,
    String type,
    String accountId,
    String category,
    DateTime selectedDate,
  ) async {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    final userDoc = await users.doc(userId).get();
    final String householdId = userDoc.get('householdId');

    DocumentReference accountRef = accounts.doc(accountId);
    DocumentReference transactionRef = expenses.doc();

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot accountSnapshot = await transaction.get(accountRef);
      if (!accountSnapshot.exists) {
        throw Exception("Contul nu a fost găsit!");
      }

      double currentBalance =
          (accountSnapshot.data() as Map<String, dynamic>)['balance'] ?? 0.0;
      double newBalance;
      if (type == 'income') {
        newBalance = currentBalance + amount;
      } else {
        newBalance = currentBalance - amount;
      }

      transaction.set(transactionRef, {
        'description': description,
        'amount': amount,
        'type': type,
        'timestamp': Timestamp.fromDate(selectedDate),
        'uid': userId,
        'householdId': householdId,
        'accountId': accountId,
        'category': category,
      });

      transaction.update(accountRef, {'balance': newBalance});
    });
  }

  // --- 2. ȘTERGERE TRANZACȚIE ---
  Future<void> deleteExpense(String docId) async {
    DocumentReference transactionRef = expenses.doc(docId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot transactionSnapshot = await transaction.get(
        transactionRef,
      );
      if (!transactionSnapshot.exists) return;

      var data = transactionSnapshot.data() as Map<String, dynamic>;
      String accountId = data['accountId'];
      double amount = (data['amount'] ?? 0.0).toDouble();
      String type = data['type'];

      DocumentReference accountRef = accounts.doc(accountId);
      DocumentSnapshot accountSnapshot = await transaction.get(accountRef);

      if (accountSnapshot.exists) {
        double currentBalance =
            (accountSnapshot.data() as Map<String, dynamic>)['balance'] ?? 0.0;
        double newBalance;
        // Inversăm operațiunea
        if (type == 'income') {
          newBalance = currentBalance - amount;
        } else {
          newBalance = currentBalance + amount;
        }
        transaction.update(accountRef, {'balance': newBalance});
      }

      transaction.delete(transactionRef);
    });
  }

  // --- 3. ACTUALIZARE (EDITARE) TRANZACȚIE (NOU) ---
  Future<void> updateTransaction(
    String transactionId,
    String newDescription,
    double newAmount,
    String newType,
    String newCategory,
    DateTime newDate,
    // Notă: Deocamdată nu permitem schimbarea contului la editare pentru simplitate
  ) async {
    DocumentReference transactionRef = expenses.doc(transactionId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // A. Citim tranzacția VECHE
      DocumentSnapshot transactionSnapshot = await transaction.get(
        transactionRef,
      );
      if (!transactionSnapshot.exists) throw Exception("Tranzacția nu există");

      var oldData = transactionSnapshot.data() as Map<String, dynamic>;
      String accountId = oldData['accountId']; // Contul rămâne același
      double oldAmount = (oldData['amount'] ?? 0.0).toDouble();
      String oldType = oldData['type'];

      // B. Citim Contul
      DocumentReference accountRef = accounts.doc(accountId);
      DocumentSnapshot accountSnapshot = await transaction.get(accountRef);
      if (!accountSnapshot.exists) throw Exception("Contul nu mai există");

      double currentBalance =
          (accountSnapshot.data() as Map<String, dynamic>)['balance'] ?? 0.0;

      // C. Recalculăm Balanța
      // 1. Anulăm vechea sumă
      if (oldType == 'income') {
        currentBalance -= oldAmount;
      } else {
        currentBalance += oldAmount;
      }

      // 2. Aplicăm noua sumă
      if (newType == 'income') {
        currentBalance += newAmount;
      } else {
        currentBalance -= newAmount;
      }

      // D. Salvăm modificările
      transaction.update(transactionRef, {
        'description': newDescription,
        'amount': newAmount,
        'type': newType,
        'category': newCategory,
        'timestamp': Timestamp.fromDate(newDate),
      });

      transaction.update(accountRef, {'balance': currentBalance});
    });
  }

  // --- ALTE FUNCȚII ---
  Stream<QuerySnapshot> getExpensesStream() {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.empty();

    return users
        .doc(userId)
        .snapshots()
        .asyncMap((userDoc) {
          if (!userDoc.exists) return Stream<QuerySnapshot>.empty();
          final String householdId = userDoc.get('householdId');

          return expenses
              .where('householdId', isEqualTo: householdId)
              .orderBy('timestamp', descending: true)
              .snapshots();
        })
        .asyncExpand((stream) => stream);
  }

  Future<void> createUserDocument(
    UserCredential userCredential,
    String name,
    String inviteCode,
  ) async {
    // ... (Logica ta de creare user/household rămâne neschimbată, o poți lăsa cum era sau o pot re-scrie dacă vrei) ...
    // Pentru simplitate, am scurtat aici, dar asigură-te că păstrezi logica completă din pașii anteriori dacă ai modificat-o
    // Dacă vrei codul complet și pentru asta, spune-mi.
  }

  // Helper simplu pentru creare user (dacă ai nevoie de el complet, e mai sus în istoric)
  // Dar important e să ai 'addAccount' și 'updateAccount' de mai jos:

  Future<void> addAccount(
    String name,
    double startingBalance,
    String currency,
  ) async {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    final userDoc = await users.doc(userId).get();
    final String householdId = userDoc.get('householdId');

    await accounts.add({
      'name': name,
      'balance': startingBalance,
      'currency': currency,
      'uid': userId,
      'householdId': householdId,
    });
  }

  Future<void> updateAccount(
    String docId,
    String name,
    double balance,
    String currency,
  ) async {
    await accounts.doc(docId).update({
      'name': name,
      'balance': balance,
      'currency': currency,
    });
  }

  Stream<QuerySnapshot> getAccountsStream() {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.empty();

    return users
        .doc(userId)
        .snapshots()
        .asyncMap((userDoc) {
          if (!userDoc.exists) return Stream<QuerySnapshot>.empty();
          final String householdId = userDoc.get('householdId');
          return accounts
              .where('householdId', isEqualTo: householdId)
              .snapshots();
        })
        .asyncExpand((stream) => stream);
  }

  // Funcția rapidă pentru dropdown
  Future<List<QueryDocumentSnapshot>> getAccountsList() async {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('Utilizator nelogat.');
    final userDoc = await users.doc(userId).get();
    final String householdId = userDoc.get('householdId');
    final querySnapshot = await accounts
        .where('householdId', isEqualTo: householdId)
        .get();
    return querySnapshot.docs;
  }

  // --- FUNCȚIE NOUĂ: ȘTERGE CONT + TRANZACȚIILE LUI ---
  Future<void> deleteAccount(String accountId) async {
    // 1. Găsește toate tranzacțiile legate de acest cont
    final transactionsQuery = await expenses
        .where('accountId', isEqualTo: accountId)
        .get();

    // 2. Pornește un Batch (grup de operațiuni)
    WriteBatch batch = FirebaseFirestore.instance.batch();

    // 3. Adaugă ștergerea fiecărei tranzacții în batch
    for (var doc in transactionsQuery.docs) {
      batch.delete(doc.reference);
    }

    // 4. Adaugă ștergerea contului în batch
    batch.delete(accounts.doc(accountId));

    // 5. Execută totul deodată
    await batch.commit();
  }
}
