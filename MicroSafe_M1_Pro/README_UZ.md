# EURUSD MicroSafe M1 Pro — o‘zbekcha qo‘llanma

Robot EURUSD uchun M1 da BUY/SELL signallarini o‘zi tekshiradi va shartlar bajarilganda savdo qiladi. Har daqiqada savdo ochish majburiyati yo‘q: natija BUY, SELL yoki signal yo‘q bo‘lishi mumkin.

**80% yutuq tasdiqlanmagan va kafolatlanmaydi.** Robot signalga yutuq ehtimoli bermaydi. Strategiya yangi; haqiqiy tickli sinov va demo kuzatuvi zarur. Yuqori yutuq ulushi o‘zi foydalilikni anglatmaydi: komissiya, spred va yirik zararlar ham hisoblanadi.

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

Real hisob standart holatda bloklangan. EA narx yo‘nalishi yoki signalning yutuq ehtimolini mashinaviy o‘rganish bilan hisoblamaydi; u ochiq yozilgan texnik qoidalarga amal qiladi. Bu blokni olib tashlash robot sinovdan o‘tganini bildirmaydi.

## Strategiya

Barcha hisoblar yopilgan shamlar asosida. `[1]` — oxirgi yopilgan, `[2]` — undan oldingi sham.

BUY uchun:

- **M15:** EMA50[1] > EMA200[1], EMA50[1] > EMA50[3].
- **M5:** EMA20 > EMA50, ADX(14) kamida 18, +DI > −DI.
- **M1 qaytish:** oldingi sham EMA20[2] ga tegishi yoki 0.15 ATR masofagacha yaqinlashishi kerak.
- **M1 tasdiq:** signal shami bullish; close EMA20 va oldingi sham high qiymatidan yuqori. Tana diapazonning kamida 40%; diapazon ko‘pi bilan 2.5 ATR.

SELL shartlari buning teskarisi. M1 ATR(14) chegarasi **0.8–8 pip**. Kirish yangi M1 shamning dastlabki **5 soniyasida** tekshiriladi; kechikkan signal tashlab yuboriladi. Spred ko‘pi bilan **1.2 pip** va SL masofasining **20%** i bo‘lishi kerak. Sessiya, marja, risk yoki boshqa himoya sharti bajarilmasa savdo ochilmaydi.

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
- Zarar bilan yopilgan savdodan keyin **60 daqiqa** tanaffus. Bir kunda ketma-ket **3 zarar** bo‘lsa, yangi broker kunigacha to‘xtash.
- Kunlik zarar limiti **2%**: kunlik yopilgan natija, xarajatlar va joriy ochiq zarar hisobga olinadi. Limitda robot o‘z pozitsiyasini yopishga urinadi. Gap, slippage va aloqa uzilishi sabab aniq 2% da chiqish kafolatlanmaydi.
- Kun boshlanish balansi tarixdan tiklanadi. Broker krediti/bonusi risk equity qiymatidan chiqariladi; bonus zarar uchun qo‘shimcha budjet yaratmaydi. Avvalgi kun pozitsiyasining aynan yarim tundagi floating qiymati robot uni kuzatmagan bo‘lsa noma’lum: bu hisob **midnight equity** bo‘yicha aniq drawdown emas.
- Ish davomida hisobga pul kiritmang yoki yechmang: yangi pul o‘tkazmasi aniqlansa shu kun uchun savdo bloklanadi.
- Sessiya **07:00–20:00**, 20:00 da majburiy chiqish; juma yangi kirish **16:00** da to‘xtaydi, chiqish **19:00** da. Bular **broker server vaqti**, Toshkent vaqti emas. Broker vaqt zonasini va yozgi vaqt o‘zgarishini tekshiring.
- Ulanish/startupdan keyin kutish ishlaydi; eski shamga qaytib kirish yo‘q. SL/TP brokerda turadi, BE/trailing va majburiy chiqish esa MT5 ishlashi va aloqa bo‘lishini talab qiladi.
- Hisob fayl qulfi bir terminalda takror ishga tushishni to‘sadi. Boshqa terminal/VPS dagi nusxa yoki qo‘lda savdo bilan muvofiqlashtirish qo‘llab-quvvatlanmaydi.
- Yuborilgan buyurtmaning javobi noaniq bo‘lsa, qayta jo‘natilmaydi. Holat tarix/brokerdan aniqlanmaguncha, restartdan keyin ham yangi kirish bloklanadi. Saqlangan holat MT5 Global Variables (F3) da turadi. Ularni sababini aniqlamasdan o‘chirmang; boshqa terminalga/VPS ga ko‘chirish holatni avtomatik ko‘chirmaydi. Holat yo‘qolsa ochiq pozitsiya taxmin asosida boshqarilmaydi: robot uni yopishga urinadi.

## Tekshirish tartibi va haqiqiy holat

**Ushbu muhitda MetaEditor va MT5 Strategy Tester mavjud emas: MQL5 kompilyatsiyasi, real tick backtest va demo forward-test bajarilmadi.** Portable signal/risk arifmetikasini C++ bilan tekshirish MT5 kompilyatsiyasi yoki broker ijrosini tasdiqlamaydi. Bunday tekshiruvlarning aniq bajarilish holati to‘plamdagi test natijasida ko‘rsatiladi.

Eski `EURUSD_MicroSafe_TrendEA_v1_2.mq5` manbasi va uning savdoli hisoboti mavjud emas; eski zararlarning sababi va ushbu versiya bilan foydalilik taqqoslovi bajarilmagan. Oldingi v2 hisobotidagi **0 savdo** ushbu yangi M1 strategiyaning natijasi emas.

1. Kompilyatsiya: xatolar bo‘lmasin, ogohlantirishlar ham tekshirilsin.
2. Strategy Tester: brokerning aynan ishlatiladigan EURUSD belgisi, **M1**, **Every tick based on real ticks**, hisobga mos leverage va $500 yoki haqiqiy Micro uchun $50 balans. Broker komissiyasi va spredi hisobga kiritilganini tekshiring.
3. Avval qisqa davrda ishga tushish va savdo/rad etish sabablarini tekshiring; keyin turli trend, diapazon va keskin harakatli bir necha yillik ma’lumotni sinang.
4. Davrni vaqt tartibida o‘rgatish/sozlash va **mustaqil test** qismlariga ajrating. Mustaqil qismni ko‘rib parametrlarni qayta tanlamang. Kamida yuzlab savdo yig‘ilmasa, foizli xulosalar zaif bo‘ladi.
5. Sof foyda, o‘rtacha savdo natijasi, profit factor, maksimal drawdown, savdo soni, komissiya va spred oshishiga chidamlilikni baholang. Yutuq foizi va uning ishonch oralig‘ini ham bering; “80%” ni oldindan natija sifatida yozmang.
6. Qayta ulanish, MT5 restart, minimal lotdan kichik risk, katta spred, kunlik stop va zarar seriyasini alohida tekshiring. Keyin bir necha hafta demo forward-test bajaring.

## Savdo ochilmasa

MT5 **Experts** va tester **Journal** yozuvlarini saqlang: `SIGNAL`, `NO SIGNAL`, `REJECT`, buyurtma javobi/retcode, lot, risk, spred va SL masofasi sababni ajratishga yordam beradi. Broker xatosini faqat “savdo bo‘lmadi” bilan baholab bo‘lmaydi.

Yordam uchun `.set`, tester HTML/XLSX hisobot, Journal matni va Specification’ni yuboring. Parol yoki token yubormang. Riskni oshirib yoki minimal lotni majburlab himoyani chetlab o‘tmang.
