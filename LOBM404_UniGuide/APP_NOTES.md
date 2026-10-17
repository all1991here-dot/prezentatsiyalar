# UniGuide ilovasi: aniq ishlash shartnomasi

Bu LOBM404 mashg‘ulotlari uchun tayyor, ishlaydigan **o‘quv MVP**. Haqiqiy universitetning manzili, ish vaqti, hisoblari yoki shaxsiy ma’lumotlari ishlatilmaydi. Python **3.10 yoki yangiroq** va brauzer yetadi; `pip install` kerak emas.

## Ishga tushirish

Terminalni aynan `LOBM404_UniGuide` papkasida oching:

```text
python --version
python app/server.py --port 8765
```

Windowsda `python` topilmasa, xuddi shu buyruqlarda `py -3` ishlating. Brauzer: <http://127.0.0.1:8765>. To‘xtatish: `Ctrl+C`. Port band bo‘lsa `--port 8766` va brauzerda ham 8766. Standart server faqat shu kompyuterdagi `127.0.0.1` interfeysida ochiladi. O‘quv mashqi uchun tashqi tarmoqqa ochish shart emas.

Ikkinchi terminalda:

```text
python -m unittest discover -s app/tests -v
python -m compileall -q app
```

Asosiy to‘plamda **32 ta** unit va haqiqiy HTTP testi bor. Birinchi buyruq domen/API xulqini tekshiradi; ikkinchisi faqat Python sintaksisini tekshiradi, to‘liq kod uslubi linti emas. HTTP testlar band bo‘lmagan vaqtinchalik portni o‘zlari tanlaydi. Ularga 8765 serverini oldindan ishga tushirish shart emas.

## Fayllar va xulq

- `app/data/articles.json`: kutubxona, LMS, dars jadvali, dekanat, xavfsizlik va klublar haqidagi olti namunaviy maqola.
- `app/core.py`: kontent shakli, qidiruv, turkum va fikr matni qoidalari.
- `app/server.py`: standart kutubxonaga asoslangan mahalliy HTTP server.
- `app/static/`: tashqi CDN, shrift yoki internet paketsiz ishlaydigan interfeys.
- `app/tests/`: avtomatik tekshiruvlar. Testning yashil chiqishi haqiqiy GitHub Actions runini avtomatik isbotlamaydi; CI alohida ko‘riladi.

Maqolalar sahifa yuklanganda/API so‘rovida diskdan o‘qiladi; JSONni saqlab, sahifani yangilash yetadi. Python qoidasini o‘zgartirgach serverni qayta ishga tushiring. Qidiruv sarlavha, qisqa izoh va asosiy matndan **barcha so‘rov so‘zlarini** izlaydi. So‘z tartibi muhim emas. Katta-kichik harflar va o‘zbek apostrofining odatiy variantlari birxillashtiriladi. Turkum esa normallashgandan keyin to‘liq mos bo‘lishi kerak. Bo‘sh qidiruv barcha maqolani qaytaradi. Maqola matni brauzerda oddiy matn sifatida chiqariladi.

## Aniq HTTP API

| Amal | Javob va xatolar |
|---|---|
| `GET /api/health` | 200: `status: "ok"`, `app: "UniGuide"`, `mode: "teaching-demo"`, `feedback_max_length: 500`. L11da qoida 300ga o‘zgarsa, qayta ishga tushgan server 300 qaytaradi. |
| `GET /api/articles?q=kutubxona&category=` | 200: `articles` ro‘yxati, `total` soni, barcha `categories`. `q` va `category` ixtiyoriy. Masalan, `category=Ta%27lim` uchta ta’lim maqolasini qaytaradi. Mos natija bo‘lmasa bo‘sh ro‘yxat — xato emas. |
| `POST /api/feedback` | `Content-Type: application/json`, tana: `{"message":"Taklif matni"}`. 200: `accepted: true`, `persisted: false`, izohli `message`. Fikr **saqlanmaydi**; bu fikrni tekshirish demosi. |

Feedback qoidasi: qiymat matn bo‘lishi, atrofi bo‘shliqlardan tozalangandan keyin 1–`MAX_FEEDBACK_LENGTH` **Unicode kod nuqtasi** bo‘lishi kerak. Faqat bo‘shliq yoki boshqa tur 400; noto‘g‘ri JSON/UTF-8 400; noto‘g‘ri `Content-Type` 415; 8192 baytdan katta HTTP tanasi 413. Noma’lum API yo‘li 404 JSON qaytaradi. Matnni faylga yoki tashqi xizmatga yozish yo‘q. Shuning uchun real ism, parol, token yoki aloqa ma’lumoti kiritilmaydi.

Brauzerdagi hisoblagich va `setCustomValidity` cheklovi `/api/health`dan kelgan qiymatni oladi. Oxirgi tekshiruv har doim serverda. O‘zgarishdan keyin serverni qayta ishga tushirib sahifani yangilang.

## L11: haqiqiy red → green kichik mashqi

Mashqni **o‘z repozitoriyingizning ish branchida** bajaring. Tarqatilgan namunaviy `main`ni boshqalarning ishi bilan aralashtirmang. Yangi talab: 301 va undan ko‘p belgili fikr rad etilsin; 1–300 belgi qabul qilinsin.

1. `app/tests/test_feedback_policy.py` nomli yangi fayl yarating:

```python
import unittest
from app.core import validate_feedback


class FeedbackPolicyTests(unittest.TestCase):
    def test_new_policy_rejects_301(self):
        with self.assertRaises(ValueError):
            validate_feedback("a" * 301)

    def test_new_policy_accepts_300(self):
        self.assertEqual(validate_feedback("a" * 300), "a" * 300)

    def test_whitespace_only_rejected(self):
        with self.assertRaises(ValueError):
            validate_feedback("   ")
```

2. `python -m unittest discover -s app/tests -v`ni bajaring. **Kutilgan RED:** `test_new_policy_rejects_301` yiqiladi: `AssertionError: ValueError not raised`. Amaldagi 500 cheklovi 301 belgini qabul qilayotgani uchun bu mazmunli xato. Avval shu chiqishni dalilga yozing. Buyruq boshqa sababdan, masalan import xatosidan yiqilsa, uni TDDning kerakli qizil bosqichi deb olmang.

3. `app/core.py`dagi bitta qatorni almashtiring:

```python
MAX_FEEDBACK_LENGTH = 300
```

4. Testlarni qayta bajaring. **Kutilgan GREEN:** 35 testning hammasi o‘tadi. Oldingi chegara testlari `MAX_FEEDBACK_LENGTH`ni import qilgani uchun yangi qoida bilan ishlashda davom etadi. Testni izohga olib yashil qilish yoki `assert`ni olib tashlash bu mashqning yechimi emas.

5. Serverni to‘xtatib qayta oching. Brauzer sahifasini yangilang: `0 / 300 belgi` chiqadi. 300 belgini qabul qilish va 301 belgini rad etishni API testi hamda interfeys bilan ko‘ring. Maqola qidiruvi va filtri ham ishlashini tekshiring.

6. Qabul mezoni, red/green chiqishi, commit va PR havolasini `team/L11` daliliga yozing. CI runini alohida ko‘ring; amaldagi natijani saqlang. Namuna repozitoriyida boshlang‘ich talab **500** bo‘lib qoladi — bu talabaning mustaqil o‘zgarishidir.

## Qo‘llanmadagi rasmlar uchun o‘quv paneli

`/lab?view=charter|backlog|board|wip|metrics|review|sprint|risks|quality|release`dan bir qiymat bilan foydalaning. Masalan <http://127.0.0.1:8765/lab?view=metrics>. Panel **statik tushuntiruvchi maket**, real xizmatdan o‘qiladigan boshqaruv paneli emas. Yuqorida doim `NAMUNAVIY / O‘QUV MA’LUMOTLARI` va `GitHub/Trello/Jira interfeysi emas` yozuvi bor. Paneldagi taxta haqiqiy Trello/Jira amaliyoti yoki ularning TN natijasi o‘rnini avtomatik bosmaydi.

`metrics` rasmining o‘quv raqamlari `data/flow_data.csv` standart misoliga mos: kuzatuv `[2026-09-01,2026-09-11)`, as-of `2026-09-10`; 6 yakun, o‘rtacha lead 5 kun, cycle 16/6 ≈ 2.67 kun, throughput 0.60 karta/kun, WIP 3. Panel CSVni jonli qayta hisoblamaydi. Haqiqiy hisob uchun `python scripts/metrics.py`ni ishlating. `review`dagi reja/tugallangan pointlar 8/6, 10/10, 10/5; bular ham namuna. `risks` byudjeti 1 300 000 + 130 000 + 70 000 = 1 500 000 so‘m — haqiqiy to‘lov emas.
