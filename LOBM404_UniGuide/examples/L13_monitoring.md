# L13. Monitoring, hisobot va vositalarni taqqoslash — o‘qituvchi namunasi

**Bu sun’iy to‘ldirilgan misol. Jamoaning haqiqiy bajargan ishlari, mavjud PRlari yoki servis akkauntlariga dalil emas. A/B/C/D anonim o‘quv rollari. Talaba bu matnni o‘z natijasi sifatida ko‘chirmaydi.**

## Monitoring — sun’iy ma’lumot
| Sprint | Reja SP | DoD SP / velocity | Tafovut |
|---|---|---|---|
| S1 | 8 | 6 | −2 |
| S2 | 10 | 10 | 0 |
| S3 | 10 | 5 | −5 |
Velocity o‘rtachasi(6+10+5)/3=7SP/sprint. Tugallangan hajm21SP. Rejalangan yig‘indi28SP, US03 qayta rejalangani sabab bu28ta noyob ish pointi degani emas. S3dagi US08 sevimlilar keyingi versiyaga qoldiriladi, MVPga kiritilmaydi. Barcha qiymat sun’iy o‘quv misoli.
L5 oqimi: lead5kun, cycle2.6667kun, throughput0.6ish/kun, 10sentabr WIP3. Bu kontent fazasiga tegishli, uni dasturiy sprintning haqiqiy ishlash tezligi deb talqin qilmaymiz.
Trello—holat va WIP siyosatini sodda ko‘rsatish uchun; Jira—sprint/backlog va kuzatuv uchun; GitHub Projects—issue/PR bilan yaqin ish uchun. Amaldagi funksiyalar hisob tarifi va UIga bog‘liq; talaba har birida haqiqiy doska, filtr va dalilni tekshiradi. Bu fayl uchala servisda ish bajarilganini isbotlamaydi.
Integratsiya bo‘lmasa PRga Jira IDni va Jiraga PR havolasini qo‘lda yozish mumkin; avtomatik bog‘lanish deb ko‘rsatilmaydi. Qaror namunasi: release maqsadini saqlab, US08ni kechiktirish va regressiyaga quvvat berish; egasiPO.
