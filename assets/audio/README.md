# Reference audio fayllari

## v1.9: Azon uchun reference audio ENDI MAVJUD (Bayati maqomida)

Quyidagi 7 ta fayl foydalanuvchi tomonidan taqdim etilgan, tekshirilgan
(WAV, PCM16, mono, 22050 Hz) va loyihaga qo'shilgan:

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
