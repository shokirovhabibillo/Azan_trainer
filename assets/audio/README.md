# Reference audio fayllari

Bu papkaga quyidagi fayl nomlari bilan **WAV (PCM16)** audiolar qo'shilishi
kerak (nomlar lib/data/phrase_catalog.dart faylidagi referenceAudioFile
qiymatlariga mos kelishi shart):

- azon_allohu_akbar.wav
- azon_ashhadu_laa_ilaaha.wav
- azon_ashhadu_anna_muhammadan.wav
- azon_hayya_alas_solah.wav
- azon_hayya_alal_falah.wav
- azon_allohu_akbar_closing.wav
- azon_laa_ilaaha_illalloh.wav
- bomdod_assolatu_khoyrum_minan_navm.wav
- iqomat_qad_qomatis_solah.wav

## Nima uchun aynan WAV (mp3 emas)?

v1.2'dan boshlab reference audio ham foydalanuvchi recordingi bilan
BIR XIL pipeline orqali o'tadi: WavDecoder → PitchContourExtractor →
YinPitchDetector. Bu sof Dart pipeline faqat PCM16 WAV formatini
tushunadi (hech qanday tashqi audio-codec kutubxonasi ishlatilmaydi).
Shuning uchun reference fayllar ham WAV (16-bit PCM, tavsiya etilgan
16000 Hz, mono) formatida bo'lishi kerak.

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
Sikah, yoki `unknown`). Hozircha **barcha yozuvlar `Maqam.unknown`**
qiymatiga ega, chunki hech qanday reference audio hali qo'shilmagan —
demak uning qaysi maqomda o'qilgani ham tasdiqlanmagan. Reference audio
qo'shilgach, tegishli `Phrase` yozuvidagi `maqam` qiymatini haqiqiy
audio tinglab, qo'lda (yoki kelajakdagi maqom-aniqlash moduli orqali)
to'g'ri qiymatga yangilang — hech qachon taxmin qilib to'ldirmang.
