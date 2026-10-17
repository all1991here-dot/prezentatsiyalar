# L9. Jamoa, kommunikatsiya, risk va xarajatlarni boshqarish — o‘qituvchi namunasi

**Bu sun’iy to‘ldirilgan misol. Jamoaning haqiqiy bajargan ishlari, mavjud PRlari yoki servis akkauntlariga dalil emas. A/B/C/D anonim o‘quv rollari. Talaba bu matnni o‘z natijasi sifatida ko‘chirmaydi.**

## RACI — namuna
| Natija | A (PO) | B (SM) | C | D |
|---|---|---|---|---|
| Kontent qabul | A/R | I | C | R |
| Kod o‘zgarishi | C | I | A/R | R |
| Reliz | A | R | R | C |
Har qatorda aynan bitta A. A/R bitta shaxsning ikki mas’uliyatini bildiradi. Review o‘z kodingizga yakka o‘zingiz qo‘yadigan belgi emas.
Kommunikatsiya: dars boshida 5daqiqa holat; GitHub issue’da asinxron to‘siq; jiddiy risk paydo bo‘lganda o‘sha kuni POga xabar; sprint reviewda buyurtmachi bilan mahsulotni ko‘rish. B uchrashuvni osonlashtiradi, barcha ishni buyuradigan menejer deb olinmaydi.
| Risk | P | I | Ball | Javob | Trigger / egasi |
|---|---|---|---|---|---|
| GitHub kirish uzilishi → PR kechikadi | 3 | 3 | 9 | Lokal commit, qaytganda push; maxfiy kalit tarqatilmaydi | 15 daqiqa uzilish / B |
| Noto‘g‘ri universitet ma’lumoti → talaba adashadi | 3 | 4 | 12 | Rasmiy manba yoki aniq o‘quv namuna belgisi | Manba topilmadi / A |
| Tekshiruvchi yo‘q → Review tiqiladi | 4 | 3 | 12 | Juft review navbatchiligi | 1dars kutish / D |
| Qamrov kengayishi → release kechikadi | 3 | 4 | 12 | CR va MVP chegarasi; US08ni kechiktirish | Yangi Must so‘rovi / A |
## Hisoblangan budjet (real to‘lov emas)
| Band | Hisob | So‘m |
|---|---|---|
| Mehnatning shartli qiymati | 4 a’zo ×12 soat ×25,000 | 1,200,000 |
| Shartli chop/material | 1 paket ×100,000 | 100,000 |
| Asosiy baho | 1,200,000+100,000 | 1,300,000 |
| Contingency: aniqlangan risk uchun | Asosiy bahoning 10%i | 130,000 |
| Cost baseline | 1,300,000+130,000 | 1,430,000 |
| Management reserve: alohida qat’iy miqdor | 70,000 (foiz emas) | 70,000 |
| Umumiy ruxsat etilgan o‘quv chegara | 1,430,000+70,000 | 1,500,000 |
Lokal dastur, Python va bepul servislar uchun shartli litsenziya xarajati0. Haqiqiy xarid yo‘q. Risk rezervi ham sarf bo‘lmaguncha xarajat hisoblanmaydi. CR-01 namunasi: sevimlilar qo‘shish 5SP; joriy sprintga sig‘maydi; PO keyingi versiyaga qoldiradi. Tasdiq jamoaning haqiqiy qaydida bo‘lishi kerak.
