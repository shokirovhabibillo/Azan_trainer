# Reference audio fayllari

## v1.15: Iqomat uchun reference audio ENDI TO'LIQ (8/8 jumla)

Foydalanuvchi `Iqamat.mp3`ni (avval "hech qanday tanaffuс yo'q"
sababli avtomatik bo'linmagan edi) **o'zi qo'lda 8 ta jumlaga
ajratib**, WAV (PCM16, mono, 16000 Hz) formatida taqdim etdi:

- ✅ iqomat_allohu_akbar_opening.wav — Allohu akbar ×4 (~8.0s)
- ✅ iqomat_ashhadu_laa_ilaaha.wav — Ashhadu an laa ilaaha illalloh ×2 (~6.8s)
- ✅ iqomat_ashhadu_anna_muhammadan.wav — Ashhadu anna Muhammadar rosululloh ×2 (~6.1s)
- ✅ iqomat_hayya_alas_solah.wav — Hayya alas-solaah ×2 (~5.8s)
- ✅ iqomat_hayya_alal_falah.wav — Hayya alal-falaah ×2 (~7.3s)
- ✅ iqomat_qad_qomatis_solah.wav — Qod qoomatis-solaah ×2 (~5.7s)
- ✅ iqomat_allohu_akbar_closing.wav — Allohu akbar ×2 (~3.1s)
- ✅ iqomat_laa_ilaaha_illalloh.wav — Laa ilaaha illalloh ×1 (~0.7s)

Jami davomiylik (~43.5s) asl uzluksiz audio bilan **aynan mos** —
segmentatsiya to'g'riligini tasdiqlaydi (`test/iqomat_real_audio_test.dart`
orqali dasturiy ravishda ham tekshirilgan).

**Eslatma:** ikkita fayl nomi foydalanuvchi bergan nomlardan biroz
farq qilgani uchun (`iqomat_allohu_akbar.wav` → `_opening` qo'shildi,
`iqomat_qod_qoomatis_solah.wav` → `qad_qomatis` transliteratsiyasiga
moslashtirildi) loyihaga qo'shishda mos ravishda **qayta nomlandi** —
audio TARKIBI o'zgartirilmadi, faqat fayl nomi katalog bilan mos
kelishi uchun.

## v1.10: Lami, Kurd va Hijaz maqomlarida QO'SHIMCHA reference audio

Foydalanuvchi 3 ta to'liq (uzluksiz) azon yozuvini taqdim etdi —
"Lami", "Kurd" va "Hijaz" maqomlarida. Ularning barchasi avtomatik
jimlik-aniqlash (silence detection) orqali segmentlarga bo'lindi va
bir xil sxemaga (4+2+2+2+2+2 = 14 segment) moslab, 6 ta jumlaga
guruhlandi:

- ✅ azon_allohu_akbar_{lami,kurd,hijaz}.wav
- ✅ azon_ashhadu_laa_ilaaha_{lami,kurd,hijaz}.wav
- ✅ azon_ashhadu_anna_muhammadan_{lami,kurd,hijaz}.wav
- ✅ azon_hayya_alas_solah_{lami,kurd,hijaz}.wav
- ✅ azon_hayya_alal_falah_{lami,kurd,hijaz}.wav
- ✅ azon_allohu_akbar_closing_{lami,kurd,hijaz}.wav

**MUHIM — ochiq eslatma:** uchala yuklangan yozuvda ham "Laa ilaaha
illalloh" uchun alohida, aniq segment topilmadi (14 segmentlik naqsh
faqat 6 jumlaga yetadi, 7-jumla yo'q). Shuning uchun **hech bir
qo'shimcha maqom variantida 7-jumla (`azon_laa_ilaaha_illalloh`)
uchun reference audio yo'q** — bu jumlada ilova faqat standart
(Bayati) variantni ko'rsatadi. Bu — taxmin qilib to'ldirilmagan, ochiq
qoldirilgan holat.

**Segmentatsiya usuli haqida ochiq eslatma:** bu bo'linish audio
signalidagi JIMLIK oraliqlarining VAQT naqshiga (uchala faylda ham
bir xil chiqqan) asoslangan — men audio tarkibini tinglab
tasdiqlamadim (bu sandbox'da audio eshitish imkoniyati yo'q).
Fayllarni ilovada sinab, har bir jumla to'g'ri audio bilan mos
kelishini tekshiring — agar birortasi noto'g'ri chiqsa, xabar bering.

Yangi `lib/data/maqam_reference_catalog.dart` fayli shu variantlarni
jumla ID bo'yicha xaritalaydi (har bir jumla uchun endi 4 tadan
variant: Bayati, Lami, Kurd, Hijaz). Foydalanuvchi ilovada mos jumla
ekranida "Maqom" tanlovchisi orqali ular orasida almashtira oladi.

## v1.9: Azon uchun reference audio (Bayati maqomida)

Quyidagi 7 ta fayl — standart (asosiy) variant:

- ✅ azon_allohu_akbar.wav
- ✅ azon_ashhadu_laa_ilaaha.wav
- ✅ azon_ashhadu_anna_muhammadan.wav
- ✅ azon_hayya_alas_solah.wav
- ✅ azon_hayya_alal_falah.wav
- ✅ azon_allohu_akbar_closing.wav
- ✅ azon_laa_ilaaha_illalloh.wav

Shu sababli `lib/data/phrase_catalog.dart`da ushbu 7 jumlaning `maqam`
maydoni endi `Maqam.bayati` (foydalanuvchi tomonidan aniq tasdiqlangan
— taxmin qilinmagan).

## Hali qo'shilmagan fayllar

- ⬜ bomdod_assolatu_khoyrum_minan_navm.wav
- ⬜ iqomat_allohu_akbar_opening.wav
- ⬜ iqomat_ashhadu_laa_ilaaha.wav
- ⬜ iqomat_ashhadu_anna_muhammadan.wav
- ⬜ iqomat_hayya_alas_solah.wav
- ⬜ iqomat_hayya_alal_falah.wav
- ⬜ iqomat_qad_qomatis_solah.wav
- ⬜ iqomat_allohu_akbar_closing.wav
- ⬜ iqomat_laa_ilaaha_illalloh.wav

Bu fayllar nomlari `lib/data/phrase_catalog.dart` faylidagi
`referenceAudioFile` qiymatlariga mos kelishi shart. Format talabi —
**WAV (PCM16)** (pastga qarang).

## Nima uchun aynan WAV (mp3 emas)?

v1.2'dan boshlab reference audio ham foydalanuvchi recordingi bilan
BIR XIL pipeline orqali o'tadi: WavDecoder → PitchContourExtractor →
YinPitchDetector. Bu sof Dart pipeline faqat PCM16 WAV formatini
tushunadi (hech qanday tashqi audio-codec kutubxonasi ishlatilmaydi).
Sample rate istalgan qiymat bo'lishi mumkin (masalan 16000 yoki 22050
Hz) — u har bir fayldan dinamik o'qiladi, qattiq kodlanmagan. Muhim
shart faqat: 16-bit PCM va mono.

## Fayl mavjud bo'lmasa yoki noto'g'ri formatda bo'lsa nima bo'ladi?

Ilova buzilmaydi:
- Fayl umuman topilmasa → "Reference audio hali qo'shilmagan" holati
  ko'rsatiladi, Play/Pause/Stop tugmalari uchalasi ham o'chirilgan
  bo'ladi, Result ekranida "Reference audio mavjud emas — taqqoslash
  bajarilmadi." deb chiqadi.
- Fayl mavjud, lekin WAV/PCM16 sifatida o'qib bo'lmasa → aniq xato
  xabari ko'rsatiladi ("Reference audio o'qib bo'lmadi: ..."), hech
  qanday fake taqqoslash natijasi berilmaydi.

## Maqom metadatasi

Har bir jumla `lib/data/phrase_catalog.dart` ichida `maqam` maydoniga
ega (`Maqam` enum: Bayati, Nahawand, Ajam, Hijaz, Rast, Kurd, Saba,
Sikah, yoki `unknown`).

**v1.9'dan boshlab: Azonning 7 jumlasi — `Maqam.bayati`** (foydalanuvchi
tomonidan aniq tasdiqlangan, chunki ularning haqiqiy reference audiosi
Bayati maqomida ekanligi bevosita aytilgan — bu taxmin emas).

Reference audiosi hali qo'shilmagan qismlar (Bomdod qo'shimchasi,
Iqomatning barcha 8 jumlasi) — hamon `Maqam.unknown`. Ularning
audiosi qo'shilgach, maqomi haqiqiy tasdiq asosida (hech qachon
taxmin qilib emas) yangilanadi.
