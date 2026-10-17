# L7. Dasturiy loyihani tashabbuslash, backlog va WBS — o‘qituvchi namunasi

**Bu sun’iy to‘ldirilgan misol. Jamoaning haqiqiy bajargan ishlari, mavjud PRlari yoki servis akkauntlariga dalil emas. A/B/C/D anonim o‘quv rollari. Talaba bu matnni o‘z natijasi sifatida ko‘chirmaydi.**

## MVP va backlog — namuna
UniGuide shu olti maqolani brauzerda ko‘rsatadi. MVP: ro‘yxat, turkum, qidiruv, lokal demo fikr shakli. Login, to‘lov, haqiqiy murojaat va bulutga deploy kirmaydi.
| ID | Natija | Point | Ustuvorlik | Qabul |
|---|---|---|---|---|
| US01 | 6 maqolani ko‘rish | 3 | Must | 6 ID va mazmun chiqadi |
| US02 | Turkum filtri | 3 | Must | Ta’lim filtri 3 maqola qaytaradi |
| US03 | Kichik ekranda o‘qish | 2 | Should | 390px kenglikda gorizontal toshish yo‘q |
| US04 | Matndan qidirish | 5 | Must | LMS so‘rovi mos matnni topadi; bo‘sh natija tushunarli |
| US05 | Demo fikr shakli | 3 | Should | Chegara ichidagi matn tekshiriladi; bo‘sh matn rad; hech qayerga saqlanmaydi |
| US06 | Sifat va kiritma tekshiruvi | 3 | Must | To‘liq regressiya, CI va tekshiruv dalillari mos |
| US07 | Reliz va topshirish | 2 | Must | Testlar yashil; release notes; tag |
| US08 | Sevimlilar | 5 | Could | Keyingi versiya; joriy MVPga kirmaydi |
| WBS | Natija | Ish paketi | Qabul |
|---|---|---|---|
| 1.1 | Qabul qilingan kontent | 6 maqola IDlarini saqlash; A | Kontent ro‘yxati |
| 1.2 | O‘qiladigan interfeys | Ro‘yxat va turkum; D | US01/US02 demo |
| 1.3 | Topish va fikr | Qidiruv, forma; C | API/DOM tekshiruvi |
| 1.4 | Sifat | Test, CI, review; B va barcha | Yashil Actions va PR |
| 1.5 | Topshirish | Release notes, hisobot; A | L14/L15 paket |
Bog‘liqlik: kontent → ro‘yxat → qidiruv; asosiy funksiyalar → regressiya → reliz. DoD: mezon o‘tgan, testlar muvaffaqiyatli, boshqa a’zo review qilgan, hujjat yangilangan, lokal demo ishlagan. DoR—jamoa yordamchi kelishuvi, Scrumning rasmiy majburiy artefakti emas. US08 qo‘shilsa PO mavjud qamrov yoki muddatni qayta kelishadi.
