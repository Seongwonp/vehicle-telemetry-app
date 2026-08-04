import 'package:flutter/material.dart';
import '../../core/responsive/breakpoints.dart';
import '../../core/theme/app_theme.dart';
import '../login/login_screen.dart';
import 'widgets/hero_section.dart';
import 'widgets/promo_visual.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _reveal;
  late final AnimationController _bgDrift;

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    // 배경 글로우를 아주 느리게 흔들어 정지된 화면이라는 느낌을 없앤다.
    _bgDrift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _reveal.dispose();
    _bgDrift.dispose();
    super.dispose();
  }

  Animation<double> _interval(double start, double end) {
    return CurvedAnimation(
      parent: _reveal,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
  }

  void _goToLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final heroReveal = _interval(0.0, 0.6);
    final previewReveal = _interval(0.15, 0.75);

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgDrift,
        builder: (context, child) => DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.lerp(
                const Alignment(-0.3, -0.8),
                const Alignment(0.3, -0.6),
                _bgDrift.value,
              )!,
              radius: 1.3,
              // 반투명 색 → 불투명 색으로 보간하면 중간 지점의 알파값이 커지면서
              // 오히려 더 진한 파란 띠가 생긴다. 처음부터 불투명한 두 색 사이를
              // 보간해야 은은한 톤 변화로 보인다.
              colors: [
                Color.lerp(AppTheme.bg, AppTheme.primary, 0.06)!,
                AppTheme.bg
              ],
              stops: const [0.0, 0.8],
            ),
          ),
          child: child,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: context.isMobile ? 24 : 48,
              vertical: 32,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: context.isDesktop
                    ? _DesktopLayout(
                        heroReveal: heroReveal,
                        previewReveal: previewReveal,
                        onGetStarted: _goToLogin,
                        featureRevealBuilder: _interval,
                      )
                    : _MobileLayout(
                        heroReveal: heroReveal,
                        previewReveal: previewReveal,
                        onGetStarted: _goToLogin,
                        featureRevealBuilder: _interval,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

typedef _IntervalBuilder = Animation<double> Function(double start, double end);

class _DesktopLayout extends StatelessWidget {
  final Animation<double> heroReveal;
  final Animation<double> previewReveal;
  final VoidCallback onGetStarted;
  final _IntervalBuilder featureRevealBuilder;

  const _DesktopLayout({
    required this.heroReveal,
    required this.previewReveal,
    required this.onGetStarted,
    required this.featureRevealBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: HeroSection(
                  reveal: heroReveal,
                  onGetStarted: onGetStarted,
                  alignLeft: true,
                ),
              ),
              const SizedBox(width: 56),
              Expanded(
                child: FadeTransition(
                  opacity: previewReveal,
                  child: const PromoVisual(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 64),
        _FeatureGrid(columns: 4, revealBuilder: featureRevealBuilder),
      ],
    );
  }
}

class _MobileLayout extends StatelessWidget {
  final Animation<double> heroReveal;
  final Animation<double> previewReveal;
  final VoidCallback onGetStarted;
  final _IntervalBuilder featureRevealBuilder;

  const _MobileLayout({
    required this.heroReveal,
    required this.previewReveal,
    required this.onGetStarted,
    required this.featureRevealBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HeroSection(reveal: heroReveal, onGetStarted: onGetStarted),
        const SizedBox(height: 36),
        FadeTransition(opacity: previewReveal, child: const PromoVisual()),
        const SizedBox(height: 40),
        _FeatureGrid(columns: 2, revealBuilder: featureRevealBuilder),
      ],
    );
  }
}

const _features = [
  (
    icon: Icons.monitor_heart_outlined,
    title: '실시간 모니터링',
    accent: AppTheme.primary
  ),
  (icon: Icons.warning_amber_rounded, title: '이상 감지', accent: AppTheme.warning),
  (icon: Icons.psychology_outlined, title: 'AI 진단', accent: AppTheme.success),
  (icon: Icons.shield_outlined, title: '보안', accent: AppTheme.danger),
];

// 아이콘+설명이 딸린 큰 카드 4개 대신, 계기판 하단 인디케이터처럼 얇고
// 압축된 띠 하나로 능력치를 나열한다 — "기능 소개 카드 그리드"라는 흔한
// 랜딩페이지 패턴에서 벗어나기 위한 의도적인 선택.
class _FeatureGrid extends StatelessWidget {
  final int columns;
  final _IntervalBuilder revealBuilder;

  const _FeatureGrid({required this.columns, required this.revealBuilder});

  @override
  Widget build(BuildContext context) {
    final reveal = revealBuilder(0.3, 0.8);
    return AnimatedBuilder(
      animation: reveal,
      builder: (context, child) => Opacity(
        opacity: reveal.value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - reveal.value)),
          child: child,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceEvenly,
          runSpacing: 20,
          children: _features
              .map((f) => _CapabilityItem(
                    icon: f.icon,
                    title: f.title,
                    accent: f.accent,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _CapabilityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accent;

  const _CapabilityItem({
    required this.icon,
    required this.title,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
