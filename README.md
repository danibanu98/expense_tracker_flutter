# 💰 Expense Tracker App

O aplicație mobilă modernă și intuitivă pentru gestionarea finanțelor personale, construită cu **Flutter** și **Firebase**.

Aplicația ajută utilizatorii să își urmărească veniturile și cheltuielile, să vizualizeze statistici detaliate și să gestioneze conturi multiple într-un singur loc.

---

## 📸 Screenshots

<div style="display: flex; gap: 10px;">
  <img src="assets/images/WhatsApp Image 2026-02-11 at 22.03.09.jpeg" alt="Home Screen" width="200" />
  <img src="assets/images/WhatsApp Image 2026-02-11 at 22.03.09 (2).jpeg" alt="Statistics" width="200" />   
  <img src="assets/images/WhatsApp Image 2026-02-11 at 22.03.09 (1).jpeg" alt="Transaction Details" width="200" />
</div>

---

## ✨ Funcționalități Principale (Existente)

### 🔐 Autentificare & Utilizator

- [x] Login și Înregistrare cu Email/Parolă (Firebase Auth).
- [x] Salvare date utilizator în Cloud (Firestore).
- [x] Pagina de Profil personalizată.

### 💸 Gestionare Finanțe

- [x] Adăugare tranzacții (Venituri / Cheltuieli).
- [x] Categorii predefinite cu iconițe intuitive.
- [x] Gestionare conturi multiple (Portofel, Card, Economii).
- [x] Vizualizare tranzacții recente.

### 📊 Statistici & Analiză

- [x] Grafice interactive (Line Chart) pentru evoluția soldului.
- [x] Filtrare avansată: Zi, Săptămână, Lună, An.
- [x] Top cheltuieli/venituri per categorie.

---

## 🚀 Roadmap & Funcționalități Viitoare (To-Do)

Aceasta este lista de dezvoltare. Pe măsură ce adaug funcționalități noi, le voi bifa aici:

### 🔄 Automatizare & Plăți

- [ ] **Plăți/Venituri Recurente** (Abonamente, Salariu, Chirie).
- [ ] Notificări push pentru plăți scadente.
- [ ] Adăugare rapidă (Shortcuts).

### 📈 Statistici Avansate

- [ ] Exportare date în format PDF / CSV (Excel).
- [ ] Setare Bugete Lunare (Ex: limită 500 RON la "Mâncare").
- [ ] Comparație între luni (Luna curentă vs. Luna trecută).

### 🎨 UI/UX & Setări

- [ ] Dark Mode / Light Mode toggle.
- [ ] Suport Multi-valută (RON, EUR, USD) cu conversie.
- [ ] Animații custom la tranziția între pagini.
- [ ] Securitate biometrică (FaceID / Fingerprint) la deschidere.

---

## 🛠️ Tehnologii Folosite

- **Framework:** [Flutter](https://flutter.dev/)
- **Limbaj:** [Dart](https://dart.dev/)
- **Backend:** [Firebase](https://firebase.google.com/) (Auth, Firestore)
- **State Management:** Provider
- **Grafice:** fl_chart
- **Icons:** Material Icons & FontAwesome

---

## 🏁 Cum să rulezi proiectul

1.  Clonează repository-ul:
    ```bash
    git clone [https://github.com/userul-tau/expense-tracker.git](https://github.com/userul-tau/expense-tracker.git)
    ```
2.  Instalează dependențele:
    ```bash
    flutter pub get
    ```
3.  Asigură-te că ai un emulator pornit sau un telefon conectat.
4.  Rulează aplicația:
    ```bash
    flutter run
    ```

---

Made with ❤️ by [Daniel Banu]
