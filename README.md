# Azon Trainer — v1.15 (Iqomat Reference Audio Complete)

## v1.15 — Iqomat na'muna audiosi endi TO'LIQ (8/8)

Foydalanuvchi avvalgi `Iqamat.mp3`ni (jimlik-aniqlash ishlamagani
sababli avtomatik bo'linmagan edi) **o'zi qo'lda 8 ta jumlaga
ajratib**, WAV (PCM16/mono/16000Hz) formatida taqdim etdi — shu
jumladan avval yo'q deb aytilgan "Qod qoomatis-solaah" ham.

Ikkita fayl nomi katalogdagi nomlardan ozgina farq qilgani uchun
(`iqomat_allohu_akbar.wav` → `_opening.wav`,
`iqomat_qod_qoomatis_solah.wav` → `iqomat_qad_qomatis_solah.wav`)
mos ravishda qayta nomlandi — **audio tarkibi o'zgartirilmadi**,
faqat fayl nomi.

Jami 8 fayl davomiyligi (~43.5s) asl uzluksiz audio bilan **aynan
mos** — bu segmentatsiya to'g'riligini dasturiy ravishda tasdiqlaydi
(`test/iqomat_real_audio_test.dart`, HAQIQIY asset yuklash zanjiri
orqali, fake emas).

Endi Iqomat rejimida barcha 8 jumlada "Namuna ovoz" tugmasi ishlaydi
va tahlil natijasida reference bilan solishtirish (pitch + duration)
Azon bilan bir xil tarzda ko'rinadi.

---



## v1.14 — Real-vaqtli Pitch Counter + Ovoz darajasi

Mashq qilish vaqtida (ovoz yozilayotganda) endi ekranda:
- **Jonli "Farq (deviation)" grafigi** — reference audio konturi
  (oldindan hisoblangan) fon sifatida, foydalanuvchi ovozi esa vaqt
  o'tishi bilan jonli chiziladi
- **Ovoz darajasi (volume) o'lchovchi** — pitch'dan mustaqil, alohida
  chiziq/foiz ko'rinishida

**MUHIM — texnik xavf va ochiq eslatma:** `record` paketining oqim
(`startStream`) API'sini bu sandbox muhitida internet aloqasi
yo'qligi sababli paket manba kodidan bevosita tasdiqlab bo'lmadi —
faqat umumiy, ishonchli bilim asosida ishlatildi. Shu sababli:
- Agar bu API chaqiruvi ishlamasa, `RealtimeAudioRecorderService`
  **avtomatik ravishda eski, tasdiqlangan fayl-asosidagi
  `AudioRecorderService`ga o'tadi** (fallback) — bu holatda
  foydalanuvchi jonli grafikni ko'rmaydi ("Jonli grafik bu qurilmada
  mavjud emas — ovoz baribir yoziladi" xabari chiqadi), LEKIN ovoz
  yozish va undan keyingi (post-hoc) tahlil **hech qanday o'zgarishsiz
  ishlayveradi**.
- Bu — qurilmada sinab ko'rilishi SHART bo'lgan yagona qism. Agar
  jonli grafik ishlamasa, xato matnini yuboring — faqat shu bitta
  faylni (`realtime_audio_recorder_service.dart`) tuzatish kifoya
  bo'ladi, chunki qolgan barcha mantiq (pitch hisoblash, volume, WAV
  yozish) undan mustaqil va alohida test qilingan.

**Arxitektura (yangi, mustaqil fayllar):**
- `lib/services/analysis/realtime_pitch_analyzer.dart` — freym-freym
  YIN chaqiradi (YIN o'zi o'zgartirilmagan)
- `lib/services/analysis/voice_level_analyzer.dart` — RMS asosida
  ovoz darajasi, pitch'dan mustaqil
- `lib/services/audio/streaming_wav_writer.dart` — oqim baytlaridan
  `WavDecoder` bilan bayt darajasida mos WAV fayl yozadi (round-trip
  test bilan tasdiqlangan)
- `lib/services/analysis/reference_contour_precomputer.dart` —
  reference konturni oldindan hisoblaydi (mavjud
  `PitchContourExtractor`ni qayta ishlatib)
- `lib/services/audio/realtime_audio_recorder_service.dart` — yuqoridagi
  xavfni yolg'iz o'zida izolyatsiya qiladigan, fallback'li wrapper
- `lib/widgets/live_pitch_deviation_meter.dart`,
  `lib/widgets/voice_level_meter.dart` — UI

**Mavjud funksiyalarga tegilmadi:** `phrase_practice_screen.dart`da
FAQAT recorder implementatsiyasi almashtirildi (bir xil
`start/stop/cancel/dispose` interfeysi bilan) va jonli grafik UI
qo'shildi — recording, tahlil, maqom tanlash, jumlalar orasida
o'tish arxitekturasi o'zgarishsiz qoldi.

---



## v1.13 — Majburiy "Muhim ma'lumotlar" onboarding

Ilova birinchi marta ochilganda, foydalanuvchi 4 sahifali (tajvid,
Hanafiy mazhabidagi azon tartibi — 23.04.2025 fatvo asosida, ayollar
masalasi) majburiy ma'lumot bilan tanishtiriladi, so'ng checkbox +
tasdiqlash orqali ilovaga kiradi. Bu holat `SharedPreferences`da
(`onboarding_completed`) doimiy saqlanadi — keyingi ochilishlarda
qayta chiqmaydi. Home ekranidagi ℹ️ tugmasi orqali istalgan payt
qayta ochish mumkin (cheklovsiz "ko'rib chiqish rejimi").

**O'qishni "sakratib o'tish"ning oldini olish:** har bir sahifa uchun
matn uzunligiga qarab hisoblangan **minimal o'qish vaqti** (220
so'z/daqiqa, kamida 6s) va **pastgacha yetib borish** sharti
bajarilmaguncha "Davom etish" tugmasi o'chirilgan turadi. Qo'shimcha
himoya sifatida, tez "fling" (barmoqni otib yuborish) tezligi
cheklangan — lekin oddiy tortib scroll qilish va yuqoriga qaytib
qayta o'qish erkin.

**Yangi dependency:** yo'q. Manba havolasi (fatvo linki) `url_launcher`
o'rniga **tanlab-nusxalanadigan matn** sifatida ko'rsatildi — chunki
loyihada oldin yangi paket qo'shish (`record`) Gradle bilan ko'p
muammo keltirib chiqargan edi, va bu bitta havola uchun shu xavfni
qayta tug'dirishga arzimaydi deb topildi.

**Mavjud funksiyalarga tegilmadi:** Azon, Bomdod, Iqomat, recording-
state, reference audio, pitch/duration tahlili, maqomlar — barchasi
`diff` bilan tasdiqlangan holda **o'zgarishsiz** qoldi. Faqat
`main.dart` (ilova kirish nuqtasi onboarding tekshiruvidan o'tadi) va
`home_screen.dart`ga (ℹ️ tugmasi) minimal, izolyatsiya qilingan
integratsiya qo'shildi.

---



## v1.12 — "V2 FIX" bo'yicha topilmalar va holat

**1) Iqomat MP3 segmentatsiyasi — BLOKLANGAN, foydalanuvchi javobini kutmoqda.**

`Iqamat.mp3` (video fayl, h264+AAC, 50.3s) turli jimlik-aniqlash
chegaralarida (-20dB dan -40dB gacha, 0.05s dan 0.5s gacha davomiylik)
sinovdan o'tkazildi — **audio boshidan oxirigacha (~43.5s) hech qanday
ichki tanaffuс topilmadi** (faqat oxirida 0.05-0.1s mikro-uzilishlar,
ular ham 7 jumla chegarasiga to'g'ri kelmaydi). Bu — Iqomat *tez*
o'qilgani sababli (Azondan farqli, u cho'ziladi). Diniy matn aniqligi
muhim bo'lgani sababli, bu fayl **taxminiy vaqt bo'yicha bo'linmadi** —
foydalanuvchidan aniq vaqt chegaralari yoki tanaffusli qayta yozuv
so'ralmoqda.

**2) Pitch/Pitch Contour/Duration Iqomat uchun ko'rinmasligi — KOD
DARAJASIDA XATO TOPILMADI.**

Tekshiruv: `grep -rn "PhraseCategory\." lib/screens/ lib/services/analysis/`
— **hech qanday natija chiqmadi**. Bu tasdiqlaydi: pitch/duration
tahlil pipeline'i va Result ekrani **kategoriyaga (Azon/Bomdod/Iqomat)
umuman bog'liq emas** — ular faqat `Phrase` obyektining
`referenceAudioFile`/matn maydonlaridan foydalanadi. `ResultScreen`da
Pitch/Duration `MetricTile`lari va Pitch Contour bo'limi **shartsiz**
(faqat `result.pitchContour.isNotEmpty`ga qarab) chiziladi — reference
mavjudligidan yoki kategoriyadan qat'i nazar.

Bu — `test/iqomat_pipeline_test.dart` orqali **kod darajasida
isbotlandi** (haqiqiy audio fayl kerak emas, mavjud fake-checker
pattern'i orqali): Iqomat jumlasi uchun pitch, pitch contour, duration,
reference comparison — barchasi Azon bilan **bir xil natija beradi**.

**Ehtimoliy sabab:** foydalanuvchi eski (v1.7'dan oldingi) APK
build'ini sinagan bo'lishi mumkin, yoki "Pitch yo'q" degani aslida
"Reference audio yo'q" bilan aralashtirilgan bo'lishi mumkin (ikkalasi
alohida-alohida ko'rsatiladi). Eng so'nggi ZIP'ni build qilib qayta
sinab ko'rishni so'rayman — agar muammo davom etsa, Result ekranining
skrinshotini yuboring, aniq diagnostika qilaman.

**3) "type = iqomat" identifikatori — allaqachon mavjud, yangi tizim
kerak emas.** `Phrase.category` maydoni (`PhraseCategory.iqomat`)
aynan shu vazifani bajaradi — reference audio qidiruv zanjiri
(`referenceAudioFile` → `ReferenceAudioChecker` → `ReferenceAudioLoader`
→ `PitchAnalyzer`/`DurationAnalyzer`) kategoriyani UMUMAN bilmaydi,
faqat fayl nomi bilan ishlaydi — bu allaqachon Azon uchun ishlagan
bir xil, umumiy mexanizm. Barcha 8 ta Iqomat jumlasining
`referenceAudioFile` qiymatlari (masalan
`iqomat_allohu_akbar_opening.wav`) allaqachon to'g'ri belgilangan —
faqat haqiqiy fayllar `assets/audio/`da yo'q.

**O'zgargan kod:** **YO'Q.** Faqat bitta yangi test fayli
(`test/iqomat_pipeline_test.dart`) qo'shildi — chunki tekshiruv hech
qanday tuzatish talab qiladigan xato topmadi.

---



## v1.11 yangiliklari (qisqacha)

**Muhim diniy-mazmuniy tuzatish:** foydalanuvchi (mahalliy Hanafiy
amaliyot asosida) v1.8'da kiritilgan Iqomat aytilish sonlari
**noto'g'ri** ekanligini aniqladi. To'g'irlandi:

| Jumla | v1.8 (noto'g'ri) | v1.11 (to'g'ri) |
|---|---|---|
| Allohu akbar (ochish) | 2 | **4** |
| Ashhadu an laa ilaaha illalloh | 1 | **2** |
| Ashhadu anna Muhammadar rosulullohi | 1 | **2** |
| Hayya alas-solaah | 1 | **2** |
| Hayya alal-falaah | 1 | **2** |
| Qod qoomatis-solaah | 2 | 2 (o'zgarmadi) |
| Allohu akbar (yopish) | 2 | 2 (o'zgarmadi) |
| Laa ilaaha illalloh | 1 | 1 (o'zgarmadi) |

Ya'ni Iqomat endi Azon bilan **bir xil sonlarda** aytiladi (4,2,2,2,2),
faqat "Hayya alal-falah"dan keyin "Qod qoomatis-solaah" (2x) qo'shiladi
— bu Hanafiy mazhabidagi standart amaliyot.

Foydalanuvchi shu bilan birga bitta video/audio fayl ("Iqamat.mp3",
aslida h264 video + AAC audio, 50s) yubordi, lekin undagi takbir
sonlari BOSHQA (kamroq) ekanligini o'zi aniq ta'kidladi — shuning
uchun bu fayl **reference audio sifatida ISHLATILMADI**, faqat
matn/son tuzatishi uchun asos bo'ldi.

---



## v1.10 yangiliklari (qisqacha)

**1) Iqomat transkripsiyasi tuzatildi:** "Qad qoomatis-solaah" →
**"Qod qoomatis-solaah"** (foydalanuvchi so'rovi bo'yicha).

**2) Uch xil yangi pitch grafik turi qo'shildi**, Result ekranida
tanlov chipi orqali almashtiriladi:
- **Chiziq** (avvalgi standart) — ikkita alohida rangli chiziq
- **Piano-roll** — vokal-trener uslubida, gorizontal "yo'llar" ustidan
  harakatlanuvchi chiziqlar
- **Farq (deviation)** — faqat semitone farqni, nol chiziq atrofida
  ko'rsatadi (reference talab qiladi)
- **Qoplama (overlay)** — ikkala konturni o'z o'rtachasiga nisbatan
  markazlashtirib, faqat SHAKLNI solishtiradi — ovoz registri (baland/
  past ovoz) farqidan mustaqil (reference talab qiladi)

Bularning barchasi **faqat taqdimot qatlamida** — YIN/pitch-tahlil
algoritmiga tegilmagan, yangi widget fayllari sifatida qo'shilgan.

**3) Uchta yangi maqom — Lami, Kurd va Hijaz — Azonning 6 jumlasiga
qo'shildi.** Foydalanuvchi taqdim etgan 3 ta to'liq azon yozuvi
(MP3→WAV) avtomatik jimlik-aniqlash orqali segmentlarga bo'lindi va
bir xil sxemaga moslab guruhlandi. Endi mos jumla ekranida **"Maqom"
tanlovchisi** orqali Bayati/Lami/Kurd/Hijaz orasida (4 variant)
almashtirish mumkin — tanlangan maqomning o'z reference audiosi bilan
solishtiriladi.

**MUHIM ochiq eslatma:** hech bir qo'shimcha maqom variantida
**7-jumla ("Laa ilaaha illalloh") uchun reference audio yo'q** —
uchala yuklangan yozuvda ham bu jumlaga mos alohida segment
aniqlanmadi. Bundan tashqari, segmentatsiya audio TARKIBINI tinglab
emas, balki jimlik VAQT naqshiga asoslangan — sinab, tasdiqlashingiz
kerak.

**Arxitektura:** `pitch_analyzer.dart` (himoyalangan) hech qanday
o'zgarishsiz qoldi — ko'p-maqom tanlovi `Phrase.copyWithReference()`
orqali amalga oshiriladi: tanlangan maqomga mos `referenceAudioFile`/
`maqam` bilan YANGI `Phrase` nusxasi yaratiladi va shu oddiy `Phrase`
sifatida analyzer'larga uzatiladi — ular ko'p-maqom haqida "bilishmaydi".

---



## v1.9 yangiliklari (qisqacha)

**Azonning barcha 7 jumlasi uchun haqiqiy reference audio qo'shildi**
(Bayati maqomida, foydalanuvchi tomonidan taqdim etilgan, WAV/PCM16/
mono formatda tekshirilgan). Shu bilan:
- `lib/data/phrase_catalog.dart`da Azon jumlalarining `maqam` maydoni
  `Maqam.unknown`dan `Maqam.bayati`ga o'zgardi (bu — foydalanuvchining
  aniq tasdig'i asosida, taxmin emas).
- "Reference audioni tinglash" (Play/Pause/Stop) endi Azon uchun
  ishlaydi.
- Result ekranida ikkala pitch contour (foydalanuvchiniki va
  Bayati na'munasi) bitta grafikda, semiton farqi va o'xshashlik
  foizi bilan ko'rinadi.
- Duration solishtirish ham endi Azon uchun ishlaydi (eslatma:
  na'muna fayllar cho'zilgan/bezakli uslubda o'qilgan, 18-40 soniya —
  oddiy tezlikdagi o'qish bilan solishtirilganda "qisqaroq" natijasi
  chiqishi **kutilgan holat**, xato emas).
- `test/pitch_analyzer_test.dart`dagi "reference mavjud emas" testi
  endi Iqomat jumlasidan foydalanadi (Azon endi haqiqiy audioga ega
  bo'lgani uchun).

Bomdod qo'shimchasi va Iqomatning barcha 8 jumlasi uchun reference
audio hali yo'q — ular hamon `Maqam.unknown` va "Reference audio
hali qo'shilmagan" holatida.

---



Azon, Bomdod azoni va Iqomat talaffuzini mashq qilish uchun Flutter (Android) ilovasi.

v1.6 haqiqiy qurilmada muvaffaqiyatli ishlagan (Azon 7/7, Bomdod 8/8
tartibi to'g'ri). v1.7 shu bazaga ustida qurilgan — asosiy vazifa: har
bir jumlaning yozilgan audiosi VA tahlil natijasini jumla
almashtirilganda ham yo'qotmaslik.

## v1.7'da nima qo'shildi

### 1) To'liq amaliyot holati (recording + tahlil) — jumla ID bo'yicha

v1.6'da faqat recording (audio) holati saqlanardi. v1.7'da bu
`PhrasePracticeState` modeliga kengaytirildi — endi har bir jumla
uchun:
- `recordingPath`
- `recordingDuration`
- `hasRecording` (hisoblanadi)
- `hasAnalysis` (hisoblanadi)
- `analysisResult` (v1.3 `PitchAnalyzer` natijasi, keshlangan)
- `durationResult` (v1.4 `DurationAnalyzer` natijasi, keshlangan)

saqlanadi. Bu holat `PracticeSessionController` (sof Dart, testlanadigan
klass) ichida, `Map<String, PhrasePracticeState>` sifatida, jumla ID
bo'yicha turadi.

### 2) Oldingi jumlaga qaytganda — audio VA tahlil darhol tiklanadi

`PhrasePracticeScreen` endi `initState()`da:
1. Ota-onadan kelgan `initialState`ni tekshiradi.
2. Agar recording bo'lsa, **audio faylning diskda amalda mavjudligini**
   tekshiradi (`File(path).exists()`) — faqat xotiradagi yo'lga
   ishonib qolmaydi. Fayl topilmasa, jumla "yozilmagan" deb qayta
   belgilanadi.
3. Fayl mavjud bo'lsa, "Yozib olindi (Xs)", "Eshitish", "Qayta yozish"
   va (agar tahlil qilingan bo'lsa) "✓ Tahlil tayyor" ko'rsatiladi.

### 3) Audio shu jumlaning o'zida eshitiladi (o'zgarmadi, tasdiqlandi)

"▶ Eshitish" va "↻ Qayta yozish" — bularning ikkalasi ham xuddi
avvalgidek FAQAT joriy jumlaning `_recordingPath`idan foydalanadi.
Yangi recording avtomatik ravishda eski recordingni (va unga tegishli
eski tahlil natijasini) shu jumla uchun almashtiradi.

### 4) Tahlil natijasi jumla (aniqrog'i, audio) bilan bog'lanadi

`ResultScreen`ga ikkita yangi, ixtiyoriy parametr qo'shildi:
- `cachedResult` / `cachedDurationResult` — agar berilsa, tahlil UMUMAN
  qayta hisoblanmaydi (`PitchAnalyzer`/`DurationAnalyzer` chaqirilmaydi).
- `onAnalysisComputed` — tahlil YANGIDAN hisoblanganda, natija shu
  callback orqali `PhrasePracticeScreen`ga qaytariladi, u esa buni
  `PracticeSessionController`ga saqlaydi.

Boshqa jumlaga o'tib, keyin qaytilganda — "✓ Tahlil tayyor" ko'rinadi
va uni bosish orqali **qayta hisoblamasdan**, saqlangan natija
ko'rsatiladi.

MUHIM: bu FAQAT saqlash/tiklash mexanizmi. `PitchAnalyzer`,
`DurationAnalyzer` va ularning algoritmlari bitta qator ham
o'zgartirilmadi.

### 5) "Natijalar" ro'yxati ekrani (yangi)

`PracticeScreen`ning AppBar'iga yangi tugma (📋 "Natijalar") qo'shildi.
Bosilganda `AzonResultsScreen` ochiladi — barcha jumlalar ro'yxati:

```
1/7 — Allohu akbar — Audio: ✓  Tahlil: ✓
2/7 — Ashhadu an laa ilaaha illalloh — Audio: ✓  Tahlil: —
...
7/7 — Laa ilaaha illalloh — Audio: —  Tahlil: —
```

Jumlaga bosilganda ro'yxat yopiladi va `PracticeScreen` o'sha jumlaga
o'tadi — uning to'liq holati (audio + tahlil, agar bo'lsa) qayta
ko'rinadi.

### 6) Kelajakdagi persistence uchun tayyor arxitektura

`PracticeSessionController` — sof Dart, Flutter widget'lariga bog'liq
emas. Hozircha faqat sessiya davomida (xotirada) saqlaydi, lekin butun
ilova shu BITTA interfeys orqali ishlaydi — kelajakda uni
Hive/SQLite/SharedPreferences bilan ta'minlangan implementatsiyaga
almashtirish (yoki `load()`/`persist()` metodlarini qo'shish) katta
o'zgarishlarsiz amalga oshadi.

## O'zgargan/qo'shilgan fayllar

| Fayl | Holat |
|---|---|
| `lib/models/phrase_practice_state.dart` | YANGI |
| `lib/services/practice_session_controller.dart` | YANGI |
| `lib/screens/azon_results_screen.dart` | YANGI |
| `lib/screens/practice_screen.dart` | O'zgardi (controller, "Natijalar" tugmasi) |
| `lib/screens/phrase_practice_screen.dart` | O'zgardi (PhrasePracticeState, fayl tekshiruvi, kesh) |
| `lib/screens/result_screen.dart` | O'zgardi (cachedResult/onAnalysisComputed — orkestratsiya, algoritm emas) |
| `test/practice_session_controller_test.dart` | YANGI, 9 test |

## Himoyalangan fayllar — o'zgarmagan (diff bilan tasdiqlangan)

- `yin_pitch_detector.dart`
- `pitch_contour_extractor.dart`
- `reference_pitch_comparator.dart`
- `wav_decoder.dart` (v1.4'dagi 1-so'zlik `const`-fixdan beri o'zgarmagan)
- `pitch_analyzer.dart`
- `duration_analyzer.dart`
- `duration_comparison_result.dart`

## Iqomat va reference audio — v1.7'da tegilmagan

Iqomat hozircha faqat "Qad qoomatis-solaah" bilan turibdi (kengaytirish
keyingi bosqichda). Reference audio fayllari hali `assets/audio/`ga
qo'shilmagan — "Reference audio hali qo'shilmagan" xabari normal holat.

## Testlar (`flutter test`)

- `test/reference_pitch_comparator_test.dart` (6, o'zgarmagan)
- `test/pitch_analyzer_test.dart` (5, o'zgarmagan)
- `test/duration_analyzer_test.dart` (8, o'zgarmagan)
- `test/reference_audio_integration_test.dart` (11, o'zgarmagan)
- `test/practice_session_controller_test.dart` (**9 YANGI**):
  1. 1/7 recording → 2/7 → 1/7 ga qaytish → recording saqlangan
  2. 1/7 va 2/7 recordinglari mustaqil, aralashmaydi
  3. Tahlil natijasi jumla bilan bog'lanib saqlanadi (boshqa jumlaga
     o'tib qaytilganda ham)
  4a. Qayta yozish — eski recording yangisi bilan almashadi
  4b. `withNewRecording` eski tahlil natijasini bekor qilishi
  5a. Oddiy azon — 7 ta jumla, yakuniy takbir to'g'ri joyda
  5b. Bomdod azoni — 8 ta jumla, Bomdod qo'shimchasi + yakuniy takbir
      to'g'ri tartibda
  - Qo'shimcha: bo'sh holat, `recordedCount`/`analyzedCount` hisoblari

**Eslatma:** bu testlar `PracticeSessionController`ni (sof Dart,
platform-kanallariga bog'liq bo'lmagan) to'g'ridan-to'g'ri sinaydi —
bu butun v1.7 tuzatishining "yuragi". `PhrasePracticeScreen`/
`PracticeScreen` widget'larining o'zi haqiqiy mikrofon/fayl tizimi
platform-kanallariga bog'liq (`AudioRecorderService` dependency-inject
qilinmagan), shuning uchun to'liq widget-test qilish "minimal fix"
doirasidan tashqariga chiqadi — bu ochiq aytiladi.

## GitHub Actions

`.github/workflows/android.yml` — v1.6'da haqiqiy qurilmada
muvaffaqiyatli natija bergan holatda — **o'zgarmadi**.

## Build (lokal)

```bash
flutter pub get
flutter run
```

## Tekshiruv natijalari — nima REAL bajarildi, nima bajarilmadi

**Ochiq eslatma:** bu kod Flutter/Dart SDK o'rnatilmagan sandbox
muhitda yozilgan.

### REAL bajarilgan:
- `diff` orqali barcha himoyalangan fayllarning (YIN, pitch contour
  extractor, reference comparator, WAV decoder, pitch analyzer,
  duration analyzer, duration comparison result) v1.3/v1.4 bilan
  bayt-baytiga bir xilligi tasdiqlandi.
- Yangi model/controller/ekranlarning barcha import va metod
  signaturalari qo'lda tekshirildi.
- Azon 7/7 va Bomdod 8/8 tartibi skript orqali qayta hisoblab
  tasdiqlandi (test fayli ichida ham mavjud).

### REAL bajarilMAGAN — aniq va ochiq:
**`flutter pub get`, `flutter analyze`, `flutter test`,
`flutter build apk --debug` — bu sandbox'da Flutter SDK yo'qligi
sababli HAQIQATDA ISHGA TUSHIRILMADI.**

Flutter SDK unavailable — build not executed.

GitHub Actions workflow (`.github/workflows/android.yml`) o'zgarishsiz
qoldirildi va real build uchun tayyor — push qilingandan keyin
natijani albatta tekshiring.

## v1.7'ni qurilmada qanday tekshirish kerak

1. Azon (yoki Bomdod) mashqini boshlang.
2. 1/7 da ovoz yozing, "Eshitish" bilan tekshiring.
3. "Keyingi jumla →" orqali 2/7, 3/7 ga o'ting, har birida ovoz yozing.
4. 4/7 ga o'ting (yozmasdan).
5. "← Oldingi jumla" orqali 3/7, 2/7, 1/7 ga birma-bir qayting —
   **har birida aynan o'sha jumlaning o'z audiosi** ("Yozib olindi",
   "Eshitish", "Qayta yozish") ko'rinishi kerak.
6. 1/7 da "Tahlil qilish"ni bosing, natijani ko'ring, ortga qayting.
7. 2/7, 3/7 ga o'ting va yana 1/7 ga qayting — "✓ Tahlil tayyor"
   ko'rinishi va uni bosganda **darhol** (qayta hisoblamasdan) avvalgi
   natija ochilishi kerak.
8. AppBar'dagi 📋 ("Natijalar") tugmasini bosing — barcha 7 jumla
   ro'yxati, har birining audio/tahlil holati bilan ko'rinishi kerak.
9. Ro'yxatdan istalgan jumlani bosing — o'sha jumlaga o'tilishi va
   holati to'g'ri tiklanishi kerak.
