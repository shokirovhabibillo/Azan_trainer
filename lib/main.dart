import 'package:flutter/material.dart';
import 'core/fiqh_engine/models/actor_role.dart';
import 'core/fiqh_engine/models/event_type.dart';
import 'core/fiqh_engine/models/fiqh_result.dart';
import 'core/fiqh_engine/models/prayer_context.dart';
import 'core/fiqh_engine/models/prayer_event.dart';
import 'core/fiqh_engine/models/prayer_position.dart';
import 'core/fiqh_engine/models/prayer_type.dart';
import 'core/fiqh_engine/rule_engine.dart';

enum TartibAppearance { day, night, clay }

enum TartibModule { engine, prayerOrder, sahv, jamaat, qiraat, sources }

void main() => runApp(const TartibApp());

class TartibApp extends StatefulWidget {
  const TartibApp({super.key});
  @override
  State<TartibApp> createState() => _TartibAppState();
}

class _TartibAppState extends State<TartibApp> {
  TartibAppearance appearance = TartibAppearance.day;

  ThemeData get _dayTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      );

  ThemeData get _nightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFF0E1420),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF171F2D),
          border: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: .08)),
          ),
        ),
      );

  ThemeData get _clayTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6E7891),
          brightness: Brightness.light,
          surface: const Color(0xFFDDE2EA),
        ),
        scaffoldBackgroundColor: const Color(0xFFDDE2EA),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Color(0xFFDDE2EA),
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFDDE2EA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            borderSide: BorderSide.none,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = switch (appearance) {
      TartibAppearance.day => _dayTheme,
      TartibAppearance.night => _nightTheme,
      TartibAppearance.clay => _clayTheme,
    };

    return MaterialApp(
      title: 'Tartib',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: HomePage(
        appearance: appearance,
        onAppearanceChanged: (value) => setState(() => appearance = value),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final TartibAppearance appearance;
  final ValueChanged<TartibAppearance> onAppearanceChanged;

  const HomePage({
    super.key,
    required this.appearance,
    required this.onAppearanceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isClay = appearance == TartibAppearance.clay;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tartib'),
        actions: [
          IconButton(
            tooltip: 'Ko‘rinish',
            onPressed: () => _showAppearanceSheet(context),
            icon: Icon(_appearanceIcon(appearance)),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Container(
        decoration: isClay
            ? const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE7EBF1), Color(0xFFD5DBE4)],
                ),
              )
            : null,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          children: [
            _AppearanceBar(
              appearance: appearance,
              onChanged: onAppearanceChanged,
            ),
            const SizedBox(height: 18),
            _ClayContainer(
              enabled: isClay,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Namozda nima bo‘ldi?',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Tartib holatni bosqichma-bosqich aniqlab, faqat tekshirilgan qoidani chiqaradi.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: isClay
                          ? _ClayButton(
                              icon: Icons.account_tree_rounded,
                              label: 'Holatni aniqlash',
                              onPressed: () => _openEngine(context),
                            )
                          : FilledButton.icon(
                              onPressed: () => _openEngine(context),
                              icon: const Icon(Icons.account_tree_rounded),
                              label: const Text('Holatni aniqlash'),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Tartib bo‘limlari',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            _ModuleGrid(
              appearance: appearance,
              onOpen: (module) => _openModule(context, module),
            ),
            const SizedBox(height: 18),
            _ClayContainer(
              enabled: isClay,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified_outlined),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Manba tamoyili: avval yuklangan kitoblar tekshiriladi. Yetarli bo‘lmasa OMI manbasi ishlatiladi. Manba yetarli bo‘lmasa, Tartib hukm to‘qimaydi.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openEngine(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EnginePage(
          appearance: appearance,
          onAppearanceChanged: onAppearanceChanged,
        ),
      ),
    );
  }

  void _openModule(BuildContext context, TartibModule module) {
    if (module == TartibModule.engine) {
      _openEngine(context);
      return;
    }
    if (module == TartibModule.prayerOrder) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PrayerOrderPage(
            appearance: appearance,
            onAppearanceChanged: onAppearanceChanged,
          ),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModulePage(
          module: module,
          appearance: appearance,
          onAppearanceChanged: onAppearanceChanged,
          onOpenEngine: () => _openEngine(context),
        ),
      ),
    );
  }

  IconData _appearanceIcon(TartibAppearance a) => switch (a) {
        TartibAppearance.day => Icons.light_mode,
        TartibAppearance.night => Icons.dark_mode,
        TartibAppearance.clay => Icons.blur_on,
      };

  void _showAppearanceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _AppearanceSheet(
        appearance: appearance,
        onChanged: (value) {
          Navigator.pop(context);
          onAppearanceChanged(value);
        },
      ),
    );
  }
}

class _ModuleGrid extends StatelessWidget {
  final TartibAppearance appearance;
  final ValueChanged<TartibModule> onOpen;

  const _ModuleGrid({required this.appearance, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final modules = [
      const _ModuleData(TartibModule.engine, 'Fiqh Engine', 'Holatni aniqlash', Icons.account_tree_rounded),
      const _ModuleData(TartibModule.prayerOrder, 'Namoz tartibi', 'Niyatdan salomgacha', Icons.timeline_rounded),
      const _ModuleData(TartibModule.sahv, 'Sajdai sahv', 'Sahv holatlari', Icons.pan_tool_alt_rounded),
      const _ModuleData(TartibModule.jamaat, 'Jamoat', 'Imom va muqtadi', Icons.groups_rounded),
      const _ModuleData(TartibModule.qiraat, 'Qiroat', 'Qiroat xatolari', Icons.menu_book_rounded),
      const _ModuleData(TartibModule.sources, 'Manbalar', 'Dalil va tekshiruv', Icons.library_books_rounded),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: modules.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.18,
      ),
      itemBuilder: (context, index) {
        final item = modules[index];
        final clay = appearance == TartibAppearance.clay;
        final content = InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => onOpen(item.module),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icon, size: 30),
                const Spacer(),
                Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(item.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
        return _ClayContainer(
          enabled: clay,
          radius: 22,
          child: clay
              ? content
              : Card(
                  margin: EdgeInsets.zero,
                  child: content,
                ),
        );
      },
    );
  }
}

class _ModuleData {
  final TartibModule module;
  final String title;
  final String subtitle;
  final IconData icon;
  const _ModuleData(this.module, this.title, this.subtitle, this.icon);
}

class ModulePage extends StatelessWidget {
  final TartibModule module;
  final TartibAppearance appearance;
  final ValueChanged<TartibAppearance> onAppearanceChanged;
  final VoidCallback onOpenEngine;

  const ModulePage({
    super.key,
    required this.module,
    required this.appearance,
    required this.onAppearanceChanged,
    required this.onOpenEngine,
  });

  @override
  Widget build(BuildContext context) {
    final data = _moduleData(module);
    final clay = appearance == TartibAppearance.clay;
    return Scaffold(
      appBar: AppBar(
        title: Text(data.title),
        actions: [
          IconButton(
            onPressed: () => _showAppearanceSheet(context),
            icon: Icon(_appearanceIcon(appearance)),
          ),
        ],
      ),
      body: Container(
        decoration: clay
            ? const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE7EBF1), Color(0xFFD5DBE4)],
                ),
              )
            : null,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ClayContainer(
              enabled: clay,
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    Icon(data.icon, size: 58),
                    const SizedBox(height: 14),
                    Text(
                      data.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(data.description, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _ClayContainer(
              enabled: clay,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Keyingi bosqich', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(data.nextStep),
                    if (data.module != TartibModule.sources) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: onOpenEngine,
                          icon: const Icon(Icons.account_tree_rounded),
                          label: const Text('Holatni aniqlashga o‘tish'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _ModuleDataFull _moduleData(TartibModule m) => switch (m) {
        TartibModule.prayerOrder => const _ModuleDataFull(
            TartibModule.prayerOrder,
            'Namoz tartibi',
            'Niyat → takbiri tahrima → qiyom → qiroat → ruku’ → qavma → sajda → qa’da → salom.',
            'Keyingi bosqichda namozning vaqtli holat ketma-ketligi shu modulga ulanadi.',
            Icons.timeline_rounded,
          ),
        TartibModule.sahv => const _ModuleDataFull(
            TartibModule.sahv,
            'Sajdai sahv',
            'Qaysi wajib qoldi, qachon aniqlandi va sahv bilan tuzatish mumkinmi — shu yo‘nalish uchun alohida modul.',
            'Tasdiqlangan sahv qoidalari mavjud Engine registry orqali bosqichma-bosqich kengaytiriladi.',
            Icons.pan_tool_alt_rounded,
          ),
        TartibModule.jamaat => const _ModuleDataFull(
            TartibModule.jamaat,
            'Jamoat',
            'Imom, muqtadi, masbuq va lahiq holatlarini alohida kontekst sifatida boshqarish.',
            'Jamoat qoidalari manba tekshiruvi bilan Engine kontekstiga ulanadi.',
            Icons.groups_rounded,
          ),
        TartibModule.qiraat => const _ModuleDataFull(
            TartibModule.qiraat,
            'Qiroat',
            'Fotiha, zam sura, jahr/sirr, sura tartibi va qiroatdagi vaqtli kechikish holatlari.',
            'Hozirgi Engine ichidagi tasdiqlangan qiroat qoidalari shu modulga ulanadi.',
            Icons.menu_book_rounded,
          ),
        TartibModule.sources => const _ModuleDataFull(
            TartibModule.sources,
            'Manbalar',
            'Har bir hukm manba nomi va tekshiruv holati bilan ko‘rsatiladi.',
            'Keyingi bosqichda manba kartochkalari va qoida bo‘yicha dalil ko‘rinishi qo‘shiladi.',
            Icons.library_books_rounded,
          ),
        TartibModule.engine => const _ModuleDataFull(
            TartibModule.engine,
            'Fiqh Engine',
            'Holatni tanlash va tekshirilgan qoida bo‘yicha natija olish.',
            'Asosiy Engine oynasi.',
            Icons.account_tree_rounded,
          ),
      };

  IconData _appearanceIcon(TartibAppearance a) => switch (a) {
        TartibAppearance.day => Icons.light_mode,
        TartibAppearance.night => Icons.dark_mode,
        TartibAppearance.clay => Icons.blur_on,
      };

  void _showAppearanceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _AppearanceSheet(
        appearance: appearance,
        onChanged: (value) {
          Navigator.pop(context);
          onAppearanceChanged(value);
        },
      ),
    );
  }
}

class _ModuleDataFull {
  final TartibModule module;
  final String title;
  final String description;
  final String nextStep;
  final IconData icon;
  const _ModuleDataFull(this.module, this.title, this.description, this.nextStep, this.icon);
}


class PrayerOrderPage extends StatefulWidget {
  final TartibAppearance appearance;
  final ValueChanged<TartibAppearance> onAppearanceChanged;

  const PrayerOrderPage({
    super.key,
    required this.appearance,
    required this.onAppearanceChanged,
  });

  @override
  State<PrayerOrderPage> createState() => _PrayerOrderPageState();
}

class _PrayerOrderPageState extends State<PrayerOrderPage> {
  final Set<int> completed = <int>{};
  int? selectedStep;

  static const steps = <_PrayerStep>[
    _PrayerStep('Niyat', 'Namozni boshlashdan oldingi niyat bosqichi.', Icons.flag_rounded),
    _PrayerStep('Takbiri tahrima', 'Namozga kirish bosqichi.', Icons.pan_tool_alt_rounded),
    _PrayerStep('Qiyom', 'Tik turish holati.', Icons.accessibility_new_rounded),
    _PrayerStep('Qiroat', 'Qiroat bajariladigan bosqich.', Icons.menu_book_rounded),
    _PrayerStep('Ruku’', 'Ruku’ holati.', Icons.keyboard_arrow_down_rounded),
    _PrayerStep('Qavma', 'Ruku’dan keyingi tik turish bosqichi.', Icons.keyboard_arrow_up_rounded),
    _PrayerStep('Sajda', 'Sajda bosqichi.', Icons.expand_more_rounded),
    _PrayerStep('Jalsa', 'Ikki sajda orasidagi o‘tirish bosqichi.', Icons.event_seat_rounded),
    _PrayerStep('Birinchi qa’da', 'Tegishli namoz holatlarida birinchi qa’da.', Icons.airline_seat_recline_normal_rounded),
    _PrayerStep('Oxirgi qa’da', 'Namoz yakunidagi qa’da.', Icons.chair_rounded),
    _PrayerStep('Salom', 'Namozni yakunlash bosqichi.', Icons.waving_hand_rounded),
  ];

  double get progress => completed.length / steps.length;

  @override
  Widget build(BuildContext context) {
    final clay = widget.appearance == TartibAppearance.clay;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Namoz tartibi'),
        actions: [
          IconButton(
            tooltip: 'Ko‘rinish',
            onPressed: () => _showAppearanceSheet(context),
            icon: Icon(_appearanceIcon(widget.appearance)),
          ),
        ],
      ),
      body: Container(
        decoration: clay
            ? const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE7EBF1), Color(0xFFD5DBE4)],
                ),
              )
            : null,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          children: [
            _AppearanceBar(appearance: widget.appearance, onChanged: widget.onAppearanceChanged),
            const SizedBox(height: 14),
            _ClayContainer(
              enabled: clay,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Namoz ketma-ketligi', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 7),
                    const Text('Bosqichlarni ko‘rib chiqing va o‘zingiz uchun bajarilgan holatni belgilang. Bu ekran hozircha universal tartib navigatori; maxsus fiqh tafsilotlari manba tekshiruvi bilan ulanadi.'),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(value: progress, minHeight: 10),
                    ),
                    const SizedBox(height: 8),
                    Text('${completed.length} / ${steps.length} bosqich belgilandi'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            ...List.generate(steps.length, (index) {
              final step = steps[index];
              final done = completed.contains(index);
              final selected = selectedStep == index;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ClayContainer(
                  enabled: clay,
                  radius: 20,
                  child: Material(
                    color: clay ? Colors.transparent : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => setState(() => selectedStep = selected ? null : index),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  child: done ? const Icon(Icons.check_rounded) : Text('${index + 1}'),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(step.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                      const SizedBox(height: 3),
                                      Text(step.description),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: done ? 'Belgini olib tashlash' : 'Bajarildi deb belgilash',
                                  onPressed: () => setState(() {
                                    if (done) {
                                      completed.remove(index);
                                    } else {
                                      completed.add(index);
                                    }
                                  }),
                                  icon: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked),
                                ),
                              ],
                            ),
                            if (selected) ...[
                              const Divider(height: 24),
                              Row(
                                children: [
                                  Icon(step.icon, size: 28),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text('Bu bosqich keyinchalik hodisa va Fiqh Engine kontekstiga ulanadi.')),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: completed.isEmpty ? null : () => setState(completed.clear),
              icon: const Icon(Icons.restart_alt),
              label: const Text('Belgilashlarni tozalash'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _appearanceIcon(TartibAppearance a) => switch (a) {
        TartibAppearance.day => Icons.light_mode,
        TartibAppearance.night => Icons.dark_mode,
        TartibAppearance.clay => Icons.blur_on,
      };

  void _showAppearanceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _AppearanceSheet(
        appearance: widget.appearance,
        onChanged: (value) {
          Navigator.pop(context);
          widget.onAppearanceChanged(value);
        },
      ),
    );
  }
}

class _PrayerStep {
  final String title;
  final String description;
  final IconData icon;
  const _PrayerStep(this.title, this.description, this.icon);
}

class EnginePage extends StatefulWidget {
  final TartibAppearance appearance;
  final ValueChanged<TartibAppearance> onAppearanceChanged;

  const EnginePage({
    super.key,
    required this.appearance,
    required this.onAppearanceChanged,
  });

  @override
  State<EnginePage> createState() => _EnginePageState();
}

class _EnginePageState extends State<EnginePage> {
  ActorRole role = ActorRole.munfarid;
  PrayerType prayer = PrayerType.asr;
  int rakat = 3;
  PrayerPosition position = PrayerPosition.qiroat;
  EventType event = EventType.qiroatOmitted;
  int delayTasbih = 3;
  FiqhResult? result;

  void evaluate() {
    final context = PrayerContext(
      prayerType: prayer,
      rakat: rakat,
      actorRole: role,
      position: position,
    );
    final prayerEvent = PrayerEvent(
      type: event,
      position: position,
      delayTasbih: event == EventType.qiroatDelayed ? delayTasbih : null,
    );
    setState(() => result = RuleEngine().evaluate(context: context, event: prayerEvent));
  }

  @override
  Widget build(BuildContext context) {
    final isClay = widget.appearance == TartibAppearance.clay;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Holatni aniqlash'),
        actions: [
          IconButton(
            tooltip: 'Ko‘rinish',
            onPressed: () => _showAppearanceSheet(context),
            icon: Icon(_appearanceIcon(widget.appearance)),
          ),
        ],
      ),
      body: Container(
        decoration: isClay
            ? const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE7EBF1), Color(0xFFD5DBE4)],
                ),
              )
            : null,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          children: [
            _AppearanceBar(appearance: widget.appearance, onChanged: widget.onAppearanceChanged),
            const SizedBox(height: 14),
            _ClayContainer(
              enabled: isClay,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Holatni aniqlash', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 6),
                    const Text('Vaziyatni tanlang. Engine faqat manba bilan tekshirilgan mos qoidani qo‘llaydi.'),
                    const SizedBox(height: 18),
                    _drop<ActorRole>('1. Kim?', role, ActorRole.values, (v) => v.label, (v) => setState(() { role = v!; result = null; })),
                    _drop<PrayerType>('2. Qaysi namoz?', prayer, PrayerType.values, (v) => v.label, (v) => setState(() { prayer = v!; result = null; })),
                    DropdownButtonFormField<int>(
                      initialValue: rakat,
                      decoration: const InputDecoration(labelText: '3. Qaysi rakat?'),
                      items: List.generate(6, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}-rakat'))),
                      onChanged: (v) => setState(() { rakat = v!; result = null; }),
                    ),
                    const SizedBox(height: 12),
                    _drop<PrayerPosition>('4. Qayerda?', position, PrayerPosition.values, (v) => v.label, (v) => setState(() { position = v!; result = null; })),
                    _drop<EventType>('5. Nima bo‘ldi?', event, EventType.values, (v) => v.label, (v) => setState(() { event = v!; result = null; })),
                    if (event == EventType.qiroatDelayed) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        initialValue: delayTasbih,
                        decoration: const InputDecoration(labelText: 'To‘xtash miqdori'),
                        items: const [1, 2, 3, 4, 5].map((v) => DropdownMenuItem(value: v, child: Text('$v tasbih'))).toList(),
                        onChanged: (v) => setState(() { delayTasbih = v!; result = null; }),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: isClay
                          ? _ClayButton(icon: Icons.gavel, label: 'Qoidani aniqlash', onPressed: evaluate)
                          : FilledButton.icon(
                              onPressed: evaluate,
                              icon: const Icon(Icons.gavel),
                              label: const Text('Qoidani aniqlash'),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            if (result != null) ...[
              const SizedBox(height: 14),
              _ClayContainer(enabled: isClay, child: ResultCard(result: result!)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _drop<T>(String label, T value, List<T> values, String Function(T) labelOf, ValueChanged<T?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: values.map((v) => DropdownMenuItem(value: v, child: Text(labelOf(v)))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  IconData _appearanceIcon(TartibAppearance a) => switch (a) {
        TartibAppearance.day => Icons.light_mode,
        TartibAppearance.night => Icons.dark_mode,
        TartibAppearance.clay => Icons.blur_on,
      };

  void _showAppearanceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _AppearanceSheet(
        appearance: widget.appearance,
        onChanged: (value) {
          Navigator.pop(context);
          widget.onAppearanceChanged(value);
        },
      ),
    );
  }
}

class _AppearanceBar extends StatelessWidget {
  final TartibAppearance appearance;
  final ValueChanged<TartibAppearance> onChanged;
  const _AppearanceBar({required this.appearance, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final control = SegmentedButton<TartibAppearance>(
      style: ButtonStyle(
        elevation: WidgetStateProperty.all(appearance == TartibAppearance.clay ? 0 : null),
        side: WidgetStateProperty.all(
          appearance == TartibAppearance.clay ? const BorderSide(color: Color(0xFFC2C9D3)) : null,
        ),
      ),
      segments: const [
        ButtonSegment(value: TartibAppearance.day, icon: Icon(Icons.light_mode), label: Text('Kunduz')),
        ButtonSegment(value: TartibAppearance.night, icon: Icon(Icons.dark_mode), label: Text('Tun')),
        ButtonSegment(value: TartibAppearance.clay, icon: Icon(Icons.blur_on), label: Text('Clay')),
      ],
      selected: {appearance},
      onSelectionChanged: (s) => onChanged(s.first),
    );
    if (appearance != TartibAppearance.clay) return control;
    return _ClayContainer(enabled: true, radius: 18, child: Padding(padding: const EdgeInsets.all(5), child: control));
  }
}

class _AppearanceSheet extends StatelessWidget {
  final TartibAppearance appearance;
  final ValueChanged<TartibAppearance> onChanged;
  const _AppearanceSheet({required this.appearance, required this.onChanged});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Ilova ko‘rinishi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              _AppearanceOption(icon: Icons.light_mode, title: 'Kunduzgi', selected: appearance == TartibAppearance.day, onTap: () => onChanged(TartibAppearance.day)),
              _AppearanceOption(icon: Icons.dark_mode, title: 'Tungi', selected: appearance == TartibAppearance.night, onTap: () => onChanged(TartibAppearance.night)),
              _AppearanceOption(icon: Icons.blur_on, title: 'Claymorphism', selected: appearance == TartibAppearance.clay, onTap: () => onChanged(TartibAppearance.clay)),
            ],
          ),
        ),
      );
}

class _AppearanceOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;
  const _AppearanceOption({required this.icon, required this.title, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        trailing: selected ? const Icon(Icons.check_circle) : null,
        onTap: onTap,
      );
}

class _ClayContainer extends StatelessWidget {
  final bool enabled;
  final Widget child;
  final double radius;
  const _ClayContainer({required this.enabled, required this.child, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDDE2EA),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFE8ECF2)),
        boxShadow: const [
          BoxShadow(color: Color(0xFFB4BBC7), offset: Offset(10, 10), blurRadius: 22, spreadRadius: 1),
          BoxShadow(color: Color(0xFFF8FAFD), offset: Offset(-10, -10), blurRadius: 22, spreadRadius: 1),
        ],
      ),
      child: child,
    );
  }
}

class _ClayButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _ClayButton({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFFDDE2EA),
          boxShadow: const [
            BoxShadow(color: Color(0xFFB4BBC7), offset: Offset(5, 5), blurRadius: 10),
            BoxShadow(color: Color(0xFFF8FAFD), offset: Offset(-5, -5), blurRadius: 10),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onPressed,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon),
                  const SizedBox(width: 10),
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      );
}

class ResultCard extends StatelessWidget {
  final FiqhResult result;
  const ResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Natija', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          Text(result.status.label, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text('Sajdai sahv: ${result.sajdaiSahv ? 'Ha' : 'Yo‘q'}'),
          Text('Qayta o‘qish: ${result.repeatPrayer ? 'Ha' : 'Yo‘q'}'),
          const Divider(height: 24),
          Text(result.explanation),
          if (result.ruleId != null) ...[
            const SizedBox(height: 12),
            Text('Qoida: ${result.ruleId}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
          if (result.sourceName != null) Text('Manba: ${result.sourceName}'),
        ],
      ),
    );
  }
}
