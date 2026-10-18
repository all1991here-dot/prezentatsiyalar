# v1.10 tekshiruv holati

Haqiqatan bajarildi:

- `MSDirection`, `MSValidBar`, `MSVolume` kodlari aynan .mq5 manbasidan ajratilib g++ C++17 bilan tekshirildi.
- 124 235 arifmetik tekshiruv: 0 xato; 12 000 lot holati va 5 000 signal simmetriyasi holati. Bu tarixiy savdolar emas.
- 20 statik tekshiruv: 0 xato. Olib tashlangan loss cooldown, zarar seriyasi, sessiya/juma, yarim tun yopish yo‘llari va saqlangan risk cheklovlari tekshirildi.
- Ikkala .set faylning 27 ta inputi manba bilan mos; qavslar va Git whitespace tekshiruvi o‘tdi.
- Portable qism SHA256: `878a6286a01d31c63133a01d03cead6aff94c3ad18e6c092f05b557183f80058`.
- Qayta bajarish: `python3 tests/check_portable.py` (Python3 + g++).

Bajarilmadi:

- v1.10 uchun to‘liq MetaEditor kompilyatsiyasi; .ex5 yaratilmagan.
- MT5 eventlari, broker ijrosi, overnight swap/risk va restart holatlarining funksional testi.
- v1.10 real tick backtest, out-of-sample va demo forward-test.
- Savdo soni, foyda yoki yutuq foizi oshishini tasdiqlash.

Foydalanuvchi yuborgan 36 savdo, 44.44% yutuq, -$3.17 hisobot v1.00 ga tegishli; v1.10 natijasi emas. C++ testi to‘liq MQL5 kompilyatsiyasi yoki real bozor sinovini almashtirmaydi.
