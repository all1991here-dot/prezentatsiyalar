# L14. Uchinchi sprintni yakunlash va release tayyorlash — o‘qituvchi namunasi

**Bu sun’iy to‘ldirilgan misol. Jamoaning haqiqiy bajargan ishlari, mavjud PRlari yoki servis akkauntlariga dalil emas. A/B/C/D anonim o‘quv rollari. Talaba bu matnni o‘z natijasi sifatida ko‘chirmaydi.**

## Sprint3 va reliz — namuna
Goal: qabul qilinadigan, takror ishga tushadigan UniGuide MVP. US06=3 va US07=2 tugallangan, US08=5 keyinga qoldirilgan; reja10, velocity5. Hozirgi ilova sevimlilar funksiyasini va’da qilmaydi.
Versiya taklifi `uniguide-v1.0.0`, boshqa kursning tagiga tegilmaydi. Haqiqiy tag jamoa o‘z repozitoriysida tayyorlik tekshiruvlaridan keyin yaratiladi.
Release notes: 6 maqola; turkum va matn qidiruvi; demo fikr; unit testlar va CI. Student L11 o‘zgarishini bajargan versiyada fikr1..300 belgi; referens namunasida yuqori limit500. Qaysi versiya chiqarilayotganini aniq yozish shart.
Cheklovlar: kontent namuna, real universitet xizmati emas; autentifikatsiya yo‘q; fikrlar xotirada demo; server lokal o‘quv uchun; US08 keyingi versiyada. Ishga tushirish: `python app/server.py --port 8765`, keyin `http://127.0.0.1:8765`. To‘xtatishCtrl+C. Qaytish: oldingi tekshirilgan commit/tagni alohida checkout qilishdan oldin o‘zgarishlarni saqlash; jamoa ishini force-push bilan o‘chirmaslik.
Qabul uchun dalillar: lokal test, yashil Actions, demo, PR review va release URL—jamoa ularni haqiqiy natija bilan to‘ldiradi.
