# L11. Sifat nazorati va avtomatlashtirish — o‘qituvchi namunasi

**Bu sun’iy to‘ldirilgan misol. Jamoaning haqiqiy bajargan ishlari, mavjud PRlari yoki servis akkauntlariga dalil emas. A/B/C/D anonim o‘quv rollari. Talaba bu matnni o‘z natijasi sifatida ko‘chirmaydi.**

## Test-first yaxshilash — bajarish namunasi
Talab: US05 doirasida demo fikri strip qilingandan keyin1..300 belgi bo‘lsin. Referens koddagi yuqori limit500. Test: `validate_feedback("a"*300)`300 belgini qaytarsin; `validate_feedback("a"*301)` ValueError bersin. Ikkinchi test eski kodda yiqilishi kutiladi:301 eski limit ichida edi.
So‘ng `MAX_FEEDBACK_LENGTH = 300`. UI yuqori chegarani `/api/health`dan oladi: serverni qayta ishga tushirish va sahifani yangilashdan keyin300 ko‘rinadi. `app/tests/test_core.py`dagi umumiy chegara sinovlari konstantadan foydalanadi va o‘zgartirilmaydi. Testlarni o‘chirish mumkin emas; yangi300/301 chegaralari talabni ochiq test bilan mustahkamlaydi.
Tekshiruvlar: ilova testlari, metrics testlari, compileall, GitHub Actions. Bo‘sh matn va noto‘g‘ri tur hali ham rad etiladi. Haqiqiy red/green terminal chiqishini talabalar saqlaydi. Bu namunada bajarilmagan CI yoki PR uchun URL uydirilmagan.
Tekshiruv misoli: konfiguratsiya o‘zgargandan keyin brauzer eski sahifada500 ko‘rsatsa, serverni qayta ishga tushirib sahifani yangilang va `/api/health`dagi limitni tekshiring. UI va server bir manbadan oladigan qoida mos bo‘lishi kerak. Barcha avtomatlashtirish mazmun aniqligi va qulaylikni to‘liq isbotlamaydi, ular qo‘lda ham ko‘riladi.
