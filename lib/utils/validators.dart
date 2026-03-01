/// Validatori reutilizabili pentru email, sume, cod invitație.
class Validators {
  Validators._();

  /// Regex pentru email (format simplu, suficient pentru majoritatea cazurilor).
  static final RegExp _emailRegex = RegExp(
    r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
  );

  /// Validează email. Returnează mesaj de eroare sau null dacă e valid.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email-ul este obligatoriu.';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Introdu un email valid.';
    }
    return null;
  }

  /// Validează parola (minim 6 caractere). Returnează mesaj sau null.
  /// Folosită în special la login (nu forțăm o parolă „foarte puternică”).
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Parola este obligatorie.';
    }
    if (value.length < 6) {
      return 'Parola trebuie să aibă cel puțin 6 caractere.';
    }
    return null;
  }

  /// Validează o parolă „puternică” pentru înregistrare / schimbare parolă.
  /// Reguli: minim 8 caractere, cel puțin o literă mică, una mare, o cifră
  /// și un caracter special.
  static String? strongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Parola este obligatorie.';
    }
    if (value.length < 8) {
      return 'Parola trebuie să aibă cel puțin 8 caractere.';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Parola trebuie să conțină cel puțin o literă mică.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Parola trebuie să conțină cel puțin o literă mare.';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Parola trebuie să conțină cel puțin o cifră.';
    }
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Adaugă un caracter special (ex: ! @ # &).';
    }
    return null;
  }

  /// Validează că două parole coincid.
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirmă parola.';
    }
    if (value != password) {
      return 'Parolele nu se potrivesc.';
    }
    return null;
  }

  /// Validează suma (trebuie > 0). Returnează mesaj sau null.
  static String? amount(String? value, {bool allowZero = false}) {
    if (value == null || value.trim().isEmpty) {
      return 'Suma este obligatorie.';
    }
    final n = double.tryParse(value.trim().replaceAll(',', '.'));
    if (n == null) {
      return 'Introdu un număr valid.';
    }
    if (!allowZero && n <= 0) {
      return 'Suma trebuie să fie mai mare decât 0.';
    }
    if (allowZero && n < 0) {
      return 'Suma nu poate fi negativă.';
    }
    return null;
  }

  /// Validează codul de invitație (opțional; dacă e completat, 4-12 caractere alfanumerice).
  static String? inviteCode(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length < 4 || trimmed.length > 12) {
      return 'Codul de invitație trebuie să aibă între 4 și 12 caractere.';
    }
    if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(trimmed)) {
      return 'Codul conține doar litere și cifre.';
    }
    return null;
  }

  /// Validează numele (non-gol).
  static String? required(String? value, [String fieldName = 'Câmpul']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName este obligatoriu.';
    }
    return null;
  }
}
