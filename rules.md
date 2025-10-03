# Kod yozish qoidalari

1) Soddalik
- Har doim eng sodda, tushunarli va keraklicha kifoya qiladigan yechimni tanla.
- Murakkablikni bosqichma-bosqich oshir: MVP → yaxshilash → optimallashtirish.

2) Izohlar (kommentlar)
- Kerak bo‘lgan joyda qisqa va mazmunli izoh yoz; “nima uchun” ni tushuntir.
- O‘zi o‘qiladigan kodni maqsad qil; keraksiz izohlardan qoch.

3) Optimizatsiya
- Ortiqcha kod yozma, takrorlarni funksiya/katalogga ajrat.
- Avval aniq bottleneck borligini isbotla, keyin optimallashtir.

4) Ishlaydigan kod
- Faqat parcha emas, to‘liq ishlaydigan misol/yoki minimal runnable blok ber.
- Yangi modul/ekran bo‘lsa, bog‘lanish (import, provider, route) ham qo‘shilsin.

5) O‘zgartirish kiritish
- Eski kod kontekstini inobatga ol; mos keladigan tarzda yangilash/qo‘shish qil.
- Refaktorlar kichik, mantiqiy bo‘laklarda; har bo‘lakdan so‘ng test qil.

6) Texnik tushuntirish
- Qadamlarni oddiy tilda, qisqa bandlarda tushuntir (what/why/how).

7) UI/Design
- Zamonaviy, toza va responsive ko‘rinish; kichik ekranlarni ham tekshir.
- Matnlar qisqa; overflowni `Expanded/Wrap` va `TextOverflow.ellipsis` bilan boshqar.

8) Savolga javob
- Keraksiz gap-so‘zsiz, aniq yechim; kerak bo‘lsa kod bloki.

9) Moslashtirish
- Talab qilingan texnologiyaga mos yoz (Flutter/HTML/CSS/Python va h.k.).
- Mavjud loyiha arxitekturasiga va kod uslubiga moslasha ol.

10) Xatolar
- Xatoni tushuntir, sababini ko‘rsat, to‘g‘rilangan kodni ber.
- RenderFlex overflow kabi UI xatolarini layout bilan bartaraf et.

11) Versiyalash
- Kichik, mantiqiy commitlar; aniq commit mesajlari.

12) Kod stili
- O‘qilishi oson nomlar; qisqartmalardan qoch (kerak bo‘lsa izohla).
- Bir xil format: linter/formatter talablariga rioya qil.

13) Performance
- UI kechikishini kamaytir: lokal-first, background sync, loglarni kamaytir.

14) Sinov va tekshiruv
- Yangi funksiya/ekran uchun kamida qo‘lda tekshiruv ro‘yxati bo‘lsin.
- Model/parsingda null-safety va default qiymatlar qo‘llanilsin.

15) Xavfsizlik
- Foydalanuvchi ma’lumotlari va kalitlarni oshkor qilma; RLS/policy’lardan foydalan.
Kod yozishda – har doim eng soddaroq va tushunarli variantini tanla.
