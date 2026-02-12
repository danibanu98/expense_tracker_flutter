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
  final CollectionReference recurringTransactions = FirebaseFirestore.instance
      .collection('recurring_transactions');

  DateTime _addMonthsStable(DateTime date, int monthsToAdd) {
    final year = date.year + ((date.month - 1 + monthsToAdd) ~/ 12);
    final month = ((date.month - 1 + monthsToAdd) % 12) + 1;
    final lastDayOfTargetMonth = DateTime(year, month + 1, 0).day;
    final day = date.day > lastDayOfTargetMonth
        ? lastDayOfTargetMonth
        : date.day;
    return DateTime(
      year,
      month,
      day,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  DateTime _addRecurringInterval({
    required DateTime from,
    required String frequency,
    required int interval,
  }) {
    final safeInterval = interval <= 0 ? 1 : interval;
    switch (frequency) {
      case 'daily':
        return from.add(Duration(days: safeInterval));
      case 'weekly':
        return from.add(Duration(days: 7 * safeInterval));
      case 'monthly':
        return _addMonthsStable(from, safeInterval);
      case 'yearly':
        return _addMonthsStable(from, 12 * safeInterval);
      default:
        return from.add(Duration(days: 30 * safeInterval));
    }
  }

  Future<String> _getHouseholdIdOrThrow() async {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('Utilizator nelogat.');
    }
    final userDoc = await users.doc(userId).get();
    if (!userDoc.exists) {
      throw Exception('Utilizator inexistent.');
    }
    return userDoc.get('householdId');
  }

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
    final String userId = userCredential.user?.uid ?? '';
    if (userId.isEmpty) {
      throw Exception('ID utilizator invalid');
    }

    String householdId;
    String finalInviteCode;

    // Dacă utilizatorul a furnizat un cod de invitație, încearcă să se alăture unui household existent
    if (inviteCode.trim().isNotEmpty) {
      // Caută household-ul cu acest cod de invitație
      final householdQuery = await households
          .where('inviteCode', isEqualTo: inviteCode.trim().toUpperCase())
          .limit(1)
          .get();

      if (householdQuery.docs.isEmpty) {
        throw Exception('Cod de invitație invalid!');
      }

      // Găsim household-ul existent
      final householdDoc = householdQuery.docs.first;
      householdId = householdDoc.id;
      finalInviteCode =
          householdDoc.get('inviteCode') ?? inviteCode.trim().toUpperCase();
    } else {
      // Dacă nu există cod de invitație, creează un household nou
      finalInviteCode = randomAlphaNumeric(
        6,
      ).toUpperCase(); // Generează cod de 6 caractere

      final householdRef = households.doc();
      householdId = householdRef.id;

      await householdRef.set({
        'name': 'Gospodăria lui $name',
        'inviteCode': finalInviteCode,
        'createdAt': Timestamp.now(),
        'createdBy': userId,
      });
    }

    // Creează documentul utilizatorului
    await users.doc(userId).set({
      'name': name,
      'email': userCredential.user?.email ?? '',
      'householdId': householdId,
      'createdAt': Timestamp.now(),
    });
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

  // ---------------------------------------------------------------------------
  // TRANZACȚII RECURENTE (plăți/venituri)
  // ---------------------------------------------------------------------------

  Stream<QuerySnapshot> getRecurringTransactionsStream() {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.empty();

    return users
        .doc(userId)
        .snapshots()
        .asyncMap((userDoc) {
          if (!userDoc.exists) return Stream<QuerySnapshot>.empty();
          final String householdId = userDoc.get('householdId');
          // Fără orderBy ca să nu fie nevoie de index compus; sortare în UI.
          return recurringTransactions
              .where('householdId', isEqualTo: householdId)
              .snapshots();
        })
        .asyncExpand((stream) => stream);
  }

  Future<void> addRecurringTransaction({
    required String description,
    required double amount,
    required String type, // expense/income
    required String accountId,
    required String category,
    required String frequency, // daily/weekly/monthly/yearly
    required int interval,
    required DateTime startDate,
    bool active = true,
  }) async {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('Utilizator nelogat.');
    final householdId = await _getHouseholdIdOrThrow();

    final docRef = recurringTransactions.doc();
    await docRef.set({
      'description': description,
      'amount': amount,
      'type': type,
      'accountId': accountId,
      'category': category,
      'frequency': frequency,
      'interval': interval <= 0 ? 1 : interval,
      'startDate': Timestamp.fromDate(startDate),
      'nextRunAt': Timestamp.fromDate(startDate),
      'lastRunAt': null,
      'active': active,
      'uid': userId,
      'householdId': householdId,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> updateRecurringTransaction({
    required String recurringId,
    required String description,
    required double amount,
    required String type,
    required String accountId,
    required String category,
    required String frequency,
    required int interval,
    required DateTime startDate,
    required bool active,
  }) async {
    final docRef = recurringTransactions.doc(recurringId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) throw Exception('Tranzacția recurentă nu există.');

    final data = snapshot.data() as Map<String, dynamic>;
    final Timestamp? lastRunTs = data['lastRunAt'];
    final DateTime? lastRunAt = lastRunTs?.toDate();
    final now = DateTime.now();

    DateTime nextRunAt;
    if (lastRunAt == null) {
      nextRunAt = startDate;
    } else {
      nextRunAt = _addRecurringInterval(
        from: lastRunAt,
        frequency: frequency,
        interval: interval,
      );
      // dacă noul startDate e în viitor, respectă-l ca limită minimă
      if (startDate.isAfter(nextRunAt)) nextRunAt = startDate;
    }
    // dacă nextRunAt e mult în trecut, îl lăsăm așa; runDue îl va procesa
    if (nextRunAt.isAfter(now.add(const Duration(days: 3650)))) {
      // sanity: evită date absurde
      nextRunAt = now;
    }

    await docRef.update({
      'description': description,
      'amount': amount,
      'type': type,
      'accountId': accountId,
      'category': category,
      'frequency': frequency,
      'interval': interval <= 0 ? 1 : interval,
      'startDate': Timestamp.fromDate(startDate),
      'nextRunAt': Timestamp.fromDate(nextRunAt),
      'active': active,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> deleteRecurringTransaction(String recurringId) async {
    await recurringTransactions.doc(recurringId).delete();
  }

  /// Rulează tranzacțiile recurente „due” și creează tranzacții normale în `expenses`,
  /// actualizând balanțele conturilor. Este idempotent prin `nextRunAt`.
  Future<void> runDueRecurringTransactions({int maxRunsPerItem = 24}) async {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final householdId = await _getHouseholdIdOrThrow();
    final now = DateTime.now();

    // Query: active + householdId. Filtrarea pe nextRunAt <= now o facem în cod
    // pentru a evita indecși/limitări de query combinate.
    final query = await recurringTransactions
        .where('householdId', isEqualTo: householdId)
        .where('active', isEqualTo: true)
        .get();

    for (final doc in query.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final Timestamp? nextTs = data['nextRunAt'];
      if (nextTs == null) continue;

      DateTime nextRunAt = nextTs.toDate();
      final String frequency = (data['frequency'] ?? 'monthly') as String;
      final int interval = (data['interval'] ?? 1) as int;

      int runs = 0;
      while (!nextRunAt.isAfter(now) && runs < maxRunsPerItem) {
        runs++;
        await _applyRecurringOccurrence(
          recurringId: doc.id,
          occurrenceDate: nextRunAt,
        );

        nextRunAt = _addRecurringInterval(
          from: nextRunAt,
          frequency: frequency,
          interval: interval,
        );
      }
    }
  }

  Future<void> _applyRecurringOccurrence({
    required String recurringId,
    required DateTime occurrenceDate,
  }) async {
    final recurringRef = recurringTransactions.doc(recurringId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final recurringSnap = await tx.get(recurringRef);
      if (!recurringSnap.exists) return;
      final recurring = recurringSnap.data() as Map<String, dynamic>;

      if (recurring['active'] != true) return;

      final Timestamp? nextTs = recurring['nextRunAt'];
      if (nextTs == null) return;
      final currentNextRunAt = nextTs.toDate();
      // Protecție contra dublării: rulează doar dacă exact aceasta e scadența curentă
      if (currentNextRunAt.compareTo(occurrenceDate) != 0) return;

      final String accountId = recurring['accountId'] as String;
      final String type = (recurring['type'] ?? 'expense') as String;
      final double amount = (recurring['amount'] ?? 0.0).toDouble();
      final String description = (recurring['description'] ?? '') as String;
      final String category = (recurring['category'] ?? 'Altele') as String;
      final String frequency = (recurring['frequency'] ?? 'monthly') as String;
      final int interval = (recurring['interval'] ?? 1) as int;
      final String? uid = recurring['uid'] as String?;
      final String householdId = recurring['householdId'] as String;

      final accountRef = accounts.doc(accountId);
      final accountSnap = await tx.get(accountRef);
      if (!accountSnap.exists) {
        throw Exception('Contul pentru recurent nu a fost găsit.');
      }

      double currentBalance =
          (accountSnap.data() as Map<String, dynamic>)['balance'] ?? 0.0;
      final double newBalance = type == 'income'
          ? (currentBalance + amount)
          : (currentBalance - amount);

      final expenseRef = expenses.doc();
      tx.set(expenseRef, {
        'description': description,
        'amount': amount,
        'type': type,
        'timestamp': Timestamp.fromDate(occurrenceDate),
        'uid': uid,
        'householdId': householdId,
        'accountId': accountId,
        'category': category,
        'recurringId': recurringId, // link pentru trasabilitate
      });

      tx.update(accountRef, {'balance': newBalance});

      final nextRunAt = _addRecurringInterval(
        from: occurrenceDate,
        frequency: frequency,
        interval: interval,
      );
      tx.update(recurringRef, {
        'lastRunAt': Timestamp.fromDate(occurrenceDate),
        'nextRunAt': Timestamp.fromDate(nextRunAt),
        'updatedAt': Timestamp.now(),
      });
    });
  }
}
