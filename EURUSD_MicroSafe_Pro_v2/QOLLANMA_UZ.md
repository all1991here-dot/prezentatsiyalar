# EURUSD MicroSafe Pro v2.0

## Haqiqiy holat

Bu talablar asosida yangidan yozilgan Expert Advisor. Eski `EURUSD_MicroSafe_TrendEA_v1_2.mq5` va MT5 hisoboti taqdim etilmagan. Shu sababli eski kod auditi, zararli savdolar tahlili va eski/yangi natijalar taqqoslovi hali bajarilmagan. MT5, MetaEditor va broker real tick tarixi ushbu Linux muhitida yo‘q: MQL5 kompilyatsiyasi, strategiya backtesti yoki forward test muvaffaqiyati tasdiqlanmaydi. `.ex5` yaratilmagan. Foyda kafolatlanmaydi.

## O‘rnatish

1. MT5 → File → Open Data Folder → MQL5 → Experts ichiga `EURUSD_MicroSafe_Pro_v2.mq5` nusxasini joylang.
2. MetaEditor’da ochib F7 bosing. Xato va ogohlantirishlarni tekshiring; kompilyatsiya xatolari bo‘lsa savdoni boshlamang. Jurnalni keyingi tekshiruv uchun saqlang.
3. Avval alohida DEMO hisob oching; hisob valyutasi USD bo‘lsin. Micro demo uchun brokerning haqiqiy micro kontrakt spetsifikatsiyasini ishlating. Standard hisob kontraktini shunchaki “micro” deb nomlash yetarli emas.
4. Brokerning EURUSD, EURUSDmicro yoki boshqa EUR/USD suffiksli instrumentining M15 grafigiga bir dona EA qo‘ying. H1 indikatorlari avtomatik olinadi. Boshqa instrumentlar qabul qilinmaydi.
5. Inputs → Load orqali mos `.set` faylini yuklang. Algo Trading va EA savdo ruxsatini yoqing. DLL, WebRequest yoki API kaliti kerak emas.
6. Experts jurnalida ishga tushish va rad etish sabablarini tekshiring. EA ulanganda joriy shamdagi eski signal bo‘yicha savdo qilmaydi; keyingi M15 shamini kutadi.

`InpAllowRealAccount=false` ikkala profil uchun ham standart. Bu real hisobga ulanishni bloklaydi. Uni o‘zgartirish demo sinovining o‘rnini bosmaydi.

## Strategiya va signal

Faqat yopilgan H1 va M15 shamlari ishlatiladi; joriy sham indikatorlari orqali signal olinmaydi. Har yangi M15 shamining dastlabki 30 soniyasida ko‘pi bilan bitta baholash bo‘ladi. Shu davrda shartlar o‘tmasa signal keyinroq qayta urinilmaydi.

BUY: H1 EMA50 > EMA200, EMA50 o‘smoqda, +DI > −DI, ADX14 kamida 20, EMA oralig‘i H1 ATR14 ning kamida 0.25 qismi. M15 oldingi ikki shamning yuqori/past darajalari undan avvalgi ikki shamnikidan yuqori bo‘lishi kerak. Signal shami EMA20 ga tegib/yaqinlashib, undan yuqorida va oldingi sham maksimumidan yuqorida bullish yopiladi. SELL shartlari teskari. Bu oddiy ikki blokli strukturaviy filtr; to‘liq swing/pivot yoki “smart money” modeli emas.

Signal tanasi diapazonning kamida 45% ini tashkil qiladi; diapazon 2 ATR dan oshmaydi. ATR14 3–25 pip, spred ko‘pi bilan 1.5 pip. Signal yopilishidan narx 0.4 ATR dan uzoqlashsa kirilmaydi. Shu filtrlar savdolarni kamaytirishi mumkin; ko‘p yoki foydali savdo va’da qilinmaydi. Yangiliklar kalendari filtri mavjud emas; kuchli xabarlar vaqtida EA ni qo‘lda to‘xtatish mumkin.

## Risk, hisob va lot

Ikkala profil ham 0.5% risk bilan boshlanadi. `InpRiskPercent` faqat 0.5–1.0 oralig‘ida. $50 uchun boshlang‘ich budjet $0.25, $500 uchun $2.50. Bu summa avtomatik lotni hisoblash budjeti; doim to‘liq sarflanmaydi. Broker minimum loti budjetdan oshsa **savdo ochilmaydi**. Ayniqsa $500 Standard hisobda ko‘p signal minimal lot sabab rad etilishi mumkin: bu himoya, xato emas.

`OrderCalcProfit` hisob valyutasida broker kontrakti, tick qiymati va real lot spetsifikatsiyasi bo‘yicha riskni hisoblaydi. Micro lotga universal “100 ga bo‘lish” ishlatilmaydi. Lot pastga yaxlitlanadi. Hisoblashga ruxsat etilgan deviation va 15% xarajat zaxirasi qo‘shiladi; ular risk budjetining ichida. Bu broker komissiyasining aniq modeli emas. Stopdagi gap/slippage yoki broker xarajatlari katta bo‘lsa haqiqiy zarar budjetdan oshishi mumkin. Market execution’da deviation mutlaq narx kafolati emas.

SL kamida 1.8 ATR va yaqin struktura ortida; broker minimal stop masofasi ham hisobga olinadi. Stop 4 ATR dan uzoq bo‘lsa savdo rad etiladi. TP boshlang‘ich stop masofasining 2 baravari. Break Even 1R da, ochilish narxidan 0.2 pip narida; komissiya sabab bu sof zararsizlikni kafolatlamaydi. Trailing 1.5R dan keyin 1.5 ATR bilan yuradi. SL faqat foydali yo‘nalishda o‘zgaradi; freeze/stops cheklovlari tekshiriladi. Brokerdagi SL/TP terminal uzilganda ham qoladi, lekin BE/trailing va vaqt bo‘yicha yopish ishlamaydi.

TP masofasi saqlanib, undan boshlang‘ich R qayta hisoblanadi. Ochiq pozitsiyaning TP sini qo‘lda o‘zgartirmang. EA o‘z pozitsiyasida SL yoki TP yo‘qligini ko‘rsa, yopishga urinadi va natijani yozadi. Broker rad etsa yoki aloqa bo‘lmasa yopish kafolatlanmaydi.

## Zarar va vaqt himoyasi

- Yakunlangan zararli pozitsiyadan keyin kamida 60 daqiqa yangi kirish yo‘q. Qisman yopilishlar alohida zarar deb sanalmaydi; yakunlangan pozitsiyaning kirish/chiqish komissiyasi, fee, swap va P/L jamlanadi.
- Joriy broker kunida yakunlangan ketma-ket 3 zarar: keyingi broker kunigacha yangi kirish bloklanadi. Nolli/foydali natija ketma-ketlikni uzadi; zarar sovish vaqti esa keyingi kunga ham o‘tadi. Tarix to‘liq yuklanishi kerak. Netting reversal tarixi aniqlansa fail-closed holati qo‘llanadi; alohida hisobdan foydalaning.
- Hisob equity bazasidan 2% pasayish: kunlik blok va EA ning o‘z pozitsiyasini yopishga urinish. Realizatsiya qilinmagan zarar ham hisobga olinadi. Budjet qolgan kunlik zaxiradan oshmaydi. Foydali savdolar uchun son cheklovi yo‘q.
- Baza birinchi o‘rnatishda ulanishdagi equity, keyingi kunlarda birinchi olingan tick equity qiymati. Bu brokerning aniq yarim tungi equity tarixini qayta tiklamaydi. MT5 tun bo‘yi o‘chiq bo‘lsa ochilishdagi gap yangi bazagacha yuz bergan bo‘lishi mumkin. Ochiq EA pozitsiyasi yangi kunga o‘tgan bo‘lsa shu kun bloklanadi va u yopishga yuboriladi.
- Savdo davrida depozit/yechish qilmang: equity himoyasi ularni alohida ajratmaydi. Alohida balance tarzida yozilgan broker to‘lovlari pozitsiya streak hisobiga bog‘lanmasligi mumkin. Ular hisob equity limitiga ta’sir qiladi.
- Savdo soati 07:00–21:00, juma yangi kirish 16:00 dan blok, 20:00 dan EA pozitsiyasini yopishga urinish. Barchasi **broker server vaqti**, Toshkent yoki UTC emas. DST va broker jadvaliga moslang. Yakshanba/shanba kirish yo‘q.

## Qayta ishga tushish va cheklovlar

Kun bazasi, blok va baholangan sham terminal Global Variables orqali saqlanadi. Hisob, broker/symbol hash va magic bo‘yicha ajratiladi; tester alohida prefiksdan foydalanadi. Terminalning ushbu ma’lumotlarini o‘chirmang, boshqa terminalga ko‘chishni oddiy qayta ishga tushish deb hisoblamang. MT5 Global Variables uzoq vaqt ishlatilmasa o‘chishi mumkin. Magic yoki terminalni almashtirish saqlangan himoyani chetlab o‘tishi mumkin; bunday qilmang.

Har bir yuborishdan oldin sham identifikatori saqlanadi. Noaniq timeout bo‘lsa order shu shamda avtomatik qayta yuborilmaydi. Aloqa tiklanganda 60 soniya kutish va eski signalni tashlash bor. Qisqa uzilish timer kuzatuviga tushmasligi mumkin; kechikkan sham va kotirovka tekshiruvlari qo‘shimcha himoya beradi. Operatsion tizim/server soati to‘g‘ri bo‘lishi kerak.

**Bitta alohida hisobda faqat bitta EA nusxasi** ishlating. Hisobda istalgan ochiq pozitsiya yoki pending order bo‘lsa yangi kirish bloklanadi. Bu bir nechta terminal/EA o‘rtasida atomar blok emas: parallel robotlar yoki qo‘lda bir paytning o‘zida order yuborish qo‘llab-quvvatlanmaydi. Begona pozitsiyalar avtomatik yopilmaydi. Netting hisobda manual savdoni EA pozitsiyasiga qo‘shmang. Martingale, grid va lotni yo‘qotishdan keyin oshirish mavjud emas.

## Diagnostika

Experts jurnalidagi `NO SIGNAL` — strategiya sharti yo‘q; `REJECT` — spred, ATR, trend, soat, risk, margin, tarix yoki boshqa sabab bilan rad; `SIGNAL` — strategiya tasdig‘i; `ORDER` — rejalangan lot/SL/TP/budjet; `ENTRY`, `MODIFY SL`, `CLOSE` — broker retcode, tavsif, order/deal va terminal xatosi; `DEAL` — haqiqiy bajarilish va xarajatlar. Broker javobining muvaffaqiyati tekshiriladi, avtomatik kirish retry yo‘q. SL boshqaruvi uchun olingan yangi narxlar bilan qayta urinishlar bo‘lishi mumkin.

## Majburiy sinov protokoli

1. Kompilyatsiya: MT5 build, xato/ogohlantirishlar va jurnalni saqlang. Kodni tahlil qilish kompilyatsiya o‘rnini bosmaydi.
2. Tester → EURUSD broker instrumenti → M15 → **Every tick based on real ticks**. Broker tarixida real ticks yetishmasa modelni haqiqiy ticks deb atamang; Journal/model sifatini tekshiring. Micro va Standard uchun alohida tester spetsifikatsiyasini tekshiring: contract size, volume min/step, leverage, commission, spread, swaps, StopsLevel.
3. USD depozit: mos ravishda 50 va 500. Ikkala `.set` bilan boshlang. Grafik timeframe M15; H1 tarixida kamida 205 yopilgan sham va indikator isishi uchun sinov boshlanishidan oldin qo‘shimcha tarix bo‘lsin.
4. Mavjud to‘liq davrni oldindan chronologik 60% ishlab chiqish, 20% tekshirish, 20% yakuniy mustaqil davrga ajrating. Yakuniy davrga qarab parametr tanlamang. Kamida turli trend, yon bozor, katta spred va yangilik kunlarini qamrab olsin. Imkon bo‘lsa 24+ oy, keyin boshqa broker real ticks bilan mustaqil tekshiruv. Bu davrlar tavsiya, bajarilgan sinov emas.
5. Eski va yangi EA bir xil tick tarixi, sana, depozit, leverage, komissiya va instrumentda ishlasin. Eski EA kirish parametrlarini ham saqlang. Hisobot va Experts/Journal eksportini oling.
6. Maxsus holatlar: minimum lot budjetdan katta; 0.5/1% risk; 3 zarar; 60 daqiqa; kun almashishi; floating equity −2%; juma; uzilish; qayta ishga tushish; keng spred; broker reject; qisman ijro; SL/TP yo‘qligi; manual pozitsiya. Gaplarda limitdan oshish ehtimolini ham o‘lchang. Tester uzilishlarni to‘liq model qilmaydi — demo terminalda alohida sinang.
7. O‘zgartirilmagan parametrlar bilan kamida 4–8 hafta forward DEMO kuzating. Savdo soni kam bo‘lsa davrni uzaytiring. Real hisobni yoqish testning majburiy natijasi emas.

Hisobot jadvali:

| Ko‘rsatkich | v1.2 | v2.0 in-sample | v2.0 out-of-sample | v2.0 demo |
|---|---|---|---|---|
| Davr / broker / tick sifat | Kutilmoqda | Bajarilmagan | Bajarilmagan | Bajarilmagan |
| Net profit / profit factor | — | — | — | — |
| Equity max drawdown ($ / %) | — | — | — | — |
| Savdolar / win rate / expectancy | — | — | — | — |
| Eng uzun zarar ketma-ketligi | — | — | — | — |
| Xarajatlar / riskdan oshish | — | — | — | — |

Eski zararlarni tahlil qilish uchun eski `.mq5`, ishlatilgan `.set`, to‘liq HTML backtest hisoboti va Experts/Journal loglarini yuboring. Savdolarni H1 trend, M15 struktura, signal sham, entry spredi, ATR, vaqt, SL masofasi, haqiqiy lot, komissiya va exit sababi bo‘yicha birma-bir tasniflash kerak. Ushbu fayllarsiz mavjud zarar sababi haqida xulosa chiqarilmadi.
