# EURUSD MicroSafe M1 Pro v1.10 — o‘zbekcha qo‘llanma

Robot EURUSD uchun M1 da BUY/SELL signallarini o‘zi tekshiradi va shartlar bajarilganda savdo qiladi. Har daqiqada savdo ochish majburiyati yo‘q: natija BUY, SELL yoki signal yo‘q bo‘lishi mumkin.

**80% yutuq va foyda kafolatlanmaydi.** Robot signalga yutuq ehtimoli bermaydi. Ushbu yangi strategiyaning savdo soni yoki foydaliligi oshgani hali backtest bilan tasdiqlanmagan. Yuqori yutuq ulushi o‘zi foydalilikni anglatmaydi: komissiya, spred va yirik zararlar ham hisoblanadi.

## Fayllar va o‘rnatish

- `EURUSD_MicroSafe_M1_Pro.mq5` — robot manba kodi.
- `Standard_500_Demo.set` — $500 Standard demo uchun boshlang‘ich sozlamalar.
- `XM_Micro_50_Demo.set` — $50 haqiqiy Micro kontraktli demo uchun boshlang‘ich sozlamalar.
- `README_UZ.md` — ushbu qo‘llanma.

1. ZIP to‘plamni yuklab, kompyuterda oching. Alohida faylni GitHub’dan olsangiz, uning sahifasidagi **Download raw file** tugmasidan foydalaning.
2. MT5 → **File → Open Data Folder** → `MQL5/Experts` ichiga `.mq5` faylni ko‘chiring.
3. MetaEditor’da faylni ochib **F7 / Compile** bosing. Kompilyatsiya xatolari bo‘lsa, savdoni boshlamang; xatolar ro‘yxatini saqlang.
4. MT5 Navigator’ni yangilang, brokerdagi EURUSD instrumentining **M1** grafigiga robotni qo‘ying.
5. **Inputs → Load** orqali mos `.set` faylni yuklang. Algo Trading va EA savdo ruxsatini yoqing.
6. Faqat ushbu robotga ajratilgan demo hisob ishlating. Boshqa EA va qo‘lda savdo ishlatmang.

Standart risk **0.5%**, real hisobga ruxsat **false**. Profil nomlari avvalgidek, tarkibi v1.10 ga moslangan; yangi to‘plamdagisini yuklang. Robot ochiq yozilgan texnik qoidalarga amal qiladi; mashinaviy o‘rganish yoki yutuq ehtimoli modeli ishlatilmaydi. Real hisob blokini ochish robot sinovdan o‘tganini bildirmaydi.

**Yangilashni faqat pozitsiya va buyurtmalar yo‘qligida, oldingi so‘rov broker tarixi bilan aniqlashtirilgandan keyin bajaring.** Global Variables’dagi hisob holati saqlanadi. Oldingi versiyadan qolgan umumiy kunlik `halt` yangi broker kunigacha davom etishi mumkin. Noaniq order, risk yoki kunlik holatni blokni aylanib o‘tish uchun o‘chirmang.

v1.10 da zarar ortidan **60 daqiqa kutish**, **3 ketma-ket zarar bloki**, **07:00–20:00 sessiya**, juma cheklovlari hamda sessiya oxiri, hafta oxiri va yarim tunda vaqtga bog‘liq majburiy yopish olib tashlandi. **Bir paytda bitta pozitsiya va kunlik 2% himoya saqlandi.**

## Strategiya

Barcha hisoblar yopilgan shamlar asosida. `[1]` — oxirgi yopilgan, `[2]` — undan oldingi sham. M15 qat’iy filtri olib tashlandi.

BUY uchun:

- **M5:** EMA20[1] > EMA50[1], EMA20[1] > EMA20[3], ADX(14) kamida **16**, +DI > −DI.
- **M1 tasdiq:** signal bullish, close > EMA20[1]; tana diapazonning kamida **35%** i, yopilish shamning yuqoridagi **35%** qismida, diapazon ko‘pi bilan **2.5 ATR(14)**.
- **PULLBACK yoki BREAKOUT** kirishlaridan kamida biri bajariladi.

**PULLBACK:** oldingi sham diapazoni EMA20[2] ± **0.25 ATR** hududi bilan kesishadi; signal close oldingi sham high qiymatidan yuqori.

**BREAKOUT:** signal close o‘zidan oldingi **5 ta yopilgan shamning** eng katta high qiymatidan yuqori; signalning o‘zi shu beshtalikka kirmaydi. Close va M1 EMA20[1] orasidagi masofa ko‘pi bilan **1.5 ATR**.

SELL shartlari teskari: pasayuvchi M5 trend, bearish sham, pastdagi 35% ichida yopilish, oldingi low yoki beshta shamning eng kichik low qiymatidan past close. Ikkala kirish mos bo‘lsa jurnalga PULLBACK yoziladi. `InpEnablePullback` va `InpEnableBreakout` standart **true**; sinov uchun bittasini o‘chirish mumkin, ikkalasini o‘chirishga ruxsat berilmaydi.

M1 ATR(14) chegarasi **0.8–8 pip**. Kirish yangi M1 shamning dastlabki **5 soniyasida**, bir shamda bir marta tekshiriladi; kechikkan signal tashlab yuboriladi. Narx signal close qiymatidan **0.5 ATR** dan uzoqlashsa kirilmaydi. Spred ko‘pi bilan **1.2 pip** va SL masofasining **20%** i. Broker, marja, risk yoki boshqa himoya sharti bajarilmasa savdo ochilmaydi.

Bu parametrlar boshlang‘ich taxminlar; brokerda foydali ekanligi hali isbotlanmagan. M1 da spred va ijro xarajatlari natijaga kuchli ta’sir qiladi.

## Lot, SL/TP va kapital

- Har savdoga risk standart **0.5%**, ruxsat etilgan eng yuqori qiymat **1%**.
- $500 da 0.5% — **$2.50**; $50 da — **$0.25** risk budjeti.
- Lot brokerning kontrakti va `OrderCalcProfit` hisobiga moslanadi, volume step bo‘yicha pastga yaxlitlanadi. Minimal lot budjetga sig‘masa **savdo ochilmaydi**.
- SL bozor strukturasi va ATR asosida; standart minimal masofa **5 pip**, maksimal **15 pip**, brokerning stop masofalari ham hisobga olinadi.
- TP — boshlang‘ich risk masofasining **1.5 baravari**. BE **1R**, trailing **1.25R** dan keyin faollashadi; trailing masofasi 1.5 ATR. Boshlang‘ich R qayta ishga tushganda ham saqlanadi. Bajarilgan orderning haqiqiy risk budjeti oshsa robot kunlik blok qo‘yib yopishga urinadi; gaplarda maksimal haqiqiy zararni kafolatlab bo‘lmaydi. BE ning 0.3 pip narx ofseti komissiyadan keyingi sof zararsizlikni kafolatlamaydi.
- Komissiya uchun standart zaxira — to‘liq ochish/yopishga **$7 / lot**, qo‘shimcha risk zaxirasi **10%**. Bu brokerning haqiqiy hisob-fakturasi emas: hisob tarifini tekshiring. Spred narxlar farqida hisoblanadi. `InpCommissionPerLot` hisob valyutasida: USD bo‘lmagan hisobda tarifni qayta moslang. Micro hisob komissiyasi boshqa bo‘lishi mumkin; ikkala profil ham bir xil konservativ 7 qiymatidan boshlanadi, bu broker tarifi tasdig‘i emas. Haqiqatan komissiyasiz hisob bo‘lsagina broker tasdig‘i bilan 0 kiriting.

**Hisob nomi kontraktni tasdiqlamaydi.** Specification’da kontrakt 100 000 EUR, minimal lot 0.01 bo‘lsa, 0.01 lot uchun 1 pip taxminan $0.10. 5 pip SL xarajatlarsiz ham $0.50: $50 balans va 0.5% riskga sig‘maydi. Bunday instrumentga Micro profil yuklash kontraktni kichraytirmaydi. $50 uchun haqiqiy kichik kontraktli Micro demo kerak; $500 uchun ham marja yoki risk ayrim signallarni bloklashi mumkin.

## Himoya va ishlash chegaralari

- Martingale, grid va zarar ortidan lotni ko‘paytirish ishlatilmaydi. Foydali savdolar soniga kunlik limit yo‘q.
- Bir paytda hisobda faqat bitta pozitsiya; boshqa ochiq pozitsiya yoki buyurtma yangi kirishni bloklaydi.
- Kunlik zarar limiti **2%**: kun boshlanishining **balans asosidagi** qiymatiga nisbatan joriy equity tekshiriladi; yopilgan natija, xarajatlar va ochiq pozitsiya ta’sir qiladi. Limitda robot o‘z pozitsiyasini yopishga urinadi. Gap, slippage va aloqa uzilishi sabab aniq 2% da chiqish kafolatlanmaydi.
- Kun boshlanish balansi tarixdan tiklanadi, broker krediti risk equity dan chiqariladi. **Oldingi kundan qolgan floating zarar ham yangi kun limitiga kiradi; floating foyda esa balansga nisbatan zaxira yaratishi mumkin.** Masalan, balans $500, olib o‘tilgan floating foyda $3 bo‘lsa, chegara $490: $503 equity dan tushish $13 bo‘lishi mumkin. Bu **midnight equity** ga nisbatan aniq 2% drawdown o‘lchovi emas.
- Ish davomida hisobga pul kiritmang yoki yechmang: yangi pul o‘tkazmasi aniqlansa shu kun uchun savdo bloklanadi.
- Soat bo‘yicha cheklov yo‘q; odatda **24/5** ishlash broker kotirovkasi, taqvimi, spred va savdo ruxsatiga bog‘liq. Kecha/rollover va hafta oxirida pozitsiya qolishi mumkin: svop va narx uzilishi xavfi bor. Risk auditida yig‘ilgan manfiy `POSITION_SWAP` ham hisoblanadi.
- Ulanish/startupdan keyingi **60 soniya** kutish saqlangan; bu olib tashlangan zarardan keyingi tanaffus emas. Eski shamga qaytib kirish yo‘q. SL/TP brokerda turadi, BE/trailing va xavfsizlik yopishi uchun MT5 ishlashi va aloqa kerak.
- Hisob fayl qulfi bir terminalda takror ishga tushishni to‘sadi. Boshqa terminal/VPS dagi nusxa yoki qo‘lda savdo bilan muvofiqlashtirish qo‘llab-quvvatlanmaydi.
- Yuborilgan buyurtmaning javobi noaniq bo‘lsa, qayta jo‘natilmaydi. Holat tarix/brokerdan aniqlanmaguncha, restartdan keyin ham yangi kirish bloklanadi. Saqlangan holat MT5 Global Variables (F3) da turadi. Ularni sababini aniqlamasdan o‘chirmang; boshqa terminalga/VPS ga ko‘chirish holatni avtomatik ko‘chirmaydi. Holat yo‘qolsa ochiq pozitsiya taxmin asosida boshqarilmaydi: robot uni yopishga urinadi.

## Tekshirish tartibi va haqiqiy holat

**Ushbu muhitda MetaEditor va MT5 Strategy Tester mavjud emas: v1.10 MQL5 kompilyatsiyasi, real tick backtest va demo forward-test bajarilmadi.** Portable signal/risk arifmetikasini C++ bilan tekshirish MT5 kompilyatsiyasi yoki broker ijrosini tasdiqlamaydi. Bunday tekshiruvlarning aniq bajarilish holati to‘plamdagi test natijasida ko‘rsatiladi.

Oldingi hisobotdagi **36 savdo, 44.44% yutuq, −$3.17** — **v1.00** natijasi. Bu v1.10 uchun dalil emas. 36 savdoga qarab foyda chiqadigan parametrlarni tanlash mustaqil tasdiq bermaydi.

1. Kompilyatsiya: xatolar bo‘lmasin, ogohlantirishlar ham tekshirilsin.
2. Strategy Tester: brokerning aynan ishlatiladigan EURUSD belgisi, **M1**, **Every tick based on real ticks**, hisobga mos leverage va $500 yoki haqiqiy Micro uchun $50 balans. Broker komissiyasi va spredi hisobga kiritilganini tekshiring.
3. Nazorat uchun eski **`ea2e066` commitdagi v1.00** va yangi v1.10 ni **bir xil broker ma’lumoti, davr, balans, leverage va xarajatlarda** sinang; har versiyaning mos `.set` faylidan foydalaning. Turli bozor holatlarini qamrab oling.
4. Davrni vaqt tartibida o‘rgatish/sozlash va **mustaqil test** qismlariga ajrating. Mustaqil qismni ko‘rib parametrlarni qayta tanlamang. Kamida yuzlab savdo yig‘ilmasa, foizli xulosalar zaif bo‘ladi.
5. Sof foyda, o‘rtacha savdo natijasi, profit factor, maksimal drawdown, savdo soni, komissiya va spred oshishiga chidamlilikni baholang. Yutuq foizi va uning ishonch oralig‘ini ham bering; “80%” ni oldindan natija sifatida yozmang.
6. v1.10 da ikkala kirish yoqilgan, faqat PULLBACK va faqat BREAKOUT holatlarini oldindan belgilangan davrlarda taqqoslang. Boshqa parametrlarni bir vaqtda o‘zgartirmang. Ko‘proq savdo o‘z-o‘zidan ko‘proq foyda bermaydi.
7. Qayta ulanish, MT5 restart, minimal lot, katta spred, noaniq order javobi, kunlik stop va pozitsiyaning yangi kunga o‘tishini tekshiring. Keyin bir necha hafta demo forward-test bajaring.

## Savdo ochilmasa

MT5 **Experts** va tester **Journal** yozuvlarini saqlang: `SIGNAL BUY/SELL PULLBACK/BREAKOUT`, `REJECT`, broker retcode, lot, risk, spred va SL masofasi sababni ajratishga yordam beradi. `SUMMARY v1.10` yo‘nalishlar, kirish turlari, order urinishlari va rad etish toifalarini sanaydi. Broker xatosini faqat “savdo bo‘lmadi” bilan baholab bo‘lmaydi.

Yordam uchun `.set`, tester HTML/XLSX hisobot, Journal matni va Specification’ni yuboring. Parol yoki token yubormang. Riskni oshirib yoki minimal lotni majburlab himoyani chetlab o‘tmang.
