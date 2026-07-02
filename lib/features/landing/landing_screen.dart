import 'package:flutter/material.dart';
import '../../core/responsive/breakpoints.dart';
import '../../core/theme/app_theme.dart';
import '../login/login_screen.dart';
import 'widgets/feature_card.dart';
import 'widgets/hero_section.dart';
import 'widgets/live_preview_card.dart';

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
              colors: const [Color(0xFF17264A), AppTheme.bg],
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
                  child: const LivePreviewCard(),
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
        FadeTransition(opacity: previewReveal, child: const LivePreviewCard()),
        const SizedBox(height: 40),
        _FeatureGrid(columns: 2, revealBuilder: featureRevealBuilder),
      ],
    );
  }
}

// 좁은 화면에서도 2줄 안에 들어가도록 설명을 짧게 유지한다 — 줄바꿈은
// 강제로 넣지 않고 Text가 알아서 감싸게 둔다(수동 \n과 자동 wrap이 겹치면
// 의도치 않게 줄 수가 늘어나 오버플로우가 난다).
const _features = [
  (
    icon: Icons.monitor_heart_outlined,
    title: '실시간 모니터링',
    desc: '속도·RPM·온도 등 센서 데이터 실시간 수집',
    accent: AppTheme.primary,
  ),
  (
    icon: Icons.warning_amber_rounded,
    title: '이상 감지',
    desc: '룰 + ML로 이상 징후 즉시 포착',
    accent: AppTheme.warning,
  ),
  (
    icon: Icons.psychology_outlined,
    title: 'AI 진단',
    desc: 'Gemini가 원인과 조치를 제안',
    accent: AppTheme.success,
  ),
  (
    icon: Icons.shield_outlined,
    title: '보안',
    desc: 'JWT·mTLS로 통신 구간을 보호',
    accent: AppTheme.danger,
  ),
];

class _FeatureGrid extends StatelessWidget {
  final int columns;
  final _IntervalBuilder revealBuilder;

  const _FeatureGrid({required this.columns, required this.revealBuilder});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // 카드 안 설명 텍스트 길이가 제각각이라 childAspectRatio로는 좁은 화면에서
      // 오버플로우가 났다 — 고정 높이(mainAxisExtent)를 줘서 폭이 좁아져도 안전하게.
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: columns == 4 ? 190 : 200,
      ),
      itemCount: _features.length,
      itemBuilder: (context, i) {
        final f = _features[i];
        // 카드가 순서대로 살짝 늦게 나타나도록 구간을 겹쳐서 stagger 효과를 준다.
        final start = 0.25 + i * 0.08;
        final reveal = revealBuilder(start.clamp(0.0, 0.9), (start + 0.5).clamp(0.0, 1.0));
        return AnimatedBuilder(
          animation: reveal,
          builder: (context, child) => Opacity(
            opacity: reveal.value,
            child: Transform.translate(
              offset: Offset(0, 16 * (1 - reveal.value)),
              child: child,
            ),
          ),
          child: FeatureCard(
            icon: f.icon,
            title: f.title,
            description: f.desc,
            accent: f.accent,
          ),
        );
      },
    );
  }
}
