# fermani_api

Minimal, lo‘nda va amaliy README. Ilova tovuq fermasi uchun kirim-chiqim va qarzlarni yuritishga mo‘ljallangan.

## 1) Loyiha haqida
- Ilova: Tovuq fermasi uchun hisobot va monitoring.
- Platforma: Flutter (Android, iOS, Web, Desktop).
- Maqsad: Kundalik savdo, xarajat, statistika va qarz daftari bilan ishlash.

## 2) Asosiy funksiyalar
- Tovuq fermasi bo‘limi: kirim-chiqim, ombor, kunlik hisobot, statistik kartalar.
- Qarz daftari bo‘limi: qarz qo‘shish, to‘lov qayd qilish, qarzdorlar ro‘yxati, qoldiq.
- Tez navigatsiya: tepada 2 ta tugma orqali sahifalararo o‘tish.

## 3) Dizayn va navigatsiya
- AppBar (yuqori panel) “driver” sifatida ishlaydi.
  - Chap tugma: "Tovuq fermani"
  - O‘ng tugma: "Qarz daftari"
- Har bir tugma o‘z sahifasiga olib boradi:
  - "Tovuq fermani" → ferma bosh sahifa (statistika, kirim-chiqim)
  - "Qarz daftari" → qarzdorlar, qarz qo‘shish/to‘lash
- Tavsiya etilgan route nomlari:
  - `/ferma`
  - `/qarz`
  (Navigator yoki siz tanlagan router bilan ishlatish mumkin.)

### UI bo‘yicha qisqa eslatmalar
- Minimal, toza, kontrast ranglar.
- Statistik kartalar: `lib/lib/widgets/animated_stats_card.dart` bilan animatsion ko‘rsatkichlar.
- Katta tugmalar, soddalashtirilgan forma va ro‘yxatlar.

## 4) O‘rnatish va ishga tushirish
1. Flutter SDK o‘rnatilgan bo‘lishi kerak.
2. Paketlarni yuklab oling:
   - `flutter pub get`
3. Ishga tushiring:
   - Android/iOS: `flutter run`
   - Web: `flutter run -d chrome`

## 5) Papkalar tuzilmasi (lo‘nda)
- `lib/main.dart` – ilova kirish nuqtasi.
- `lib/lib/widgets/animated_stats_card.dart` – statistik kartalar vidjeti.
- `lib/lib/` ichida: `core/`, `data/`, `models/` – logika, ma’lumot, model fayllari.

## 6) TODO (tezkor reja)
- AppBar ga 2 ta asosiy tugma qo‘shish: "Tovuq fermani" va "Qarz daftari".
- Navigatsiya yo‘llarini kiritish: `/ferma` va `/qarz`.
- "Qarz daftari" sahifasini qo‘shish: ro‘yxat, qo‘shish, to‘lov, filtr/qidiruv.
- Statistik ko‘rsatkichlarni (animated cards) ferma sahifasida ko‘rsatish.
- Ma’lumotlarni lokal (va keyin kerak bo‘lsa onlayn) saqlash.

## 7) Qisqa foydalanish yo‘riqnomasi
- Ilova ochilganda yuqoridagi paneldan bo‘lim tanlang.
- "Tovuq fermani" – kundalik kirim/chiqim va statistikani yuriting.
- "Qarz daftari" – qarzdorlarni ro‘yxatga oling, to‘lovlarni qayd qiling.

## 8) Talab va versiyalar
- Flutter SDK: pubspec.yaml talablari bo‘yicha.
- Qo‘shimcha paketlar: `pubspec.yaml` ga qarang.
