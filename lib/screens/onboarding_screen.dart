import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/onboarding_content.dart';
import '../models/onboarding_page_content.dart';
import '../services/onboarding_service.dart';
import '../services/reading_time_calculator.dart';
import '../widgets/limited_fling_scroll_physics.dart';
import 'home_screen.dart';

/// v1.13: majburiy (yoki qayta ko'rib chiqish uchun) onboarding oqimi.
///
/// - `isReviewMode == false` (birinchi ishga tushirish): har bir
///   sahifa uchun minimal o'qish vaqti + pastgacha yetib borish talab
///   qilinadi, "Skip"/"Later" tugmasi yo'q, yakunida checkbox +
///   tasdiqlash orqaligina HomeScreen'ga o'tiladi va bu holat
///   doimiy saqlanadi.
/// - `isReviewMode == true` (Settings/"Muhim ma'lumotlar" orqali
///   qayta ochilganda): xuddi shu matn ko'rsatiladi, lekin hech
///   qanday cheklov yo'q — foydalanuvchi istagan payt orqaga qaytishi
///   (pop) mumkin, holat qayta yozilmaydi.
class OnboardingScreen extends StatefulWidget {
  final bool isReviewMode;

  const OnboardingScreen({super.key, this.isReviewMode = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _onboardingService = OnboardingService();

  /// 0..3 — kontent sahifalari, 4 (== onboardingPages.length) —
  /// yakuniy tasdiqlash sahifasi.
  int _currentIndex = 0;

  bool _checkboxChecked = false;

  // Joriy kontent sahifasi uchun gating holati.
  bool _minTimeElapsed = false;
  bool _reachedBottom = false;
  Timer? _readingTimer;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _startGatingForCurrentPage();
  }

  @override
  void dispose() {
    _readingTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startGatingForCurrentPage() {
    _readingTimer?.cancel();

    if (widget.isReviewMode || _currentIndex >= onboardingPages.length) {
      // Ko'rib chiqish rejimida yoki tasdiqlash sahifasida cheklov yo'q.
      _minTimeElapsed = true;
      _reachedBottom = true;
      return;
    }

    _minTimeElapsed = false;
    _reachedBottom = false;

    final page = onboardingPages[_currentIndex];
    final minDuration = ReadingTimeCalculator.forText(page.body);
    _readingTimer = Timer(minDuration, () {
      if (!mounted) return;
      setState(() => _minTimeElapsed = true);
    });

    // Agar kontent ekranga to'liq sig'sa (scroll qilish shart bo'lmasa),
    // "pastga yetib borish" shartini avtomatik bajarilgan deb hisoblaymiz.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent <= 0) {
        setState(() => _reachedBottom = true);
      }
    });
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 24 && !_reachedBottom) {
      setState(() => _reachedBottom = true);
    }
  }

  bool get _canContinue =>
      widget.isReviewMode || (_minTimeElapsed && _reachedBottom);

  void _goToNextPage() {
    if (_currentIndex >= onboardingPages.length) return;
    setState(() => _currentIndex++);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    _startGatingForCurrentPage();
  }

  void _goToPreviousPage() {
    if (_currentIndex <= 0) return;
    setState(() => _currentIndex--);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    _startGatingForCurrentPage();
  }

  Future<void> _finish() async {
    if (!widget.isReviewMode) {
      await _onboardingService.markCompleted();
    }
    if (!mounted) return;
    if (widget.isReviewMode) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConfirmationPage = _currentIndex >= onboardingPages.length;

    return PopScope(
      // Majburiy rejimda tizim "orqaga" tugmasi bilan onboarding'dan
      // chetlab o'tib bo'lmaydi (Skip yo'qligi talabiga mos).
      canPop: widget.isReviewMode,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            isConfirmationPage
                ? 'Davom etishga tayyormisiz?'
                : 'Muhim ma\'lumotlar',
          ),
          leading: (_currentIndex > 0)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _goToPreviousPage,
                )
              : (widget.isReviewMode
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  : null),
        ),
        body: SafeArea(
          child: isConfirmationPage
              ? _buildConfirmationPage()
              : _buildContentPage(onboardingPages[_currentIndex]),
        ),
      ),
    );
  }

  Widget _buildContentPage(OnboardingPageContent page) {
    return Column(
      children: [
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const LimitedFlingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    page.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    page.body,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.55,
                      color: Colors.black87,
                    ),
                  ),
                  if (page.sourceUrl != null) ...[
                    const SizedBox(height: 20),
                    _SourceLink(
                      label: page.sourceLabel ?? '',
                      url: page.sourceUrl!,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        _buildBottomBar(
          pageIndicator: '${page.pageNumber} / ${page.totalPages}',
        ),
      ],
    );
  }

  Widget _buildConfirmationPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          const Icon(
            Icons.check_circle_outline,
            size: 56,
            color: AppTheme.primary,
          ),
          const SizedBox(height: 20),
          const Text(
            'Davom etishga tayyormisiz?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 28),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _checkboxChecked = !_checkboxChecked),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _checkboxChecked,
                    onChanged: (v) =>
                        setState(() => _checkboxChecked = v ?? false),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'Men yuqoridagi ma\'lumotlarni to\'liq o\'qib '
                        'chiqdim va tushundim.',
                        style: TextStyle(fontSize: 15, height: 1.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _checkboxChecked ? _finish : null,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text('Azon Trainer\'dan boshlash'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBottomBar({required String pageIndicator}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(
          top: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            pageIndicator,
            style: const TextStyle(color: Colors.black45, fontSize: 13),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canContinue ? _goToNextPage : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  _canContinue
                      ? 'Davom etish'
                      : (!_minTimeElapsed
                          ? 'O\'qib chiqing...'
                          : 'Pastgacha o\'qing...'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// v1.13: manba havolasi — `url_launcher` kabi qo'shimcha dependency
/// qo'shmaslik uchun (loyihada oldin `record` paketi bilan Gradle
/// mos kelmasligi ko'p vaqt olgan edi), havola shunchaki TANLAB
/// NUSXALASH mumkin bo'lgan matn sifatida ko'rsatiladi — "havola"
/// ko'rinishida (rang, chiziq), lekin bosilmaydi.
class _SourceLink extends StatelessWidget {
  final String label;
  final String url;

  const _SourceLink({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: Colors.black54),
            ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.link, size: 16, color: AppTheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: SelectableText(
                  url,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
