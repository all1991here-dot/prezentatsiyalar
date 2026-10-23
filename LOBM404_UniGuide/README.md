# UniGuide — LOBM404 laboratoriya loyihasi

**L4 uchun yangi:** [rasmlar va bosqichlar bilan amaliy loyiha](L4_amaliy_loyiha/) · [Word qo‘llanma](Dars_materiallari/L4_rasmli_amaliy_qollanma.docx) · [ZIP paket](Dars_materiallari/L4_amaliy_loyiha.zip).


**Loyihalarni boshqarish**, 2026–2027. Sillabusdagi15 laboratoriya bitta mahsulotga bog‘langan: yangi talabalarga6 asosiy yo‘nalishda yo‘l ko‘rsatadigan UniGuide.

## O‘qituvchi qo‘llanmasi

**[Rasmli Word qo‘llanmani yuklab olish](https://github.com/all1991here-dot/prezentatsiyalar/raw/refs/heads/main/LOBM404_UniGuide/Qollanma/LOBM404_15_laboratoriya_qollanma.docx)**

Har laboratoriyada90 daqiqalik reja, o‘qituvchi izohi, batafsil bajarish qadamlari, ikkita tushuntiruvchi rasm, namuna, tekshirish mezonlari, xatolar yechimi, javobli savollar va10 ballik tavsiya rubrikasi bor. Rasm va dashboardlar mahalliy o‘quv namoyishidir; ular GitHub, Trello yoki Jira ning rasmiy interfeysi emas.

## Mahsulot va bosqichlar

- **L01–L06:** kontent-loyiha, Kanban, WIP, oqim metrikalari va kontentni qabul qilish.
- **L07–L10:** shu kontentning dasturiy ko‘rinishi; backlog/WBS, Git va birinchi sprint.
- **L11–L12:** sifat va kichik test-first yaxshilash, ikkinchi sprint.
- **L13–L15:** monitoring, uchinchi sprint, release va individual dalilli himoya.

Ilova tayyor, ishlaydigan **o‘quv MVP**. Uni noldan yozish talab qilinmaydi: asosiy e’tibor loyihani boshqarish, kontentni yaxshilash, hamkorlik va tekshiriladigan kichik o‘zgarishlarga qaratilgan. Rejadagi storylar dars uchun namunadir; jamoaning haqiqiy dalili tayyor misoldan alohida yuritiladi.

## Tez boshlash

Python3.10+ va brauzer kerak. Tashqi Python paketi, bank kartasi yoki pullik hosting kerak emas.

1. Ushbu repozitoriyni o‘z hisobingizga **Fork** qiling yoki **Code → Download ZIP** bilan olib arxivdan chiqaring.
2. Terminalni **LOBM404_UniGuide** papkasida oching.
3. Bajaring:

```sh
python app/server.py --port 8765
```

Brauzerda **http://127.0.0.1:8765** ni oching. O‘quv doskasi: **http://127.0.0.1:8765/lab**. Serverni `Ctrl+C` bilan to‘xtating. Windows da `python` topilmasa, `py -3` ishlating. Port band bo‘lsa, `--port 8766` va brauzerda ham8766 ni tanlang.

Ikkinchi terminalda:

```sh
python -m unittest discover -s app/tests -v
python -m unittest discover -s scripts/tests -v
python -m compileall -q app scripts
python scripts/check_project.py
python scripts/metrics.py
```

Tayyor nusxada **32 ta ilova testi** va **6 ta metrika testi** mavjud. `compileall` sintaksis tekshiruvi, to‘liq uslub linteri emas. Testlar o‘z vaqtinchalik HTTP portini tanlaydi; ularni bajarish uchun serverni avval yoqish shart emas.

## Papkalar

| Papka/fayl | Vazifasi |
|---|---|
| `Qollanma/` | Rasmli o‘qituvchi Word qo‘llanmasi |
| `templates/` | L01–L15 talaba shablonlari; nusxasini `team/` ga oling |
| `examples/` | O‘qituvchi uchun to‘ldirilgan, aniq belgilangan sun’iy misollar |
| `app/` |6 maqolali ro‘yxat, qidiruv, turkum filtri va fikrni tekshirish demosi |
| `data/` | Namunaviy oqim va sprint ma’lumotlari |
| `scripts/` | Metrikalar hisoblash, testlar va loyiha tekshiruvi |
| `APP_NOTES.md` | API va L11 qizil→yashil mashqining aniq kodi |

## Talabaning ish tartibi

Shablonni `team/L01_charter.md` kabi yo‘lga ko‘chiring, maydonlarni haqiqiy jamoa ma’lumoti va dalillari bilan to‘ldiring. Issue → branch → commit → pull request → review → test → merge zanjirini bajaring. PR ning base repozitoriysi **o‘z jamoangiz nusxasi** ekanini tekshiring. Asl o‘qituvchi repozitoriysiga PR yuborish bu mashqda shart emas.

Trello/Jira/GitHub Projects darslarida haqiqiy board/sprint havolasini saqlang. Mahalliy `/lab` paneli tushuntirish uchun; u tashqi servisda amaliyot qilinganini isbotlamaydi. Kirish bo‘lmasa fallbackni va tekshirilmagan natijani ochiq qayd eting. Hisobotga parol/token yoki real talaba shaxsiy ma’lumotini kiritmang.

## L11: kichik, haqiqiy o‘zgarish

`app/tests/test_feedback_policy.py` ga300 qabul/301 rad/bo‘sh matn rad testlari qo‘shiladi. Eski500 limit bilan bir testning yiqilishi kutiladi. Keyin **o‘z ish branchingizda** `MAX_FEEDBACK_LENGTH=300` qiling, serverni qayta ishga tushiring va brauzerni yangilang. UI limitni `/api/health` dan oladi. Asosiy chegara testlari konstantaga bog‘langan; ularni o‘chirmang. To‘liq ko‘rsatma: `APP_NOTES.md` va Word L11.

Fikrlar bazaga yozilmaydi; server xabarni tekshirib, saqlanmaganini qaytaradi. Haqiqiy universitet hisobi yoki ma’lumot bazasi ulanmagan.

## Hisoblash namunasi va CI

`data/flow_data.csv`: [2026-09-01,2026-09-11), asof2026-09-10. Lead5.00kun, cycle2.6667kun, throughput0.60ish/kun, WIP3. Bu sun’iy o‘quv ma’lumotlari, haqiqiy jamoa ko‘rsatkichlari emas. To‘liq ta’riflar: `scripts/README.md`.

GitHub Actions konfiguratsiyasi repozitoriy ildizida: `.github/workflows/lobm404-uniguide.yml`. Forkda Actions o‘chiq bo‘lsa, o‘z hisobingiz huquqlari doirasida uni yoqing. Workflow fayli borligi run muvaffaqiyatli o‘tganini bildirmaydi; **Actions** bo‘limida haqiqiy natijani tekshiring va URL saqlang. Bu qo‘llanma tayyorlanganda lokal testlar tekshirilgan; masofadagi Actions holati alohida tasdiqlanadi.
