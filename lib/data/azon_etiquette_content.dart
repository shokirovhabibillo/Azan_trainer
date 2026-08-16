/// v1.16: "Azon aytish tartibi va odoblari" — alohida, majburiy
/// bo'lmagan ma'lumot ekrani uchun kontent. Foydalanuvchi tomonidan
/// berilgan matn, so'zma-so'z saqlangan.
class AzonEtiquetteItem {
  final String title;
  final String body;

  const AzonEtiquetteItem({required this.title, required this.body});
}

const String azonEtiquetteIntro = 'Azon aytish tartibi va odoblari:';

const List<AzonEtiquetteItem> azonEtiquetteItems = [
  AzonEtiquetteItem(
    title: 'Qiblaga qarash',
    body: 'Muazzin (azon aytuvchi) tahoratli holda, qibla tomonga '
        'yuzlanib azon aytadi.',
  ),
  AzonEtiquetteItem(
    title: 'Ovoz va ohang',
    body: 'Azon dona-dona va barchaga eshitiladigan go\'zal, baland '
        'ovozda aytiladi.',
  ),
  AzonEtiquetteItem(
    title: 'O\'ng va chapga burilish',
    body: '"Hayya \'alas-salah" deyilganda o\'ng tomonga, "Hayya '
        '\'alal-falah" deyilganda chap tomonga burilinadi.',
  ),
  AzonEtiquetteItem(
    title: 'Azonni eshitganning odobi',
    body: 'Azonni eshitgan kishi uni tinglab, muazzin ketidan ushbu '
        'kalomalarni sekin takrorlashi hamda azon tugagach ma\'lum '
        'bo\'lgan duoni o\'qishi sunnat hisoblanadi.',
  ),
];
