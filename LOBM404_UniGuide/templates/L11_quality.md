# L11. Sifat nazorati va avtomatlashtirish

Talaba jamoasi to‘ldiradigan shablon. Faylni `team/` papkasiga shu nom bilan ko‘chiring.

**Jamoa / sana / to‘ldiruvchi:** ...

## Sifat kelishuvi va aniq o‘zgarish
Story/issue: ...; talab: fikr uzunligini 500dan300 belgiga tushirish. Referens ilova avval 1..500ni qabul qiladi.
1. `app/tests/test_feedback_policy.py`da300 qabul,301 rad testini qo‘shing.
2. Testni ishga tushiring; eski kodda301 testi yiqilgan chiqishni yozing.
3. `app/core.py`dagi `MAX_FEEDBACK_LENGTH = 300`ni belgilang. Serverni qayta ishga tushiring va brauzerni yangilang: interfeys yuqori chegarani `/api/health`dan oladi. Mavjud testlar konstantadan foydalanadi, ularni o‘chirmang; yangi300/301 testlari yangi talabni alohida mustahkamlaydi.
4. Barcha test, compileall va lokal demo; PR va teammate review.
| Tekshiruv | Buyruq / usul | Natija va dalil |
|---|---|---|
| Qizil test | `python -m unittest discover -s app/tests -v` | ... |
| Yashil test | Xuddi shu buyruq | ... |
| Sintaksis | `python -m compileall -q app scripts` | ... |
| CI | Actions run URL | ... |
GitHub Actionsdagi compileall sintaksis tekshiruvi; to‘liq uslub linteri emas. Real Actions natijasisiz CI muvaffaqiyatli deb yozmang.
Nuqson reyestri: ID, qayta hosil qilish, kutilgan/amaldagi, ustuvorlik, egasi, tuzatish dalili.

**Topshiriladigan dalillar manzili:** ...
