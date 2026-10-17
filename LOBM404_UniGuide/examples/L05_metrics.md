# L5. Oqim metrikalarini hisoblash va tahlil qilish — o‘qituvchi namunasi

**Bu sun’iy to‘ldirilgan misol. Jamoaning haqiqiy bajargan ishlari, mavjud PRlari yoki servis akkauntlariga dalil emas. A/B/C/D anonim o‘quv rollari. Talaba bu matnni o‘z natijasi sifatida ko‘chirmaydi.**

## Hisob — sun’iy misol
Chegaralar: [2026-09-01, 2026-09-11), 10 kalendar kun. Kesim: 2026-09-10.
| ID | Lead | Cycle |
|---|---|---|
| C01 | 3 | 2 |
| C02 | 4 | 2 |
| C03 | 5 | 4 |
| C04 | 6 | 3 |
| C05 | 6 | 3 |
| C06 | 6 | 2 |
Lead yig‘indisi=30; o‘rtacha=30/6=5 kun. Cycle yig‘indisi=16; o‘rtacha=16/6≈2.6667 kun. Throughput=6/10=0.6 ish/kun. 1 sentabr va 11 sentabr orasida 10 o‘tgan kun bor; kunlarni sanab ikkala chegarani qo‘shmaymiz.
WIP=3: C07 (1 kun), C08 (0 kun), C10 (0 kun). C10 11 sentabrda tugaydi, shu sabab 10 sentabr kesimida faol, lekin kuzatuv oynasida tugallanganlar ro‘yxatiga kirmaydi. C06 aynan 10 sentabrda tugagan va bu kesimda WIP emas. C09 boshlanmagan, age ham WIP ham hisoblanmaydi.
Qaror: C03ning cycle time4 kuni boshqalardan uzun; sabab tekshiruv navbatimi yoki matn murakkabligimi, kartalar tarixidan tekshirish kerak. Bu sun’iy CSV sababni isbotlamaydi. Keyingi tajriba: muallif va tekshiruvchi oldindan juft bo‘lsin. N/A—tugallangan ish bo‘lmasa o‘rtacha yo‘q; 0—shu kunning o‘zida tugagan ish uchun to‘g‘ri davomiylik bo‘lishi mumkin.
