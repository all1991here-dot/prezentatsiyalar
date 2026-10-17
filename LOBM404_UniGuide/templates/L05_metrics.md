# L5. Oqim metrikalarini hisoblash va tahlil qilish

Talaba jamoasi to‘ldiradigan shablon. Faylni `team/` papkasiga shu nom bilan ko‘chiring.

**Jamoa / sana / to‘ldiruvchi:** ...

## Manba va chegaralar
Ma’lumot: `data/flow_data.csv` (sun’iy misol) yoki jamoaning alohida CSV fayli: ... . Haqiqiy natijani sun’iy ma’lumot bilan almashtirmang.
Kuzatuv [start, end): ... ; kalendar kunlar soni: ... ; WIP/age kesimi asof: ... .
Formulalar: lead=done−queued; cycle=done−started; throughput=oynada tugallangan ish/kuzatuv kuni; age=asof−started.
| ID | Lead kun | Cycle kun | Oynaga kiradimi? Sabab |
|---|---|---|---|
| ... | ... | ... | ... |
| Ko‘rsatkich | Qiymat | Izoh |
|---|---|---|
| O‘rtacha lead/cycle | ... | Faqat oynada tugallanganlar |
| Throughput | ... | ish/kun |
| WIP va har bir faol ish yoshi | ... | started≤asof; done yo‘q yoki done>asof |
`python scripts/metrics.py --json` chiqishini biriktiring. C10 nima uchun kuzatuvga kirmaydi? ... . C09 nima uchun WIP emas? ... . Nol va N/A farqi: ... .
## Qaror
Ma’lumotdan bitta dalil: ...; cheklov: ...; sinov qilinadigan yaxshilash: ... . SLE hisoblasangiz tanlanma, foiz va usulni aniq yozing; kichik misoldan kafolat chiqarmang.

**Topshiriladigan dalillar manzili:** ...
