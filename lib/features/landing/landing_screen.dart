import 'package:flutter/material.dart';
import '../../core/responsive/breakpoints.dart';
import '../../core/theme/app_theme.dart';
import '../login/login_screen.dart';
import 'widgets/hero_section.dart';
import 'widgets/promo_visual.dart';
import '../../core/theme/design_tokens.dart';

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
    final colors = context.appColors;
    final primary = Theme.of(context).colorScheme.primary;
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
              colors: [
                Color.lerp(colors.background, primary, 0.06)!,
                colors.background
              ],
              stops: const [0.0, 0.8],
            ),
          ),
          child: child,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: context.isMobile ? Spacing.lg : Spacing.xxl,
              vertical: Spacing.xl,
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
        const SizedBox(height: Spacing.lg),
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
              const SizedBox(width: Spacing.xxl),
              Expanded(
                child: FadeTransition(
                  opacity: previewReveal,
                  child: const PromoVisual(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.xxl),
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
        const SizedBox(height: Spacing.xl),
        FadeTransition(opacity: previewReveal, child: const PromoVisual()),
        const SizedBox(height: Spacing.xxl),
        _FeatureGrid(columns: 2, revealBuilder: featureRevealBuilder),
      ],
    );
  }
}

const _features = [
  (
    icon: Icons.monitor_heart_outlined,
    title: '실시간 상태',
    accent: AppTheme.primary
  ),
  (icon: Icons.schedule_outlined, title: '데이터 지연', accent: AppTheme.warning),
  (icon: Icons.warning_amber_rounded, title: '이상 이력', accent: AppTheme.danger),
  (icon: Icons.route_outlined, title: '주행 기록', accent: AppTheme.success),
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
    final colors = context.appColors;
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
        padding: const EdgeInsets.symmetric(
            vertical: Spacing.lg, horizontal: Spacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: colors.border),
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
    final colors = context.appColors;
    return SizedBox(
      width: 128,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: FontSizes.caption,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
