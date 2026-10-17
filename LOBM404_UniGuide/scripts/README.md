# Oqim metrikalari va materiallarni tekshirish

Loyiha ildizidan Python3.10+ bilan ishlating. Tashqi paket talab etilmaydi.

```console
python scripts/metrics.py
python scripts/metrics.py --json
python -m unittest discover -s scripts/tests -v
python scripts/check_project.py
```

O‘z CSV faylingiz uchun:

```console
python scripts/metrics.py --csv team/flow_data.csv --start 2026-09-01 --end 2026-09-11 --asof 2026-09-10
```

Windowsda `python` o‘rniga `py -3` bo‘lishi mumkin. Sanalar `YYYY-MM-DD`. Faqat `started` va `done` bo‘sh bo‘lishi mumkin. Qabul navbatida turib boshlanmagan ishda ikkalasi ham bo‘sh; boshlangan-u tugamagan ishda faqat `done` bo‘sh. Sana yo‘qolishi boshqa holat bo‘lsa, uni taxmin qilib to‘ldirmang: jamoa tarixidan tiklang yoki alohida rad etilgan yozuv deb qayd qiling.

## Hisoblash shartnomasi

- Lead time = done − queued; cycle time = done − started.
- Bu o‘tgan kalendar kunlar; dam olish kunlari ayirilmaydi, ikkala chegara qo‘shilib sanalmaydi. Shu kunning o‘zida tugash0 kun bo‘lishi mumkin. Sana aniqligi soatlik farqni o‘lchamaydi.
- Tugallangan ishlar va o‘rtacha qiymatlar faqat `start ≤ done < end` bo‘lgan ishlar uchun. Masalan `[2026-09-01, 2026-09-11)` oynasida11sentabr tugallangan ish kirmaydi.
- Throughput = shu oynadagi tugallangan ishlar soni / `(end − start).days`. Oyna barcha ishlarning min/max sanasidan avtomatik olinmaydi; tahlilchi oldindan belgilaydi.
- WIP kesimida `started ≤ asof` va `done` bo‘sh yoki `done > asof`. Kelajakda tugagan, ammo shu kesimda faol bo‘lgan ish WIPga kiradi. `done == asof` bo‘lsa tugagan deb olinadi.
- Age shu kesimdagi faol ishlar uchun `asof − started`. Boshlanmagan ish uchun age yo‘q. Bu boshlangandan beri ish yoshi, navbatda kutish yoshi emas.
- Oynada tugallangan ish bo‘lmasa o‘rtacha lead/cycle `null`/N/A, throughput0. Faol ish bo‘lmasa o‘rtacha age `null`/N/A. Nolni mavjud bo‘lmagan o‘rtacha o‘rniga qo‘ymaymiz.
- ID takrori, yo‘q queued, done bor-u started yo‘q, noto‘g‘ri sana, `started < queued` yoki `done < started` xatodir. Noto‘g‘ri kataklar soni ham xato. Skript tushunarli xabar va exit code2 beradi.

## Berilgan CSVning aniq natijasi

`data/flow_data.csv` sun’iy o‘quv misoli. U haqiqiy jamoa tarixi emas.

| Ish | Lead (kun) | Cycle (kun) |
|---|---:|---:|
| C01 | 3 | 2 |
| C02 | 4 | 2 |
| C03 | 5 | 4 |
| C04 | 6 | 3 |
| C05 | 6 | 3 |
| C06 | 6 | 2 |

Standart oyna10kun, tugallangan6ish. O‘rtacha lead =30/6=5kun, cycle=16/6≈2.6667kun, throughput=6/10=0.6ish/kun. 10sentabr kesimida C07 age1, C08 age0, C10 age0; WIP3 va o‘rtacha age1/3kun. C06 shu kesimda allaqachon tugagan. C09 boshlanmagan. C10 11sentabrda tugaydi va oynaning yuqori chegarasi sabab tugallangan6ish qatoriga kirmaydi.

L3/L4dagi WIP limit2+1 uchun bu tarixiy kesim3ta boshlangan ish mos kelishi mumkin; faqat started/done CSVsi qaysi biri In Progress yoki Reviewda ekanini ajratmaydi. Alohida ustun tarixi bo‘lmasa Review kutish vaqti yoki to‘liq CFDni "haqiqiy o‘lchov" deb chiqarmang. Shu CSVdan kunlik queued/active/done jami shaklida uch holatli o‘quv CFDsi chizish mumkin; besh holatli Trello CFDsi uchun batafsil o‘tish tarixi kerak.

Tanlanma6ishdan ishonchli kelajak kafolati chiqarmang. SLE uchun uzunroq, bir xil siyosat bilan yig‘ilgan tarix va hisoblash usulini yozish zarur.

## Sprint misoli

`data/sprint_data.csv` ham sun’iy. `done` bo‘lgan story butun reja pointini oladi; `incomplete` va `deferred`0. S1reja8/velocity6, S2reja10/velocity10, S3reja10/velocity5; jami tugallangan21SP, o‘rtacha7SP/sprint. Jami rejalangan28SP qayta rejalangan US03ni ikki marta o‘z ichiga oladi; bu28noyob point degani emas. US03 faqat S2da2point bajarilgan deb hisoblanadi. Story pointlar soat emas, turli jamoalarni tezlik bo‘yicha reyting qilish uchun emas. US08 sevimlilar joriy MVPdan tashqarida.

`check_project.py` 15+15artefakt, ilova asosiy fayllari, 6barqaror maqola IDsi, maqoladagi kamida3qadam, oqim sanalari va sprint pointlari izchilligini tekshiradi. U mazmunning haqiqiy universitetga mosligini, shaxsiy hissani, o‘qituvchi qabulini yoki tashqi servisdagi ishni tekshirmaydi.
