# L6. Kontent-loyihani yakunlash va retrospektiva — o‘qituvchi namunasi

**Bu sun’iy to‘ldirilgan misol. Jamoaning haqiqiy bajargan ishlari, mavjud PRlari yoki servis akkauntlariga dalil emas. A/B/C/D anonim o‘quv rollari. Talaba bu matnni o‘z natijasi sifatida ko‘chirmaydi.**

## Kontent-v1 qabul ro‘yxati — namuna
6 asosiy maqola `app/data/articles.json`da. IDlar: kutubxona, lms, dars-jadvali, dekanat, xavfsizlik, klublar. C01/C04ni A yozadi, D tekshiradi; C02/C03ni B yozadi, D tekshiradi; C05/C06ni C yozadi, A tekshiradi. Bu taqsimot o‘quv misoli.
Har birida title, category, summary, body va 3 bandli checklist mavjud. Mazmun haqiqiy universitetning xizmat vaqti deb ko‘rsatilmaydi; "o‘quv namuna" chegarasi saqlanadi. Kontent qabul holati o‘qituvchi ko‘rigi bilan jamoaning o‘z faylida qayd etiladi.
Content-v1: IDlar barqaror qoladi, L7da boshqa loyiha boshlanmaydi; shu olti maqola dasturiy mahsulotga o‘tadi. Lokal rasmiy tekshiruv uchun `python scripts/check_project.py` ishlatiladi. Bu skript mazmunning universitet qoidalariga haqiqatdan mosligini tekshira olmaydi.
Retrospektiva namunasi: yaxshi—qabul ro‘yxati qayta ishlashni kamaytirdi; qiyin—Review bitta kishiga bog‘landi. Amal: L7dan tekshiruvchi navbatchiligini B tashkil qiladi, har PRda ikkinchi a’zo review qiladi. Kengaytirish C07–C10 hali alohida backlogda; asosiy 6 maqola qabuliga avtomatik to‘siq emas.
