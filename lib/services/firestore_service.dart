import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:random_string/random_string.dart';

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

  // --- FUNCȚIA DE ADĂUGARE TRANZACȚIE (COREctată) ---
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
    if (!userDoc.exists) {
      throw Exception("Utilizatorul nu are un document.");
    }
    final String householdId = userDoc.get('householdId');

    DocumentReference accountRef = accounts.doc(accountId);
    DocumentReference transactionRef = expenses
        .doc(); // Firestore generează un ID nou

    // *** CORECTURA: Am înlocuit 'return' cu 'await' ***
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // 1. Citește starea curentă a contului
      DocumentSnapshot accountSnapshot = await transaction.get(accountRef);
      if (!accountSnapshot.exists) {
        throw Exception("Contul nu a fost găsit!");
      }

      // 2. Calculează noua balanță
      double currentBalance =
          (accountSnapshot.data() as Map<String, dynamic>)['balance'] ?? 0.0;
      double newBalance;
      if (type == 'income') {
        newBalance = currentBalance + amount;
      } else {
        newBalance = currentBalance - amount;
      }

      // 3. Scrie noua tranzacție
      transaction.set(transactionRef, {
        'description': description,
        'amount': amount,
        'type': type,
        'timestamp': Timestamp.fromDate(selectedDate),
        'uid': userId,
        'householdId': householdId,
        'accountId': accountId,
        'category': category, // <-- AM ADĂUGAT NOUL CÂMP!
      });

      // 4. Actualizează balanța contului
      transaction.update(accountRef, {'balance': newBalance});
    });
  }

  // --- FUNCȚIA DE ȘTERGERE (COREctată) ---
  Future<void> deleteExpense(String docId) async {
    DocumentReference transactionRef = expenses.doc(docId);

    // *** CORECTURA: Am înlocuit 'return' cu 'await' ***
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // 1. Citește tranzacția
      DocumentSnapshot transactionSnapshot = await transaction.get(
        transactionRef,
      );
      if (!transactionSnapshot.exists) {
        throw Exception("Tranzacția nu a fost găsită!");
      }

      var data = transactionSnapshot.data() as Map<String, dynamic>;
      String accountId = data['accountId'];
      double amount = data['amount'];
      String type = data['type'];

      // 2. Găsește referința la cont
      DocumentReference accountRef = accounts.doc(accountId);

      // 3. Citește contul
      DocumentSnapshot accountSnapshot = await transaction.get(accountRef);
      if (accountSnapshot.exists) {
        // 4. Calculează "rambursarea"
        double currentBalance =
            (accountSnapshot.data() as Map<String, dynamic>)['balance'] ?? 0.0;
        double newBalance;
        if (type == 'income') {
          newBalance = currentBalance - amount;
        } else {
          newBalance = currentBalance + amount;
        }
        // 5. Actualizează balanța
        transaction.update(accountRef, {'balance': newBalance});
      }

      // 6. Șterge tranzacția
      transaction.delete(transactionRef);
    });
  }

  // --- FUNCȚIA LIPSĂ: 'getExpensesStream' (PENTRU HOME ȘI STATISTICS) ---
  Stream<QuerySnapshot> getExpensesStream() {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Stream.empty();
    }

    return users
        .doc(userId)
        .snapshots()
        .asyncMap((userDoc) {
          if (!userDoc.exists) {
            return Stream<QuerySnapshot>.empty();
          }
          final String householdId = userDoc.get('householdId');

          return expenses
              .where('householdId', isEqualTo: householdId)
              .orderBy('timestamp', descending: true)
              .snapshots();
        })
        .asyncExpand((stream) => stream);
  }

  // --- FUNCȚIA DE CREARE UTILIZATOR (OK) ---
  // --- FUNCȚIE COMPLET RESCRISĂ ---
  Future<void> createUserDocument(
    UserCredential userCredential,
    String name,
    String inviteCode,
  ) async {
    if (userCredential.user == null) return;

    String householdId;

    // CAZUL 1: Utilizatorul ARE un cod de invitație
    if (inviteCode.isNotEmpty) {
      // Caută gospodăria care are acest cod
      var query = await households
          .where('inviteCode', isEqualTo: inviteCode)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        // Am găsit-o! Ne alăturăm gospodăriei existente
        householdId = query.docs.first.id;
      } else {
        // Codul este greșit
        throw Exception('Codul de invitație nu este valid.');
      }
    }
    // CAZUL 2: Utilizatorul NU are cod (creează o gospodărie nouă)
    else {
      // Generează un cod de invitație unic de 6 caractere
      String newInviteCode = randomAlphaNumeric(6).toUpperCase();

      // Creează un document nou în 'households'
      DocumentReference householdDoc = await households.add({
        'name': '$name\'s Household', // ex: "Daniel's Household"
        'ownerUid': userCredential.user!.uid, // El este proprietarul
        'inviteCode': newInviteCode,
      });

      // Folosim ID-ul noii gospodării
      householdId = householdDoc.id;
    }

    // La final, creăm documentul 'user' și îl legăm de gospodărie
    await users.doc(userCredential.user!.uid).set({
      'uid': userCredential.user!.uid,
      'email': userCredential.user!.email,
      'name': name,
      'householdId': householdId, // ID-ul (nou sau existent)
    });
  }

  // --- FUNCȚIA DE ADĂUGARE CONT (OK) ---
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

  // --- NOU: Funcția de EDITARE CONT ---
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

  // --- FUNCȚIA DE CITIRE CONTURI (OK) ---
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

  // --- FUNCȚIE NOUĂ, EFICIENTĂ, PENTRU O SINGURĂ CITIRE A CONTURILOR ---
  Future<List<QueryDocumentSnapshot>> getAccountsList() async {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('Utilizator nelogat.');
    }

    try {
      // 1. Citește documentul utilizatorului O SINGURĂ DATĂ
      final userDoc = await users.doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('Utilizatorul nu are un document.');
      }
      final String householdId = userDoc.get('householdId');

      // 2. Citește conturile O SINGURĂ DATĂ
      final querySnapshot = await accounts
          .where('householdId', isEqualTo: householdId)
          .get();

      return querySnapshot.docs; // Returnează lista
    } catch (e) {
      print("Eroare la getAccountsList: $e");
      return []; // Returnează o listă goală în caz de eroare
    }
  }
}
