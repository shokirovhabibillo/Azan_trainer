# Azon Trainer — v1.4 (Duration / Mad Analysis)

Azon, Bomdod azoni va Iqomat talaffuzini mashq qilish uchun Flutter (Android) ilovasi.

## Loyiha strukturasi

```
lib/
  main.dart
  core/
    constants.dart
    theme.dart
  models/
    phrase.dart
    maqam.dart
    analysis_result.dart
    duration_comparison_result.dart   # v1.4: YANGI
    practice_session.dart
    pitch_frame.dart
    reference_comparison_result.dart
  data/
    phrase_catalog.dart
  services/
    audio/
      audio_recorder_service.dart
      audio_player_service.dart
      reference_audio_checker.dart
      reference_audio_loader.dart
    analysis/
      audio_analyzer.dart
      pitch_analyzer.dart                # O'ZGARMAGAN (v1.3'dan)
      pitch_contour_extractor.dart       # O'ZGARMAGAN - v1.4 talabi
      reference_pitch_comparator.dart    # O'ZGARMAGAN - v1.4 talabi
      wav_decoder.dart                   # O'ZGARMAGAN - v1.4 talabi
      yin_pitch_detector.dart            # O'ZGARMAGAN - v1.4 talabi
      duration_analyzer.dart             # v1.4: YANGI, mustaqil servis
    progress_service.dart
  screens/
    home_screen.dart
    practice_screen.dart
    phrase_practice_screen.dart
    result_screen.dart                   # v1.4: + Duration kartochkasi
  widgets/
    phrase_card.dart
    metric_tile.dart
    dual_pitch_contour_chart.dart
assets/audio/                            # Reference audio (.wav) - HALI YO'Q
.github/workflows/android.yml            # pub get -> analyze -> test -> build
test/
  pitch_analyzer_test.dart
  reference_pitch_comparator_test.dart
  reference_audio_integration_test.dart
  duration_analyzer_test.dart             # v1.4: YANGI, 8 test
  helpers/wav_test_helper.dart
```

## v1.4'da nima o'zgardi (va nima QASDDAN o'zgarmadi)

**QASDDAN O'ZGARTIRILMAGAN (talab bo'yicha, aynan shu maqsadda tekshirildi):**
- `yin_pitch_detector.dart`
- `pitch_contour_extractor.dart`
- `reference_pitch_comparator.dart`
- `wav_decoder.dart`
- Mavjud reference-comparison (`PitchAnalyzer`ning reference pipeline qismi)

Bularning har biri v1.3 versiyasi bilan `diff` orqali solishtirilib,
**bayt-baytiga bir xilligi tasdiqlandi** (pastdagi "Tekshiruv
natijalari" bo'limida).

**YANGI (v1.4):**
- `lib/models/duration_comparison_result.dart`
- `lib/services/analysis/duration_analyzer.dart`
- `ResultScreen`ga alohida "Duration" kartochkasi
- `test/duration_analyzer_test.dart` - 8 test

## Duration/Mad tahlili - maqsad va pipeline

```
User WAV      -> WavDecoder -> PitchContourExtractor -> total + faol davomiylik
                                    (BIR XIL kod, o'zgarmagan)
Reference WAV -> WavDecoder -> PitchContourExtractor -> total + faol davomiylik
  (agar mavjud)
                       |
                       v
       duration difference, duration ratio
                       |
                       v
   threshold-based TEXNIK feedback (diniy hukm emas)
```

`DurationAnalyzer` - `PitchAnalyzer`dan **butunlay mustaqil**: o'z
ichida `WavDecoder` va `PitchContourExtractor`ni (ikkalasi ham
o'zgarmagan) alohida chaqiradi. `ResultScreen` ikkalasini **parallel,
bir-biridan bexabar** chaqiradi (`Future`larni bir vaqtda boshlab,
keyin ikkisini ham kutish) va natijalarni faqat ko'rsatish maqsadida
birlashtiradi - biri ikkinchisiga bog'liq emas (talab #8).

## Hisoblanadigan qiymatlar

`DurationComparisonResult` modelida:

- `userDurationMs` / `referenceDurationMs` - umumiy fayl davomiyligi
- `userActiveDurationMs` / `referenceActiveDurationMs` - **faol
  (voiced) davomiylik**: birinchi va oxirgi voiced freym orasidagi
  oraliq + bitta hop davomiyligi. Bu boshidagi va oxiridagi jimlikni
  (masalan, foydalanuvchi tugmani bosib, keyin gapira boshlagan vaqt)
  hisobga OLMAYDI - faqat umumiy fayl uzunligiga tayanib xato
  natija berilmasligi shu orqali ta'minlanadi (talab #3).
- `durationDifferenceMs` = userActive - referenceActive
- `durationRatio` = userActive / referenceActive
- `userVoicedRatio` / `referenceVoicedRatio` - voiced freymlar ulushi

## Feedback - faqat texnik, diniy hukm emas

Thresholdlar `DurationAnalyzer` ichida alohida nomlangan constant
sifatida saqlanadi (`minActiveDurationMs = 300`,
`closeRatioLowerBound = 0.85`, `closeRatioUpperBound = 1.15`) -
kelajakda tajvid/mad ekspertizasi asosida osongina almashtirilishi
uchun.

Ustuvorlik tartibida:
1. Faol davomiylik (user yoki reference) 300ms'dan kam ->
   **"Faol ovozli qism juda qisqa."**
2. Ratio [0.85, 1.15] oralig'ida -> **"Reference bilan davomiylik juda
   yaqin."**
3. Ratio < 0.85 -> **"User phrase reference'dan qisqaroq."**
4. Ratio > 1.15 -> **"User phrase reference'dan uzunroq."**
5. Reference umuman mavjud emas -> **"Reference audio mavjud emas -
   duration comparison bajarilmadi."**

Bu xabarlarning hech biri "to'g'ri/noto'g'ri o'qildi" degan diniy
baho bermaydi - faqat ikki audio faylning davomiyligi qanday
solishtirilganini tasvirlaydi.

## Result screen - Duration kartochkasi

Reference mavjud bo'lganda: User / Reference / Farq / Feedback to'rt
qatorli kartochka. Reference mavjud bo'lmaganda: "Reference duration
mavjud emas" holati va faqat foydalanuvchining faol davomiyligi
ko'rsatiladi (agar hisoblangan bo'lsa).

## Reference audio - hali yo'q (o'zgarmadi)

`assets/audio/` ichida haqiqiy WAV fayllar hamon yo'q va ular
sun'iy/demo audio bilan almashtirilmadi. `DurationAnalyzer` xuddi
`PitchAnalyzer` kabi `ReferenceAudioChecker`/`ReferenceAudioLoader`
orqali ishlaydi - real WAV fayllar `assets/audio/`ga qo'shilgan
zahoti, kod o'zgarishisiz avtomatik ishlay boshlaydi.

## Testlar (`flutter test`)

- `test/reference_pitch_comparator_test.dart` (6, o'zgarmagan)
- `test/pitch_analyzer_test.dart` (5, o'zgarmagan)
- `test/reference_audio_integration_test.dart` (9, o'zgarmagan)
- `test/duration_analyzer_test.dart` (**8 YANGI, v1.4**):
  1. User va reference davomiyligi bir xil -> `veryClose`
  2. User sezilarli qisqaroq -> `userShorter`
  3. User sezilarli uzunroq -> `userLonger`
  4. Reference mavjud emas -> `notAvailable`, fake natija yo'q
  5. Leading/trailing silence - faol davomiylik umumiy fayldan
     sezilarli kichik ekanligi (windowing chegara effektlariga
     chidamli tarzda, nisbat orqali tekshirilgan)
  6. Juda qisqa audio (0.15s) -> `activeTooShort`
  7. Faqat silence -> `activeTooShort`, faol davomiylik = 0
  8. Normal voiced audio - asosiy statistikalar (davomiylik, voiced
     ratio) to'g'ri hisoblanishi

Barcha testlar `assets/audio/`ga hech narsa yozmaydi - reference
mavjudligi `ReferenceAudioChecker`/`ReferenceAudioLoader`ning test
doirasidagi (xotiradagi) fake implementatsiyalari orqali simulyatsiya
qilinadi (v1.3'dagi bilan bir xil pattern).

## GitHub Actions

`.github/workflows/android.yml`: `flutter pub get` -> `flutter analyze`
(continue-on-error YO'Q, v1.3'dan meros) -> `flutter test` ->
`flutter build apk --debug`. Ketma-ketlik o'zgarmadi.

## Build (lokal)

```bash
flutter pub get
flutter run
```

## Tekshiruv natijalari - nima REAL bajarildi, nima bajarilmadi

**Ochiq eslatma (yashirilmaydi):** bu kod Flutter/Dart SDK
o'rnatilmagan sandbox muhitda yozilgan (tarmoq sozlamalari
`storage.googleapis.com`ni bloklaydi).

### REAL bajarilgan tekshiruvlar:
- `diff` orqali `yin_pitch_detector.dart`, `pitch_contour_extractor.dart`,
  `reference_pitch_comparator.dart`, `wav_decoder.dart` fayllarining
  v1.3 bilan **bayt-baytiga bir xilligi** dasturiy tasdiqlandi
  (natija: 4 fayl ham "IDENTICAL").
- `DurationAnalyzer`ning `_measure`/`_compare` mantig'i qo'lda,
  qadamma-qadam sonli hisob-kitob orqali tekshirildi (masalan, test
  #1-3, #6-8 uchun frame-by-frame RMS/voiced chegaralari qo'lda
  hisoblanib, kutilgan natija bilan solishtirildi).
- Test #5 (leading/trailing silence) uchun boshlang'ich qattiq
  assertion ("aynan veryClose bo'lishi kerak") **noto'g'ri chiqishi
  mumkinligi qo'lda hisob-kitob orqali aniqlandi** (sliding-window
  freym chegaralari sabab ~10-20% qo'shimcha og'ish beradi) - shuning
  uchun test windowing-artefaktlariga chidamli, faqat "trimming
  ishladi" faktini tekshiradigan shaklga o'zgartirildi.
- Barcha yangi fayllar import/unused-variable nuqtai nazaridan qo'lda
  tekshirildi.

### REAL bajarilMAGAN tekshiruvlar:
- `flutter pub get`, `flutter analyze`, `flutter test`,
  `flutter build apk --debug` - bu buyruqlar sandbox'da Flutter SDK
  yo'qligi sababli **haqiqatda ishga tushirilmadi**. Xususan, YIN
  algoritmi orqali sun'iy sinusoida signalidan chastota qanchalik
  aniq chiqishi (voiced/unvoiced chegaralari) faqat qo'lda,
  RMS-asoslangan mantiq darajasida tekshirildi - YIN'ning haqiqiy
  chiqishi (masalan, chekka freymlarda) biroz farq qilishi mumkin.
  Push qilingandan keyin GitHub Actions natijasini albatta
  tekshiring. Agar biror test kutilmagan natija bersa (ayniqsa test
  #2/#3 dagi qattiq threshold solishtirishlari), log bilan qaytsangiz,
  darhol tuzataman.
