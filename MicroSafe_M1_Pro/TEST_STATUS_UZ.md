# Tekshiruv holati

## Haqiqatan bajarilgan

- Kodning portable `MSDirection` va `MSVolume` qismi aynan manbadan ajratilib, g++ C++17 bilan kompilyatsiya qilindi.
- 12 000 lot/risk holati va 5 000 BUY/SELL simmetriya holati hamda maqsadli chekka holatlar tekshirildi.
- Natija: 109 101 arifmetik tekshiruv, 0 xato. Bular tarixiy savdolar emas.
- 30 ta input ikkala .set faylida koddagi qiymatlarga mosligi va qavslar muvofiqligi tekshirildi.
- Portable qism SHA256: `779ab962ff47197e5b7920d1d75292c54c999f9afb7ff79d0fc8becbef130026`.
- Qayta bajarish: `python3 tests/check_portable.py` (Python 3 va g++ kerak; vaqtinchalik katalog ishlatiladi).

## Bajarilmagan

- To‘liq .mq5 MetaEditor kompilyatsiyasi va .ex5 yaratish.
- MT5 eventlari, broker order yuborish, kunlik holat/restartni real terminalda funksional sinash.
- Real tick backtest, out-of-sample, demo forward-test.
- 80% yoki boshqa yutuq foizi hamda daromadlilikni tasdiqlash.

Portable test MQL5 kompilyatsiyasi emas: u faqat platformadan mustaqil signal va lot arifmetikasini tekshiradi. MT5 API chaqiruvlari, ijro, kundalik zarar holati va terminal voqealari ushbu harness doirasiga kirmaydi. Real hisob bloki standart holatda yoqilgan.
