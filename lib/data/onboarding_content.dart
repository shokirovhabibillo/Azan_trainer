import '../models/onboarding_page_content.dart';

/// v1.13: majburiy onboarding uchun 4 ta sahifa matni.
///
/// MUHIM: matnlar so'zma-so'z, o'zgartirmasdan saqlangan — diniy
/// mazmun bo'lgani sababli erkin parafrazlash qilinmadi.
const List<OnboardingPageContent> onboardingPages = [
  OnboardingPageContent(
    pageNumber: 1,
    totalPages: 4,
    title: 'Azon Trainer\'ga xush kelibsiz',
    body: '''
Ushbu ilova azonni to'g'ri talaffuz qilish, ovoz ohangi va davomiyligini mashq qilish hamda o'z ijroningizni namuna ovoz bilan solishtirish uchun mo'ljallangan.

Ilovadan foydalanishdan oldin quyidagi muhim ma'lumotlarni to'liq o'qib chiqing.

Azonni o'rganishda faqat ovoz ohangi yoki balandligi emas, arabiy harflarning maxraji, talaffuzi, harakatlari, madd va boshqa tajvid qoidalariga rioya qilish ham muhim.

Noto'g'ri talaffuz ayrim hollarda lafzning ma'nosiga ta'sir qilishi mumkin.

Shuning uchun Azon Trainer texnik mashq va tahlil vositasi bo'lib, tajvid ilmini o'rgatuvchi malakali ustozning o'rnini bosmaydi.

Agar tajvid qoidalarini yaxshi bilmasangiz, azonni malakali ustozdan o'rganishingiz tavsiya etiladi.''',
  ),
  OnboardingPageContent(
    pageNumber: 2,
    totalPages: 4,
    title: 'Nega tajvid muhim?',
    body: '''
Tajvid — arabiy lafzlarni to'g'ri talaffuz qilish qoidalarini o'rgatuvchi ilm.

Azon kalimalari arab tilidagi muhim lafzlardir. Harflarning maxraji, sifatlari, harakatlari va cho'zilishlarini noto'g'ri bajarish talaffuzni buzishi mumkin.

Ayniqsa, bir-biriga o'xshash tovushlarning maxrajini noto'g'ri chiqarish yoki lafzning harakatini o'zgartirish ayrim hollarda so'zning ma'nosiga ta'sir qilishi mumkin.

Azon Trainer sizning ovozingizni texnik jihatdan tahlil qiladi:
• pitch
• pitch contour
• duration
• voiced activity
• reference audio bilan taqqoslash

Ammo texnik tahlil tajvid ustozining hukmini almashtirmaydi.

Ilovadan foydalanishdan oldin foydalanuvchi hech bo'lmaganda azon kalimalarining to'g'ri talaffuzi va asosiy tajvid qoidalarini o'rganishi kerak.''',
  ),
  OnboardingPageContent(
    pageNumber: 3,
    totalPages: 4,
    title: 'Hanafiy mazhabiga ko\'ra azon',
    body: '''
Hanafiy mazhabiga ko'ra azon shoshilmasdan, xotirjamlik bilan — tarassul bilan aytiladi.

Tarassul — azonni shoshmasdan va aniq talaffuz bilan aytishdir.

Azondagi ikki takbirni bir ovozda:

Allohu akbar, Allohu akbar

deb aytib, so'ng vaqf qilish Hanafiy mazhabining mo'tabar manbalarida sunnat shakli sifatida bayon qilingan.

Keyin:

Allohu akbar, Allohu akbar

aytiladi.

Boshqa azon jumlalari ham o'z o'rnida, shoshilmasdan va aniq talaffuz bilan aytiladi.

Azonni aytishdagi ayrim fiqhiy tafsilotlar mazhablar orasida farq qilishi mumkin.

Ushbu ilova bu masalada Hanafiy mazhabiga va O'zbekiston musulmonlari idorasi qoshidagi Fatvo markazi tomonidan 2025-yil 23-aprelda e'lon qilingan tegishli fatvo materialiga asoslanadi.''',
    sourceLabel: 'O\'zbekiston musulmonlari idorasi — Fatvo markazi\n23.04.2025',
    sourceUrl:
        'https://fatvo.uz/lat/fatwas/hanafiy-mazhabiga-kora-azondagi-ikki-takbirni-qoshib-aytishga-doir-fatvo-3',
  ),
  OnboardingPageContent(
    pageNumber: 4,
    totalPages: 4,
    title: 'Ayollar uchun muhim eslatma',
    body: '''
Hanafiy fiqhiga ko'ra azon va iqomat ayollar uchun sunnati muakkada sifatida belgilanmagan.

Ayol kishi yolg'iz namoz o'qiganda yoki faqat ayollardan iborat jamoatda namoz o'qiganda ham azon va iqomatni tark etadi.

Shu sababli ushbu ilova erkaklarning azon va iqomatni o'rganishi uchun mo'ljallangan.

Bu masalada turli fiqhiy qarashlar mavjud bo'lishi mumkin. Ushbu ilovadagi ma'lumot Hanafiy mazhabiga asoslangan.

Agar foydalanuvchi ushbu masalada batafsil diniy hukmni bilmoqchi bo'lsa, ishonchli va malakali ahli ilmga murojaat qilishi tavsiya etiladi.''',
  ),
];
